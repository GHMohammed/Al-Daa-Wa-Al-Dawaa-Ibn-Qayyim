import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/app_bottom_nav.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/progress_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// شاشة إحصاءات التقدم في الكتاب
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overall = ref.watch(overallProgressProvider);
    final completed = ref.watch(completedCountProvider);
    final downloaded = ref.watch(downloadedCountProvider);
    final hoursAsync = ref.watch(totalHoursProvider);
    final recentAsync = ref.watch(recentProgressProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: const Text(
                'تقدمك في الكتاب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ProgressCircle(progress: overall, size: 180),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // 1.2 بدلاً من 1.4 — يعطي البطاقة ~132dp ارتفاعاً بدل ~113dp
                // يحل overflow خط Cairo الأطول من الافتراضي
                childAspectRatio: 1.2,
                children: [
                  _StatCard(
                    title: 'الدروس المكتملة',
                    value: '$completed / ${AppConstants.totalLessons}',
                    icon: Icons.check_circle_outline,
                  ),
                  hoursAsync.when(
                    data: (h) => _StatCard(
                      title: 'ساعات الاستماع',
                      value: h.toStringAsFixed(1),
                      icon: Icons.headphones,
                    ),
                    loading: () => const _StatCard(
                      title: 'ساعات الاستماع',
                      value: '...',
                      icon: Icons.headphones,
                    ),
                    error: (_, __) => const _StatCard(
                      title: 'ساعات الاستماع',
                      value: '—',
                      icon: Icons.headphones,
                    ),
                  ),
                  _StatCard(
                    title: 'الدروس المحمّلة',
                    value: '$downloaded',
                    icon: Icons.download_done,
                  ),
                  recentAsync.when(
                    data: (list) {
                      final last = list.isNotEmpty ? list.first : null;
                      final text = last != null
                          ? AppConstants.formatSeconds(last.position)
                          : '—';
                      return _StatCard(
                        title: 'آخر جلسة',
                        value: text,
                        icon: Icons.history,
                      );
                    },
                    loading: () => const _StatCard(
                      title: 'آخر جلسة',
                      value: '...',
                      icon: Icons.history,
                    ),
                    error: (_, __) => const _StatCard(
                      title: 'آخر جلسة',
                      value: '—',
                      icon: Icons.history,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'آخر الدروس المستمَع إليها',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            recentAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('تعذّر تحميل السجل: $e'),
              ),
              data: (progressList) {
                final lessonsAsync = ref.watch(lessonsProvider);
                return lessonsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (lessons) {
                    final lessonMap = {
                      for (final l in lessons) l.lesson.id: l.lesson.title,
                    };
                    if (progressList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('لم تبدأ الاستماع بعد'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: progressList.length.clamp(0, 10),
                      itemBuilder: (_, i) {
                        final p = progressList[i];
                        final title =
                            lessonMap[p.lessonId] ?? 'درس ${p.lessonId}';
                        return ListTile(
                          leading: CircularProgressIndicator(
                            value: p.percentage,
                            strokeWidth: 2,
                          ),
                          title: Text(title),
                          subtitle: Text(
                            '${(p.percentage * 100).toStringAsFixed(0)}% • ${AppConstants.formatSeconds(p.position)}',
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
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
    return Card(
      child: Padding(
        // padding مخفّض لإعطاء مزيد من المساحة للمحتوى
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              // maxLines:1 يمنع التفاف العنوان إلى سطرين ويحل الـ overflow
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
