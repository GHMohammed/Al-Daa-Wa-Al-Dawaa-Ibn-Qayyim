import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/app_bottom_nav.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/lesson_card.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/page_header.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/status_bar_scrim.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/progress_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// شاشة إحصاءات التقدم في الكتاب
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overall = ref.watch(overallProgressProvider);
    final completed = ref.watch(completedCountProvider);
    final downloaded = ref.watch(downloadedCountProvider);
    final hours = ref.watch(totalHoursProvider);
    final recent = ref.watch(recentProgressProvider);
    final last = recent.isNotEmpty ? recent.first : null;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: StatusBarScrim(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const PageHeader(
                title: 'تقدمك',
                subtitle: 'ما أنجزته من شرح الكتاب',
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(child: ProgressCircle(progress: overall, size: 170)),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.45,
                  children: [
                    _StatCard(
                      title: 'الدروس المكتملة',
                      value: '$completed من ${AppConstants.totalLessons}',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    _StatCard(
                      title: 'ساعات الاستماع',
                      value: hours.toStringAsFixed(1),
                      icon: Icons.headphones_outlined,
                    ),
                    _StatCard(
                      title: 'الدروس المحفوظة',
                      value: '$downloaded',
                      icon: Icons.download_done_rounded,
                    ),
                    _StatCard(
                      title: 'آخر موضع',
                      value: last != null
                          ? AppConstants.formatSeconds(last.position)
                          : '—',
                      icon: Icons.history_rounded,
                    ),
                  ],
                ),
              ),
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
                      final byId = {
                        for (final l in lessons) l.lesson.id: l.lesson
                      };
                      if (recent.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'ابدأ الاستماع لأول درس وسيظهر تقدمك هنا',
                            textAlign: TextAlign.center,
                            style: text.bodyMedium
                                ?.copyWith(color: colors.textMuted),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final p in recent.take(10))
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
                                  ref
                                      .read(playerProvider.notifier)
                                      .play(lesson);
                                  context.push('/player/${lesson.id}');
                                },
                              ),
                        ],
                      );
                    },
                  ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: colors.brand, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(
                    fontWeight: AppTypography.medium,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
