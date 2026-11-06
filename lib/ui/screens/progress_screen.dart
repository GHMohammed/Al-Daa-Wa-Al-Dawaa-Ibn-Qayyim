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
    final hours = ref.watch(totalHoursProvider);
    final recent = ref.watch(recentProgressProvider);
    final last = recent.isNotEmpty ? recent.first : null;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: BoxDecoration(
                color: context.colors.header,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Text(
                'تقدمك في الكتاب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.onHeader,
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
                  _StatCard(
                    title: 'ساعات الاستماع',
                    value: hours.toStringAsFixed(1),
                    icon: Icons.headphones,
                  ),
                  _StatCard(
                    title: 'الدروس المحمّلة',
                    value: '$downloaded',
                    icon: Icons.download_done,
                  ),
                  _StatCard(
                    title: 'آخر جلسة',
                    value: last != null
                        ? AppConstants.formatSeconds(last.position)
                        : '—',
                    icon: Icons.history,
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
            ref.watch(lessonsProvider).when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (lessons) {
                    final lessonMap = {
                      for (final l in lessons) l.lesson.id: l.lesson.title,
                    };
                    if (recent.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('لم تبدأ الاستماع بعد'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length.clamp(0, 10),
                      itemBuilder: (_, i) {
                        final p = recent[i];
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
    final colors = context.colors;
    return Card(
      child: Padding(
        // padding مخفّض لإعطاء مزيد من المساحة للمحتوى
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.brand, size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.brand,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: colors.textMuted),
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
