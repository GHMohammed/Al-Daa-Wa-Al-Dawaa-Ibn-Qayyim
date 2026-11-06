import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/annotations_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/annotation_widgets.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/islamic_pattern.dart';
import 'package:flutter/foundation.dart' show listEquals;
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
                      _ToolsRow(
                        lessonId: lesson.id,
                        speed: player.speed,
                        position: player.position,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SeekBar(
                        lessonId: lesson.id,
                        positionMs: player.position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, maxMs),
                        maxMs: maxMs > 0 ? maxMs : 1,
                        onSeek: (v) =>
                            notifier.seek(Duration(milliseconds: v.toInt())),
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
                      _AnnotationsSummary(lessonId: lesson.id),
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

/// أدوات الدرس تحت العنوان: السرعة، إضافة علامة، كتابة ملاحظة
class _ToolsRow extends ConsumerWidget {
  const _ToolsRow({
    required this.lessonId,
    required this.speed,
    required this.position,
  });

  final int lessonId;
  final double speed;
  final Duration position;

  static String speedLabel(double s) {
    final str = s.toStringAsFixed(2);
    return '${str.replaceFirst(RegExp(r'\.?0+$'), '')}×';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        PopupMenuButton<double>(
          initialValue: speed,
          tooltip: 'سرعة التشغيل',
          position: PopupMenuPosition.under,
          onSelected: (s) => ref.read(playerProvider.notifier).setSpeed(s),
          itemBuilder: (_) => [
            for (final s in AppConstants.playbackSpeeds)
              PopupMenuItem(value: s, child: Text(speedLabel(s))),
          ],
          child: _ToolChip(
            icon: Icons.speed_rounded,
            label: 'السرعة ${speedLabel(speed)}',
          ),
        ),
        _ToolChip(
          icon: Icons.bookmark_add_outlined,
          label: 'علامة',
          onTap: () => addBookmarkWithFeedback(
            context,
            ref,
            lessonId: lessonId,
            position: position,
          ),
        ),
        _ToolChip(
          icon: Icons.edit_note_rounded,
          label: 'ملاحظة',
          onTap: () => showNoteEditor(
            context,
            ref,
            lessonId: lessonId,
            position: position,
          ),
        ),
      ],
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;

  /// null عندما يتولّى الضغطَ عنصرٌ أب (مثل قائمة السرعة)
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: colors.accentContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colors.onAccentContainer),
          const SizedBox(width: AppSpacing.xxs + 2),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: colors.onAccentContainer),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: chip,
      ),
    );
  }
}

/// شريط التقديم مع نقاط العلامات (ذهبية) والملاحظات (خضراء) فوق مواضعها
class _SeekBar extends ConsumerWidget {
  const _SeekBar({
    required this.lessonId,
    required this.positionMs,
    required this.maxMs,
    required this.onSeek,
  });

  final int lessonId;
  final double positionMs;
  final double maxMs;
  final ValueChanged<double> onSeek;

  /// المسافة الأفقية للمسار داخل الـ Slider — نفسها لحساب مواضع النقاط
  static const double _inset = AppSpacing.xl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final items = ref.watch(lessonAnnotationsProvider(lessonId));

    // الرسم بـ CustomPainter (لا LayoutBuilder) لأن الشاشة داخل IntrinsicHeight
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _TicksPainter(
              fractions: [
                for (final i in items)
                  (i.position * 1000 / maxMs).clamp(0.0, 1.0),
              ],
              colors: [
                for (final i in items) i.isNote ? colors.brand : colors.gold,
              ],
              inset: _inset,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
        Slider(
          padding: const EdgeInsets.symmetric(horizontal: _inset),
          value: positionMs,
          max: maxMs,
          onChanged: onSeek,
        ),
      ],
    );
  }
}

class _TicksPainter extends CustomPainter {
  _TicksPainter({
    required this.fractions,
    required this.colors,
    required this.inset,
    required this.rtl,
  });

  final List<double> fractions;
  final List<Color> colors;
  final double inset;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final track = size.width - inset * 2;
    final cy = size.height / 2;
    for (var i = 0; i < fractions.length; i++) {
      final offset = inset + fractions[i] * track;
      final x = rtl ? size.width - offset : offset;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, cy), width: 3, height: 14),
          const Radius.circular(2),
        ),
        Paint()..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(_TicksPainter old) =>
      old.rtl != rtl ||
      old.inset != inset ||
      !listEquals(old.fractions, fractions) ||
      !listEquals(old.colors, colors);
}

/// سطر يلخّص علامات وملاحظات الدرس ويفتح قائمتها
class _AnnotationsSummary extends ConsumerWidget {
  const _AnnotationsSummary({required this.lessonId});

  final int lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(lessonAnnotationsProvider(lessonId));
    if (items.isEmpty) return const SizedBox.shrink();

    final notes = items.where((i) => i.isNote).length;
    final marks = items.length - notes;
    // العدد في العربية: مفرد، مثنى، جمع (3–10)، ثم مفرد منصوب (11+)
    String count(int n, String one, String two, String few, String many) =>
        switch (n) {
          1 => one,
          2 => two,
          <= 10 => '$n $few',
          _ => '$n $many',
        };
    final parts = [
      if (marks > 0) count(marks, 'علامة واحدة', 'علامتان', 'علامات', 'علامة'),
      if (notes > 0)
        count(notes, 'ملاحظة واحدة', 'ملاحظتان', 'ملاحظات', 'ملاحظة'),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: TextButton.icon(
        onPressed: () => _showLessonAnnotations(context, lessonId),
        icon: const Icon(Icons.bookmarks_outlined, size: 18),
        label: Text('في هذا الدرس: ${parts.join(' و')}'),
      ),
    );
  }
}

void _showLessonAnnotations(BuildContext context, int lessonId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (ctx, scroll) => Consumer(
        builder: (ctx, ref, _) {
          final items = ref.watch(lessonAnnotationsProvider(lessonId));
          if (items.isEmpty) {
            return Center(
              child: Text(
                'لا توجد علامات أو ملاحظات في هذا الدرس',
                style: TextStyle(color: ctx.colors.textMuted),
              ),
            );
          }
          return ListView.builder(
            controller: scroll,
            itemCount: items.length,
            itemBuilder: (_, i) => AnnotationTile(
              item: items[i],
              onTap: () {
                ref
                    .read(playerProvider.notifier)
                    .seek(Duration(seconds: items[i].position));
                Navigator.pop(ctx);
              },
            ),
          );
        },
      ),
    ),
  );
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
