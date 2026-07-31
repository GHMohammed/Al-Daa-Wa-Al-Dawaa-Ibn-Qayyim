import 'dart:math' as math;

import 'package:al_daa_wal_dawaa/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// دائرة تقدم مخصّصة للنسبة المئوية
class ProgressCircle extends StatelessWidget {
  const ProgressCircle({
    super.key,
    required this.progress,
    this.size = 160,
    this.strokeWidth = 12,
    this.centerText,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final String? centerText;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    final text = centerText ?? '$percent%';

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CirclePainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          color: AppColors.secondary,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A4A40)
              : AppColors.lightSurface,
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
