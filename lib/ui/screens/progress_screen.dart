import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/models/book_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/book_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:al_daa_wal_dawaa/ui/screens/book_screen.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/lesson_card.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/page_header.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/progress_circle.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/status_bar_scrim.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// شاشة التقدم: كم بقي، إحصاءات موجزة، استماع الأسبوع، القراءة، آخر الدروس
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: StatusBarScrim(
          child: ListView(
            padding: EdgeInsets.zero,
            children: const [
              PageHeader(
                title: 'تقدمك',
                subtitle: 'ما أنجزته من شرح الكتاب',
              ),
              SizedBox(height: AppSpacing.md),
              _Summary(),
              SizedBox(height: AppSpacing.md),
              _StatsRow(),
              SizedBox(height: AppSpacing.sm),
              _WeekCard(),
              SizedBox(height: AppSpacing.sm),
              _ReadingCard(),
              _RecentLessons(),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// الحلقة + كم بقي لإتمام الشرح وبأي معدّل
class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overall = ref.watch(overallProgressProvider);
    final remaining = ref.watch(remainingSecondsProvider);
    final weekSeconds = ref
        .watch(weekListeningProvider)
        .fold<int>(0, (sum, d) => sum + d.seconds);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    final remainingHours = (remaining / 3600).round();
    final String headline;
    final String? pace;
    if (remaining == 0) {
      headline = 'أتممت الشرح كاملاً، بارك الله فيك';
      pace = null;
    } else {
      headline = 'بقي نحو $remainingHours ساعة لإتمام الشرح';
      pace = weekSeconds < 60
          ? 'استمع هذا الأسبوع ونقدّر لك موعد الإتمام'
          : 'بمعدّل أسبوعك الحالي: نحو ${_paceLabel(remaining, weekSeconds)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          ProgressCircle(
            progress: overall,
            size: 110,
            strokeWidth: 8,
            label: 'من الشرح',
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (remaining == 0)
                  Text(headline, style: text.titleMedium)
                else
                  Text.rich(
                    TextSpan(
                      style: text.titleMedium,
                      children: [
                        const TextSpan(text: 'بقي نحو '),
                        TextSpan(
                          text: '$remainingHours ساعة',
                          style: TextStyle(color: colors.gold),
                        ),
                        const TextSpan(text: ' لإتمام الشرح'),
                      ],
                    ),
                  ),
                if (pace != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    pace,
                    style: text.labelMedium?.copyWith(color: colors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// المدة المتوقعة إن استمر المستمع على معدّل آخر 7 أيام
  static String _paceLabel(int remaining, int weekSeconds) {
    final days = (remaining / (weekSeconds / 7)).ceil();
    if (days <= 1) return 'يوم واحد';
    if (days < 14) return '$days أيام';
    final weeks = (days / 7).round();
    if (weeks < 9) return '$weeks أسابيع';
    return '${(days / 30).round()} أشهر';
  }
}

/// ثلاث أرقام موجزة في بطاقة واحدة بفواصل
class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(completedCountProvider);
    final hours = ref.watch(totalHoursProvider);
    final streak = ref.watch(listeningStreakProvider);
    final colors = context.colors;

    Widget divider() => Container(
          width: 1,
          height: 36,
          color: colors.track,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              _Stat(
                value: '$completed/${AppConstants.totalLessons}',
                label: 'درساً مكتملاً',
              ),
              divider(),
              _Stat(value: hours.toStringAsFixed(1), label: 'ساعة استماع'),
              divider(),
              _Stat(
                value: '$streak',
                label: streak == 1 ? 'يوم متتالٍ' : 'أيام متتالية',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: text.titleLarge?.copyWith(
              fontWeight: AppTypography.medium,
              color: context.colors.brand,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// أعمدة دقائق الاستماع لآخر 7 أيام — الأقدم يميناً واليوم يساراً بالذهبي
class _WeekCard extends ConsumerWidget {
  const _WeekCard();

  /// الحرف الأول من اسم اليوم حسب DateTime.weekday (1 = الاثنين)
  static const _initials = {
    1: 'ن',
    2: 'ث',
    3: 'ر',
    4: 'خ',
    5: 'ج',
    6: 'س',
    7: 'ح',
  };

  static const _barArea = 72.0;
  static const _minScaleSeconds = 15 * 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekListeningProvider);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final totalSeconds = week.fold<int>(0, (s, d) => s + d.seconds);
    // ربع ساعة حدّ أدنى للمقياس: دقائق قليلة لا تملأ العمود كله
    final scale = week.fold<int>(
      _minScaleSeconds,
      (m, d) => d.seconds > m ? d.seconds : m,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text('هذا الأسبوع', style: text.titleSmall),
                  const Spacer(),
                  Text(
                    _formatTotal(totalSeconds),
                    style: text.labelMedium?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < week.length; i++)
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            height: _barArea,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 14,
                                // عمود صغير حتى لليوم الفارغ ليبقى الشكل مقروءاً
                                height: (week[i].seconds / scale * _barArea)
                                    .clamp(3.0, _barArea),
                                decoration: BoxDecoration(
                                  color: i == week.length - 1
                                      ? colors.gold
                                      : week[i].seconds > 0
                                          ? colors.accent
                                          : colors.track,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm / 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _initials[week[i].day.weekday]!,
                            style: text.labelSmall?.copyWith(
                              color: i == week.length - 1
                                  ? colors.brand
                                  : colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTotal(int seconds) {
    if (seconds == 0) return 'لا استماع بعد';
    final minutes = seconds ~/ 60;
    if (minutes == 0) return 'أقل من دقيقة';
    if (minutes < 60) return '$minutes دقيقة';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h ساعة' : '$h ساعة و$m دقيقة';
  }
}

/// تقدّم قراءة الكتاب الإلكتروني مع زر للمتابعة
class _ReadingCard extends ConsumerWidget {
  const _ReadingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(readerIndexProvider).valueOrNull;
    if (index == null) return const SizedBox.shrink();
    final saved = ref.watch(readingPositionProvider);
    final pos = saved ?? const BookPosition(0, 0);
    final progress = saved == null ? 0.0 : index.progressOf(pos);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => openReader(context, pos),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قراءة الكتاب: ${(progress * 100).round()}%',
                        style: text.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          color: colors.gold,
                          backgroundColor: colors.track,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  saved == null ? 'ابدأ' : 'أكمل',
                  style: text.labelLarge?.copyWith(color: colors.brand),
                ),
                Icon(Icons.chevron_left_rounded, color: colors.brand),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentLessons extends ConsumerWidget {
  const _RecentLessons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentProgressProvider);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxs,
          ),
          child: Text('استمعت إليها مؤخراً', style: text.titleMedium),
        ),
        ref.watch(lessonsProvider).when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (lessons) {
                final byId = {for (final l in lessons) l.lesson.id: l.lesson};
                if (recent.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'ابدأ الاستماع لأول درس وسيظهر تقدمك هنا',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: colors.textMuted),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final p in recent.take(5))
                      if (byId[p.lessonId] case final lesson?)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg - 2,
                          ),
                          leading: LessonNumberRing(
                            number: lesson.id,
                            state: isProgressCompleted(p)
                                ? LessonState.completed
                                : LessonState.inProgress,
                            progress: p.percentage,
                          ),
                          title: Text(
                            lesson.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium,
                          ),
                          subtitle: Text(
                            isProgressCompleted(p)
                                ? 'مكتمل'
                                : 'استمعت ${(p.percentage * 100).round()}%، توقفت عند ${AppConstants.formatSeconds(p.position)}',
                            style: text.labelMedium
                                ?.copyWith(color: colors.textMuted),
                          ),
                          onTap: () {
                            ref.read(playerProvider.notifier).play(lesson);
                            context.push('/player/${lesson.id}');
                          },
                        ),
                  ],
                );
              },
            ),
      ],
    );
  }
}
