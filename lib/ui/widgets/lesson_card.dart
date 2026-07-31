import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/download_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// بطاقة درس في القائمة الرئيسية
class LessonCard extends ConsumerWidget {
  const LessonCard({super.key, required this.item});

  final LessonWithProgress item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = item.lesson;
    final progress = item.progress?.percentage ?? 0.0;
    final completed = item.progress?.completed == true ||
        AppConstants.isLessonCompleted(
          item.progress?.position ?? 0,
          lesson.duration,
        );
    final inProgress = !completed && (item.progress?.position ?? 0) > 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // لا await — نطلق التشغيل ونتنقل فوراً في نفس الدورة
          // حتى لا يظهر MiniPlayer ويسجّل نقرة مكررة (race condition)
          // _ensurePlaying في PlayerScreen ستُكمل التشغيل عند الحاجة
          ref.read(playerProvider.notifier).play(lesson);
          context.push('/player/${lesson.id}');
        },
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // دائرة رقم الدرس مع مؤشر التقدم
                _LessonCircle(
                  lessonId: lesson.id,
                  progress: progress,
                  completed: completed,
                  inProgress: inProgress,
                ),
                const SizedBox(width: 12),
                // عنوان + مدة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (inProgress) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // زر التحميل أو شارة محفوظ
                DownloadButton(lesson: lesson, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// دائرة تعرض رقم الدرس ونسبة إنجازه
class _LessonCircle extends StatelessWidget {
  const _LessonCircle({
    required this.lessonId,
    required this.progress,
    required this.completed,
    required this.inProgress,
  });

  final int lessonId;
  final double progress;
  final bool completed;
  final bool inProgress;

  @override
  Widget build(BuildContext context) {
    const double size = 44;

    // مكتمل: دائرة خضراء مكتملة مع علامة ✓
    if (completed) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
      );
    }

    // لم يبدأ أو جارٍ: دائرة بخط دائري رمادي/أخضر والرقم بالداخل
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: inProgress ? progress : 0,
            strokeWidth: 2.5,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              inProgress ? AppColors.secondary : Colors.grey.shade300,
            ),
          ),
          Text(
            '$lessonId',
            style: TextStyle(
              fontSize: lessonId > 99 ? 10 : 13,
              fontWeight: FontWeight.bold,
              color: inProgress ? AppColors.primary : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
