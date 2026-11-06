import 'dart:math' as math;

import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/download_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum LessonState { notStarted, inProgress, completed }

/// صف درس في القائمة الرئيسية: دائرة الرقم مع التقدم، العنوان والحالة، زر التحميل
class LessonCard extends ConsumerWidget {
  const LessonCard({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    // select: تُعاد بناء هذا الصف فقط عند تغيّر تقدم درسه
    final saved = ref.watch(
      progressMapProvider.select((map) => map[lesson.id]),
    );
    final progress = saved?.percentage ?? 0.0;
    final state = saved != null && isProgressCompleted(saved)
        ? LessonState.completed
        : (saved?.position ?? 0) > 0
            ? LessonState.inProgress
            : LessonState.notStarted;

    // المدة الحقيقية تُعرف بعد أول تشغيل؛ مدة JSON تقديرية فلا نعرضها
    final minutes = saved != null ? (saved.totalDuration / 60).round() : null;
    final status = switch (state) {
      LessonState.completed => 'مكتمل',
      LessonState.inProgress => 'استمعت ${(progress * 100).round()}%',
      LessonState.notStarted => 'لم تبدأ بعد',
    };

    return InkWell(
      onTap: () {
        // لا await — نطلق التشغيل ونتنقل فوراً في نفس الدورة
        // حتى لا يظهر MiniPlayer ويسجّل نقرة مكررة (race condition)
        // _ensurePlaying في PlayerScreen ستُكمل التشغيل عند الحاجة
        ref.read(playerProvider.notifier).play(lesson);
        context.push('/player/${lesson.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg - 2,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            LessonNumberRing(
              number: lesson.id,
              state: state,
              progress: progress,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: state == LessonState.inProgress
                          ? AppTypography.medium
                          : AppTypography.regular,
                      color: state == LessonState.notStarted
                          ? colors.textSecondary
                          : null,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (minutes != null) TextSpan(text: '$minutes دقيقة، '),
                        TextSpan(
                          text: status,
                          style: state == LessonState.inProgress
                              ? TextStyle(color: colors.gold)
                              : null,
                        ),
                      ],
                    ),
                    style: text.labelMedium?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
            DownloadButton(lesson: lesson, compact: true),
          ],
        ),
      ),
    );
  }
}

/// دائرة رقم الدرس: ممتلئة بالأخضر إذا اكتمل، وبإطار ذهبي جزئي إذا كان قيد الاستماع
class LessonNumberRing extends StatelessWidget {
  const LessonNumberRing({
    super.key,
    required this.number,
    required this.state,
    this.progress = 0,
    this.size = 40,
  });

  final int number;
  final LessonState state;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final completed = state == LessonState.completed;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          fill: completed ? colors.brand : Theme.of(context).cardTheme.color!,
          track: completed
              ? colors.brand
              : state == LessonState.inProgress
                  ? colors.track
                  : colors.ringTrack,
          arc: colors.gold,
          progress: state == LessonState.inProgress ? progress : 0,
        ),
        child: Center(
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: number > 99 ? 11 : 13,
              fontWeight: AppTypography.medium,
              color: completed
                  ? Colors.white
                  : state == LessonState.inProgress
                      ? null
                      : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fill,
    required this.track,
    required this.arc,
    required this.progress,
  });

  final Color fill;
  final Color track;
  final Color arc;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1.5;
    canvas
      ..drawCircle(c, r, Paint()..color = fill)
      ..drawCircle(
        c,
        r,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = arc
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fill != fill ||
      old.track != track ||
      old.arc != arc ||
      old.progress != progress;
}
