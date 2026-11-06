import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/islamic_pattern.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// شاشة المشغّل الكامل
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePlaying());
  }

  Future<void> _ensurePlaying() async {
    final item = ref.read(lessonByIdProvider(widget.lessonId));
    if (item == null) return;
    final player = ref.read(playerProvider);
    if (player.currentLesson?.id != widget.lessonId) {
      await ref.read(playerProvider.notifier).play(item.lesson);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final item = ref.watch(lessonByIdProvider(widget.lessonId));
    // بعد «التالي/السابق» يتغيّر الدرس في المشغّل دون تغيير المسار
    final lesson = player.currentLesson ?? item?.lesson;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المشغّل')),
        body: const Center(child: Text('الدرس غير موجود')),
      );
    }

    final duration = player.duration.inSeconds > 0
        ? player.duration
        : Duration(seconds: lesson.duration);
    final maxMs = duration.inMilliseconds.toDouble();
    final notifier = ref.read(playerProvider.notifier);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            // التمرير متاح دائماً للشاشات الصغيرة، والمحتوى يملأ الطول في الكبيرة
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      _TopBar(lessonId: lesson.id),
                      const SizedBox(height: AppSpacing.md),
                      _Cover(number: lesson.id),
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Text(
                          lesson.title,
                          textAlign: TextAlign.center,
                          style: text.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'الشيخ ${AppConstants.sheikhName}',
                        style:
                            text.bodySmall?.copyWith(color: colors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SpeedChip(speed: player.speed),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Slider(
                          value: player.position.inMilliseconds
                              .toDouble()
                              .clamp(0.0, maxMs),
                          max: maxMs > 0 ? maxMs : 1,
                          onChanged: (v) =>
                              notifier.seek(Duration(milliseconds: v.toInt())),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppConstants.formatDuration(player.position),
                              style: text.labelSmall
                                  ?.copyWith(color: colors.textMuted),
                            ),
                            Text(
                              AppConstants.formatDuration(duration),
                              style: text.labelSmall
                                  ?.copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _Controls(
                        playing: player.status == PlayerStatus.playing,
                        loading: player.status == PlayerStatus.loading,
                      ),
                      if (player.status == PlayerStatus.error &&
                          player.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.md,
                            AppSpacing.xl,
                            0,
                          ),
                          child: Text(
                            player.errorMessage!,
                            textAlign: TextAlign.center,
                            style:
                                text.bodySmall?.copyWith(color: colors.danger),
                          ),
                        ),
                      const Spacer(),
                      _NextUp(currentId: lesson.id),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.lessonId});

  final int lessonId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
            color: colors.textMuted,
            tooltip: 'رجوع',
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          Expanded(
            child: Text(
              'الدرس $lessonId من ${AppConstants.totalLessons}',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colors.textMuted),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_rounded),
            color: colors.textMuted,
            tooltip: 'قائمة الدروس',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
    );
  }
}

/// غلاف الدرس: سطح أخضر عميق بزخرفة ذهبية، ورقم الدرس في دائرة بالوسط
class _Cover extends StatelessWidget {
  const _Cover({required this.number});

  final int number;

  static String _arabicDigits(int n) =>
      n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 220,
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.header,
        borderRadius: BorderRadius.circular(AppRadius.xxl + 4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IslamicPattern(
              color: colors.gold.withValues(alpha: 0.24),
              cellSize: 55,
            ),
          ),
          Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.header,
              shape: BoxShape.circle,
              border: Border.all(color: colors.gold, width: 1.5),
            ),
            child: Text(
              _arabicDigits(number),
              style: TextStyle(
                color: colors.gold,
                fontSize: number > 9 ? 30 : 34,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر السرعة — يفتح قائمة السرعات المتاحة
class _SpeedChip extends ConsumerWidget {
  const _SpeedChip({required this.speed});

  final double speed;

  static String label(double s) {
    final str = s.toStringAsFixed(2);
    return '${str.replaceFirst(RegExp(r'\.?0+$'), '')}×';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return PopupMenuButton<double>(
      initialValue: speed,
      tooltip: 'سرعة التشغيل',
      position: PopupMenuPosition.under,
      onSelected: (s) => ref.read(playerProvider.notifier).setSpeed(s),
      itemBuilder: (_) => [
        for (final s in AppConstants.playbackSpeeds)
          PopupMenuItem(value: s, child: Text(label(s))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs - 1,
        ),
        decoration: BoxDecoration(
          color: colors.accentContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded,
                size: 16, color: colors.onAccentContainer),
            const SizedBox(width: AppSpacing.xxs + 2),
            Text(
              'السرعة ${label(speed)}',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colors.onAccentContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends ConsumerWidget {
  const _Controls({required this.playing, required this.loading});

  final bool playing;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final notifier = ref.read(playerProvider.notifier);

    Widget side(IconData icon, String tip, VoidCallback onTap) => IconButton(
          icon: Icon(icon),
          iconSize: 28,
          color: colors.textSecondary,
          tooltip: tip,
          onPressed: onTap,
        );

    // FittedBox يُقلّص الصف على الشاشات الضيقة دون تغيير المسافات
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          side(Icons.replay_30_rounded, 'رجوع 30 ثانية',
              notifier.skipBackward30),
          const SizedBox(width: AppSpacing.xs),
          side(Icons.skip_previous_rounded, 'الدرس السابق',
              notifier.playPrevious),
          const SizedBox(width: AppSpacing.md),
          Material(
            color: colors.brand,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: notifier.togglePlayPause,
              child: SizedBox.square(
                dimension: 68,
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(22),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 36,
                        color: Colors.white,
                        semanticLabel: playing ? 'إيقاف مؤقت' : 'تشغيل',
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          side(Icons.skip_next_rounded, 'الدرس التالي', notifier.playNext),
          const SizedBox(width: AppSpacing.xs),
          side(Icons.forward_30_rounded, 'تقديم 30 ثانية',
              notifier.skipForward30),
        ],
      ),
    );
  }
}

/// سطر «التالي» أسفل الشاشة
class _NextUp extends ConsumerWidget {
  const _NextUp({required this.currentId});

  final int currentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final lessons = ref.watch(lessonsProvider).valueOrNull;
    LessonModel? next;
    if (lessons != null) {
      final i = lessons.indexWhere((l) => l.lesson.id == currentId);
      if (i >= 0 && i < lessons.length - 1) next = lessons[i + 1].lesson;
    }
    if (next == null) return const SizedBox(height: AppSpacing.md);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          const Divider(),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: ref.read(playerProvider.notifier).playNext,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'التالي: ',
                    style: text.labelMedium?.copyWith(color: colors.textMuted),
                  ),
                  Expanded(
                    child: Text(
                      next.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ),
                  Icon(
                    Icons.skip_next_rounded,
                    size: 20,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
