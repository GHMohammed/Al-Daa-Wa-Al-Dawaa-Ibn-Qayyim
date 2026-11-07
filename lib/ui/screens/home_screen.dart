import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/core/utils/arabic_text.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/home_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/islamic_pattern.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/lesson_card.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/page_header.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/status_bar_scrim.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// الشاشة الرئيسية — الإنجاز، «أكمل الاستماع»، وقائمة الدروس
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(filteredLessonsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: StatusBarScrim(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: _Header()),
                    const SliverToBoxAdapter(child: _ContinueCard()),
                    const SliverToBoxAdapter(child: _LessonsHeader()),
                    ...lessonsAsync.when(
                      loading: () => const [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xxl),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      ],
                      error: (e, _) => [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Text('تعذّر تحميل الدروس: $e'),
                          ),
                        ),
                      ],
                      data: (lessons) => [
                        if (lessons.isEmpty)
                          const SliverToBoxAdapter(child: _EmptyFilter())
                        else
                          SliverList.builder(
                            itemCount: lessons.length,
                            itemBuilder: (_, i) =>
                                LessonCard(lesson: lessons[i]),
                          ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: AppSpacing.md),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// رأس الصفحة: الاسم والإنجاز فوق زخرفة باهتة تتلاشى نحو الأسفل
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final completed = ref.watch(completedCountProvider);
    final overall = ref.watch(overallProgressProvider);

    return PageHeader(
      title: 'الداء والدواء',
      subtitle: 'شرح الشيخ ${AppConstants.sheikhName}',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'إنجازك في الكتاب',
                  style:
                      text.labelMedium?.copyWith(color: colors.textSecondary),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$completed',
                      style: TextStyle(
                        color: colors.brand,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    TextSpan(
                      text: ' من ${AppConstants.totalLessons} درساً',
                    ),
                  ],
                ),
                style: text.labelMedium?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: overall.clamp(0.0, 1.0),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة «أكمل الاستماع» — الدرس الحالي أو آخر درس لم يكتمل
class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(continueLessonProvider);
    if (item == null) return const SizedBox(height: AppSpacing.xs);

    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final player = ref.watch(playerProvider);
    final isCurrent = player.currentLesson?.id == item.lesson.id;
    final isPlaying = isCurrent && player.status == PlayerStatus.playing;

    // الموضع الحي من المشغّل إن كان هذا الدرس محمّلاً، وإلا المحفوظ
    final position = isCurrent
        ? player.position
        : Duration(seconds: item.progress?.position ?? 0);
    final total = isCurrent && player.duration > Duration.zero
        ? player.duration
        : Duration(
            seconds: item.progress?.totalDuration ?? item.lesson.duration,
          );
    final fraction = total.inMilliseconds > 0
        ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final remainingMin = ((total - position).inSeconds / 60).ceil();
    final fresh = position == Duration.zero;

    void openPlayer() {
      if (!isCurrent) ref.read(playerProvider.notifier).play(item.lesson);
      context.push('/player/${item.lesson.id}');
    }

    void togglePlay() {
      final notifier = ref.read(playerProvider.notifier);
      if (isCurrent) {
        notifier.togglePlayPause();
      } else {
        notifier.play(item.lesson);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Material(
        color: colors.header,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openPlayer,
          child: Stack(
            children: [
              Positioned.fill(
                child: IslamicPattern(
                  color: colors.gold.withValues(alpha: 0.2),
                  cellSize: 46,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fresh ? 'ابدأ الاستماع' : 'أكمل الاستماع'}، الدرس ${item.lesson.id}',
                      style: text.labelMedium
                          ?.copyWith(color: colors.onHeaderMuted),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      item.lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(color: colors.onHeader),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Material(
                          color: colors.gold,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: togglePlay,
                            child: SizedBox.square(
                              dimension: AppSizes.minTapTarget,
                              child: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: colors.onGold,
                                size: 26,
                                semanticLabel:
                                    isPlaying ? 'إيقاف مؤقت' : 'تشغيل',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  minHeight: 3,
                                  color: colors.gold,
                                  backgroundColor: colors.onHeaderTrack,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs - 2),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppConstants.formatDuration(position),
                                    style: text.labelSmall?.copyWith(
                                      color: colors.onHeaderMuted,
                                    ),
                                  ),
                                  Text(
                                    fresh
                                        ? '${(total.inSeconds / 60).round()} دقيقة'
                                        : 'بقي $remainingMin دقيقة',
                                    style: text.labelSmall?.copyWith(
                                      color: colors.onHeaderMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عنوان «الدروس» مع قائمة التصفية
class _LessonsHeader extends ConsumerWidget {
  const _LessonsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final filter = ref.watch(lessonFilterProvider);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          Expanded(child: Text('الدروس', style: text.titleMedium)),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: colors.textMuted,
            tooltip: 'ابحث في الدروس',
            onPressed: () {
              final lessons = ref.read(lessonsProvider).valueOrNull;
              if (lessons == null) return;
              showSearch<void>(
                context: context,
                delegate:
                    LessonSearchDelegate([for (final l in lessons) l.lesson]),
              );
            },
          ),
          PopupMenuButton<LessonFilter>(
            initialValue: filter,
            tooltip: 'تصفية الدروس',
            onSelected: (f) =>
                ref.read(lessonFilterProvider.notifier).state = f,
            itemBuilder: (_) => [
              for (final f in LessonFilter.values)
                PopupMenuItem(value: f, child: Text(f.label)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: text.labelMedium?.copyWith(
                      color: filter == LessonFilter.all
                          ? colors.textMuted
                          : colors.brand,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
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

class _EmptyFilter extends ConsumerWidget {
  const _EmptyFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(lessonFilterProvider);
    final message = switch (filter) {
      LessonFilter.inProgress => 'لا يوجد درس قيد الاستماع',
      LessonFilter.completed => 'لم تُكمل أي درس بعد',
      LessonFilter.downloaded => 'لم تحفظ أي درس للاستماع دون إنترنت',
      LessonFilter.all => 'لا توجد دروس',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.colors.textMuted),
          ),
          TextButton(
            onPressed: () => ref.read(lessonFilterProvider.notifier).state =
                LessonFilter.all,
            child: const Text('عرض كل الدروس'),
          ),
        ],
      ),
    );
  }
}

/// يطابق الدروس بالعنوان (بعد توحيد الهمزات والتشكيل) أو برقم الدرس
List<LessonModel> searchLessons(List<LessonModel> lessons, String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final number = int.tryParse(q);
  if (number != null) return lessons.where((l) => l.id == number).toList();
  final words = normalizeArabic(q).split(RegExp(r'\s+'));
  return lessons.where((l) {
    final title = normalizeArabic(l.title);
    return words.every(title.contains);
  }).toList();
}

class LessonSearchDelegate extends SearchDelegate<void> {
  LessonSearchDelegate(this.lessons)
      : super(
          searchFieldLabel: 'عنوان الدرس أو رقمه',
          keyboardType: TextInputType.text,
        );

  final List<LessonModel> lessons;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'مسح',
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_forward_rounded),
        tooltip: 'رجوع',
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final muted = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: context.colors.textMuted);
    if (query.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'اكتب كلمة من عنوان الدرس، مثل: الدعاء، الذنوب — أو رقمه',
          textAlign: TextAlign.center,
          style: muted,
        ),
      );
    }
    final hits = searchLessons(lessons, query);
    if (hits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'لا يوجد درس يطابق «$query»',
          textAlign: TextAlign.center,
          style: muted,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: hits.length,
      itemBuilder: (_, i) => LessonCard(lesson: hits[i]),
    );
  }
}
