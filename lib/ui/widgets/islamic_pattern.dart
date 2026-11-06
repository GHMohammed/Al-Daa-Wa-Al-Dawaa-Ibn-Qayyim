import 'dart:math' as math;

import 'package:flutter/material.dart';

/// زخرفة هندسية إسلامية: نجوم ثمانية {8/3} متداخلة على شبكة مربعة
/// (عند رؤوس الشبكة ومراكز خلاياها) فتتشابك خطوطها في نسيج كثيف.
/// تُرسم بالكود فتبقى حادّة على كل الشاشات ويتغيّر لونها مع الثيم.
class IslamicPattern extends StatelessWidget {
  const IslamicPattern({
    super.key,
    required this.color,
    this.cellSize = 52,
    this.strokeWidth = 0.8,
    this.fadeToBottom = false,
  });

  final Color color;

  /// المسافة بين مراكز النجوم — كلما صغرت ازدادت الكثافة
  final double cellSize;
  final double strokeWidth;

  /// تتلاشى الزخرفة تدريجياً نحو الأسفل (لرأس الصفحة)
  final bool fadeToBottom;

  @override
  Widget build(BuildContext context) {
    final pattern = RepaintBoundary(
      child: CustomPaint(
        painter: _StarLatticePainter(
          color: color,
          cellSize: cellSize,
          strokeWidth: strokeWidth,
        ),
        size: Size.infinite,
      ),
    );
    if (!fadeToBottom) return pattern;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Colors.transparent],
        stops: [0.35, 1],
      ).createShader(rect),
      child: pattern,
    );
  }
}

class _StarLatticePainter extends CustomPainter {
  _StarLatticePainter({
    required this.color,
    required this.cellSize,
    required this.strokeWidth,
  });

  final Color color;
  final double cellSize;
  final double strokeWidth;

  /// نصف قطر النجمة نسبة إلى الخلية — 0.6 يجعل نجوم الجيران تتقاطع
  static const double _radiusRatio = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    final r = cellSize * _radiusRatio;
    final path = Path();

    void star(double cx, double cy) {
      final v = List.generate(8, (k) {
        final a = k * math.pi / 4;
        return Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      });
      for (var k = 0; k < 8; k++) {
        path
          ..moveTo(v[k].dx, v[k].dy)
          ..lineTo(v[(k + 3) % 8].dx, v[(k + 3) % 8].dy);
      }
    }

    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;
    for (var i = -1; i <= cols; i++) {
      for (var j = -1; j <= rows; j++) {
        star(i * cellSize, j * cellSize);
        star(i * cellSize + cellSize / 2, j * cellSize + cellSize / 2);
      }
    }

    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..isAntiAlias = true,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_StarLatticePainter old) =>
      old.color != color ||
      old.cellSize != cellSize ||
      old.strokeWidth != strokeWidth;
}
