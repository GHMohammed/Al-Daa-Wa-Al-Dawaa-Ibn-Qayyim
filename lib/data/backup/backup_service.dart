import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/backup/backup_format.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/local/voice_note_storage.dart';
import 'package:al_daa_wal_dawaa/data/models/annotation_model.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// نسخة مقروءة من ملف، جاهزة لعرض ملخصها ثم استعادتها
class BackupPreview {
  const BackupPreview(this.manifest, this.data, this._archive);

  final BackupManifest manifest;
  final BackupData data;
  final Archive _archive;
}

/// التصدير والاستيراد اليدوي (docs/manual-backup-plan.md)
abstract final class BackupService {
  /// الإعدادات التي تُحفظ في النسخة، بأسمائها في SharedPreferences
  static const _prefKeys = [
    'theme_mode',
    'autoplay_next',
    'playback_speed',
    'reading_position',
    'reader_font_size',
    'reader_spacing',
    'reader_theme',
  ];

  /// موضع القراءة يُستعاد فقط إن لم يكن للمستخدم موضع؛ والبقية لا تُستعاد
  static const _readingPositionKey = 'reading_position';

  static const lastExportKey = 'last_backup_export';

  // ── التصدير ──────────────────────────────────────────────────────

  /// يبني ملف النسخة في المجلد المؤقت ويُعيده (للمشاركة)
  static Future<File> export() async {
    final db = DatabaseHelper.instance;
    final progress = await db.getAllProgress();
    final notes = await db.getAllNotes();
    final archive = Archive();

    // الملاحظات الصوتية: الملف داخل voice_notes/ والمسار يصبح اسمه فقط
    var voiceCount = 0;
    final portableNotes = <NoteModel>[];
    for (final note in notes) {
      final path = note.audioPath;
      if (path == null) {
        portableNotes.add(note);
        continue;
      }
      final name = p.basename(path);
      final file = File(path);
      if (await file.exists()) {
        archive.addFile(
          ArchiveFile.bytes('$kVoiceNotesDir$name', await file.readAsBytes()),
        );
        voiceCount++;
      }
      portableNotes.add(_withAudio(note, name));
    }

    final prefs = await SharedPreferences.getInstance();
    final data = BackupData(
      progress: progress,
      listeningLog: await db.getListeningLog(),
      bookmarks: await db.getAllBookmarks(),
      notes: portableNotes,
      prefs: {
        for (final key in _prefKeys)
          if (prefs.get(key) case final Object value) key: value,
      },
    );
    final manifest = BackupManifest(
      format: kBackupFormat,
      appVersion: AppConstants.appVersion,
      createdAt: DateTime.now(),
      completedLessons: progress
          .where(
            (p) =>
                p.completed ||
                AppConstants.isLessonCompleted(p.position, p.totalDuration),
          )
          .length,
      bookmarks: data.bookmarks.length,
      notes: notes.length,
      voiceNotes: voiceCount,
    );

    archive
      ..addFile(
        ArchiveFile.string(kManifestEntry, jsonEncode(manifest.toJson())),
      )
      ..addFile(ArchiveFile.string(kDataEntry, data.encode()));

    final day = manifest.createdAt.toIso8601String().substring(0, 10);
    final file = File(
      p.join(
        (await getTemporaryDirectory()).path,
        'al-daa-wal-dawaa-backup-$day.zip',
      ),
    );
    await file.writeAsBytes(ZipEncoder().encodeBytes(archive), flush: true);
    return file;
  }

  // ── الاستيراد ─────────────────────────────────────────────────────

  /// يقرأ الملف ويتحقق منه دون تغيير أي شيء. يرمي [BackupException]
  static BackupPreview read(Uint8List bytes) {
    final Archive archive;
    final BackupManifest manifest;
    final BackupData data;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupException('هذا الملف ليس نسخة احتياطية صالحة');
    }
    final manifestFile = archive.findFile(kManifestEntry);
    final dataFile = archive.findFile(kDataEntry);
    if (manifestFile == null || dataFile == null) {
      throw const BackupException('هذا الملف ليس نسخة احتياطية من التطبيق');
    }
    try {
      manifest = BackupManifest.fromJson(
        jsonDecode(utf8.decode(manifestFile.content)) as Map<String, dynamic>,
      );
      data = BackupData.decode(utf8.decode(dataFile.content));
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException('ملف النسخة تالف ولا يمكن قراءته');
    }
    return BackupPreview(manifest, data, archive);
  }

  /// يدمج النسخة دون حذف شيء. الملفات الصوتية تُنسخ أولاً، وإن فشل الدمج
  /// تُحذف الملفات التي أُضيفت للتو، فلا يبقى أثر لاستعادة فاشلة.
  static Future<BackupMergeResult> restore(BackupPreview preview) async {
    final dir = await VoiceNoteStorage.directory();
    final written = <File>[];
    final paths = <String, String>{};

    try {
      for (final note in preview.data.notes) {
        final name = note.audioPath;
        if (name == null || paths.containsKey(name)) continue;
        final entry = preview._archive.findFile('$kVoiceNotesDir$name');
        paths[name] = entry == null
            // الملف لم يكن في النسخة: تبقى الملاحظة، والمشغّل يتعامل مع المفقود
            ? p.join(dir.path, name)
            : await _placeVoiceFile(dir, name, entry.content, written);
      }

      final result = await DatabaseHelper.instance.mergeBackup(
        preview.data,
        voicePath: (name) => paths[name] ?? p.join(dir.path, name),
      );

      final position = preview.data.prefs[_readingPositionKey];
      final prefs = await SharedPreferences.getInstance();
      if (position is List && !prefs.containsKey(_readingPositionKey)) {
        await prefs.setStringList(
          _readingPositionKey,
          position.map((e) => '$e').toList(),
        );
      }
      return result;
    } catch (_) {
      for (final file in written) {
        if (await file.exists()) await file.delete();
      }
      rethrow;
    }
  }

  /// يضع ملف الملاحظة في مجلدها: إن وُجد ملف بنفس الاسم والحجم فهو نفسه،
  /// وإن اختلف الحجم يُحفظ باسم جديد حتى لا يُستبدل ملف آخر
  static Future<String> _placeVoiceFile(
    Directory dir,
    String name,
    Uint8List bytes,
    List<File> written,
  ) async {
    var target = File(p.join(dir.path, name));
    if (await target.exists()) {
      if (await target.length() == bytes.length) return target.path;
      final stem = p.basenameWithoutExtension(name);
      final ext = p.extension(name);
      var i = 1;
      do {
        target = File(p.join(dir.path, '${stem}_$i$ext'));
        i++;
      } while (await target.exists());
    }
    await target.writeAsBytes(bytes, flush: true);
    written.add(target);
    return target.path;
  }

  static NoteModel _withAudio(NoteModel note, String audioPath) => NoteModel(
        id: note.id,
        lessonId: note.lessonId,
        position: note.position,
        text: note.text,
        audioPath: audioPath,
        createdAt: note.createdAt,
        updatedAt: note.updatedAt,
      );
}
