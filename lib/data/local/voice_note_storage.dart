import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ملفات الملاحظات الصوتية داخل مجلد التطبيق (لا تحتاج صلاحية تخزين)
class VoiceNoteStorage {
  VoiceNoteStorage._();

  /// مجلد الملاحظات الصوتية (يُنشأ إن لم يوجد) — للنسخ الاحتياطي أيضاً
  static Future<Directory> directory() => _dir();

  static Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'voice_notes'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// مسار ملف جديد فريد لتسجيل قادم
  static Future<String> newPath(int lessonId) async {
    final dir = await _dir();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, 'lesson_${lessonId}_$stamp.m4a');
  }

  static Future<void> delete(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
