import 'dart:async';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/local/voice_note_storage.dart';
import 'package:al_daa_wal_dawaa/domain/providers/annotations_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/voice_note_player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// يفتح ورقة تسجيل ملاحظة صوتية مرتبطة بموضع في الدرس
Future<void> showVoiceRecorder(
  BuildContext context,
  WidgetRef ref, {
  required int lessonId,
  required Duration position,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  // نوقف الدرس أثناء التسجيل حتى لا يلتقط الميكروفون صوت السماعة
  final wasPlaying = ref.read(playerProvider).status == PlayerStatus.playing;
  if (wasPlaying) await ref.read(playerProvider.notifier).pause();
  if (!context.mounted) return;

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: true,
    builder: (_) => _RecorderSheet(lessonId: lessonId, position: position),
  );

  if (saved == true) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'حُفظت الملاحظة الصوتية عند ${AppConstants.formatDuration(position)}',
          ),
        ),
      );
  }
  if (wasPlaying) await ref.read(playerProvider.notifier).resume();
}

enum _Stage { ready, recording, recorded, denied }

class _RecorderSheet extends ConsumerStatefulWidget {
  const _RecorderSheet({required this.lessonId, required this.position});

  final int lessonId;
  final Duration position;

  @override
  ConsumerState<_RecorderSheet> createState() => _RecorderSheetState();
}

class _RecorderSheetState extends ConsumerState<_RecorderSheet> {
  static const _maxLength = Duration(minutes: 5);
  static const _bars = 32;

  final _recorder = AudioRecorder();
  _Stage _stage = _Stage.ready;
  String? _path;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;
  // قابلة للتمدد: كل قراءة تُزيل الأقدم وتضيف الأحدث (List.filled وحدها
  // ثابتة الطول فيفشل removeAt ويتجمد المؤشر)
  final List<double> _levels = List.filled(_bars, 0, growable: true);
  bool _saved = false;

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      setState(() => _stage = _Stage.denied);
      return;
    }
    final path = await VoiceNoteStorage.newPath(widget.lessonId);
    await _recorder.start(
      // جودة الكلام تكفيها 32 كيلوبت (ربع الافتراضي)، فتبقى الملاحظات صغيرة
      // ضمن حد النسخ الاحتياطي التلقائي (25 ميغا للتطبيق كله)
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
        bitRate: 32000,
        sampleRate: 22050,
      ),
      path: path,
    );
    _path = path;
    _elapsed = Duration.zero;
    _levels.fillRange(0, _bars, 0);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= _maxLength) _stop();
    });
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 120))
        .listen((a) {
      // dBFS من -60 (صمت) إلى 0 (أعلى مستوى) → 0..1
      final level = ((a.current + 60) / 60).clamp(0.0, 1.0);
      setState(() {
        _levels
          ..removeAt(0)
          ..add(level);
      });
    });
    setState(() => _stage = _Stage.recording);
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _path = path ?? _path;
      _stage = _Stage.recorded;
    });
  }

  Future<void> _discard() async {
    await ref.read(voiceNotePlayerProvider.notifier).stop();
    await VoiceNoteStorage.delete(_path);
    _path = null;
  }

  Future<void> _retake() async {
    await _discard();
    setState(() => _stage = _Stage.ready);
  }

  Future<void> _save() async {
    final path = _path;
    if (path == null) return;
    await ref.read(voiceNotePlayerProvider.notifier).stop();
    await ref
        .read(annotationsProvider.notifier)
        .addVoiceNote(widget.lessonId, widget.position, path);
    _saved = true;
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _cancel() async {
    if (_stage == _Stage.recording) {
      _ticker?.cancel();
      await _ampSub?.cancel();
      await _recorder.stop();
    }
    await _discard();
    if (mounted) Navigator.pop(context, false);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ampSub?.cancel();
    _recorder.dispose();
    // إغلاق غير متوقع (زر الرجوع) قبل الحفظ: لا نترك ملفاً يتيماً
    if (!_saved && _path != null) VoiceNoteStorage.delete(_path);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final at = AppConstants.formatDuration(widget.position);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ملاحظة صوتية عند $at', style: text.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            switch (_stage) {
              _Stage.ready => _ReadyView(onStart: _start),
              _Stage.denied => _DeniedView(onRetry: _start),
              _Stage.recording => _RecordingView(
                  elapsed: _elapsed,
                  levels: _levels,
                  onStop: _stop,
                ),
              _Stage.recorded => _RecordedView(
                  path: _path!,
                  elapsed: _elapsed,
                  onRetake: _retake,
                  onSave: _save,
                ),
            },
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _cancel,
              style: TextButton.styleFrom(foregroundColor: colors.textMuted),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? context.colors.brand,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 76,
          child:
              Icon(icon, size: 34, color: Colors.white, semanticLabel: label),
        ),
      ),
    );
  }
}

class _ReadyView extends StatelessWidget {
  const _ReadyView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MicButton(
          icon: Icons.mic_rounded,
          label: 'ابدأ التسجيل',
          onTap: onStart,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'اضغط لبدء التسجيل. يُستخدم الميكروفون لتسجيل ملاحظتك فقط، وتُحفظ على هاتفك.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: context.colors.textMuted),
        ),
      ],
    );
  }
}

class _DeniedView extends StatelessWidget {
  const _DeniedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.mic_off_rounded, size: 40, color: context.colors.danger),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'لا يمكن التسجيل بدون إذن الميكروفون. اسمح به من إعدادات الهاتف ثم حاول مرة أخرى.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton(onPressed: onRetry, child: const Text('حاول مرة أخرى')),
      ],
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView({
    required this.elapsed,
    required this.levels,
    required this.onStop,
  });

  final Duration elapsed;
  final List<double> levels;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final l in levels)
                Container(
                  width: 4,
                  height: 4 + l * 40,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: 0.4 + l * 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppConstants.formatDuration(elapsed),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: colors.danger),
        ),
        const SizedBox(height: AppSpacing.md),
        _MicButton(
          icon: Icons.stop_rounded,
          label: 'إيقاف التسجيل',
          color: colors.danger,
          onTap: onStop,
        ),
      ],
    );
  }
}

class _RecordedView extends ConsumerWidget {
  const _RecordedView({
    required this.path,
    required this.elapsed,
    required this.onRetake,
    required this.onSave,
  });

  final String path;
  final Duration elapsed;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(voiceNotePlayerProvider);
    final active = playback.isActive(path);
    final playing = active && playback.playing;
    final total = active && playback.duration > Duration.zero
        ? playback.duration
        : elapsed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: context.colors.accentContainer,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: context.colors.onAccentContainer,
                ),
                tooltip: playing ? 'إيقاف مؤقت' : 'استمع للتسجيل',
                onPressed: () =>
                    ref.read(voiceNotePlayerProvider.notifier).toggle(path),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: total.inMilliseconds > 0 && active
                        ? playback.position.inMilliseconds /
                            total.inMilliseconds
                        : 0,
                    minHeight: 3,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  AppConstants.formatDuration(total),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetake,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('إعادة التسجيل'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
