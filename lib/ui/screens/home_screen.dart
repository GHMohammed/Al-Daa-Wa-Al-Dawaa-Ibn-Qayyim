import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/app_bottom_nav.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/lesson_card.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// الشاشة الرئيسية — قائمة الدروس والتقدم العام
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final overall = ref.watch(overallProgressProvider);
    final completed = ref.watch(completedCountProvider);
    final percent = (overall * 100).toStringAsFixed(0);
    const total = AppConstants.totalLessons;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // AnnotatedRegion يضمن أن أيقونات status bar تبقى بيضاء
          // فوق الهيدر الأخضر بغض النظر عن إعداد ThemeMode
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: _Header(
              progress: overall,
              percent: percent,
              completed: completed,
              total: total,
            ),
          ),
          Expanded(
            child: lessonsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('تعذّر تحميل الدروس: $e'),
              ),
              data: (lessons) => ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: lessons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => LessonCard(item: lessons[i]),
              ),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.progress,
    required this.percent,
    required this.completed,
    required this.total,
  });

  final double progress;
  final String percent;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    // Container خارجي بدون borderRadius يمتد خلف الـ status bar بالكامل
    // SafeArea(bottom: false) يدفع المحتوى أسفل الـ status bar
    // Container داخلي يرسم الزوايا الدائرية في الأسفل فقط
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            top: 16,
            bottom: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                AppConstants.sheikhName,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إنجاز الكتاب $percent%',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    '$completed من $total درس',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
