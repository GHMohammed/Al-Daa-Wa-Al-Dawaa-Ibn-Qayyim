import 'dart:io';
import 'dart:ui' as ui;

import 'package:al_daa_wal_dawaa/core/theme/app_colors.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_typography.dart';
import 'package:al_daa_wal_dawaa/ui/widgets/islamic_pattern.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// غلاف الدرس لإشعار التشغيل وشاشة القفل: نفس غلاف المشغّل (أخضر عميق،
/// زخرفة ذهبية، ورقم الدرس في دائرة). أندرويد يشتق ألوان بطاقة التشغيل
/// في شاشة القفل من هذه الصورة، فتتبع هوية التطبيق تلقائياً.
///
/// يُرسم مرة لكل درس ويُحفظ ملفاً، لأن audio_service يحتاج رابط ملف.
abstract final class LessonArtwork {
  static const double _size = 512;

  /// يتغيّر عند تعديل التصميم، فتُعاد الرسومات بدل استخدام القديمة
  static const _version = 1;

  static Future<Uri?> uriFor(int lessonNumber) async {
    try {
      final dir = Directory(
        p.join((await getTemporaryDirectory()).path, 'artwork'),
      );
      final file =
          File(p.join(dir.path, 'lesson_${lessonNumber}_v$_version.png'));
      if (!await file.exists()) {
        await dir.create(recursive: true);
        await file.writeAsBytes(await _render(lessonNumber), flush: true);
      }
      return file.uri;
    } catch (_) {
      return null; // الإشعار يعمل بدون صورة
    }
  }

  static Future<List<int>> _render(int number) async {
    const size = Size(_size, _size);
    const center = Offset(_size / 2, _size / 2);
    const ring = _size * 0.4;
    const gold = AppPalette.gold500;
    const green = AppPalette.green950;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // الصورة مربعة بلا حواف دائرية: النظام يقصّها ويدوّرها بنفسه
    canvas.drawRect(Offset.zero & size, Paint()..color = green);
    IslamicPattern.paintOn(
      canvas,
      size,
      color: gold.withValues(alpha: 0.24),
      cellSize: _size / 4,
      strokeWidth: 1.4,
    );
    canvas
      ..drawCircle(center, ring / 2, Paint()..color = green)
      ..drawCircle(
        center,
        ring / 2,
        Paint()
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

    final text = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: gold,
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.medium,
          fontSize: ring * (number > 9 ? 0.34 : 0.38),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));

    final image =
        await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }
}
