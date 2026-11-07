import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/backup/backup_format.dart';
import 'package:al_daa_wal_dawaa/data/models/annotation_model.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// قاعدة البيانات المحلية للتقدم والتحميلات
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // على الويب: اسم ملف بسيط؛ على الهاتف: مسار مجلد التطبيق
    final path = kIsWeb
        ? AppConstants.dbName
        : join(await getDatabasesPath(), AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  /// تثبيت جديد: ننشئ كل الإصدارات بالترتيب
  @visibleForTesting
  static Future<void> onCreate(Database db, int version) async {
    await _createV1(db);
    await _createV2(db);
    await _createV3(db);
  }

  /// ترقية تطبيق موجود: ننفّذ فقط ما ينقصه دون المساس ببيانات المستخدم
  @visibleForTesting
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) await _createV2(db);
    if (oldVersion < 3) await _createV3(db);
  }

  /// سجل الاستماع اليومي: ثوانٍ فعلية لكل يوم (YYYY-MM-DD) — للرسم والأيام المتتالية
  static Future<void> _createV3(Database db) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableListeningLog} (
        day TEXT PRIMARY KEY,
        seconds INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBookmarks} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        label TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_bookmarks_lesson ON ${AppConstants.tableBookmarks} (lesson_id)',
    );

    // audio_path للملاحظات الصوتية (المرحلة 3)؛ text للنصية — أحدهما على الأقل
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotes} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        text TEXT,
        audio_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_notes_lesson ON ${AppConstants.tableNotes} (lesson_id)',
    );
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableProgress} (
        lesson_id INTEGER PRIMARY KEY,
        position INTEGER NOT NULL,
        total_duration INTEGER NOT NULL,
        completed INTEGER NOT NULL,
        last_played TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableDownloads} (
        lesson_id INTEGER PRIMARY KEY,
        local_path TEXT NOT NULL,
        downloaded_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> saveProgress(ProgressModel progress) async {
    final db = await database;
    await db.insert(
      AppConstants.tableProgress,
      progress.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProgressModel?> getProgress(int lessonId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableProgress,
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProgressModel.fromJson(rows.first);
  }

  Future<List<ProgressModel>> getAllProgress() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableProgress,
      orderBy: 'last_played DESC',
    );
    return rows.map(ProgressModel.fromJson).toList();
  }

  Future<void> saveDownload(int lessonId, String localPath) async {
    final db = await database;
    await db.insert(
      AppConstants.tableDownloads,
      {
        'lesson_id': lessonId,
        'local_path': localPath,
        'downloaded_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getDownloadPath(int lessonId) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableDownloads,
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['local_path'] as String?;
  }

  Future<void> deleteDownload(int lessonId) async {
    final db = await database;
    await db.delete(
      AppConstants.tableDownloads,
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
    );
  }

  Future<Map<int, String>> getAllDownloads() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableDownloads);
    return {
      for (final row in rows)
        row['lesson_id'] as int: row['local_path'] as String,
    };
  }

  // ── العلامات المرجعية ────────────────────────────────────────────

  Future<List<BookmarkModel>> getAllBookmarks() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableBookmarks,
      orderBy: 'created_at DESC',
    );
    return rows.map(BookmarkModel.fromJson).toList();
  }

  /// يُعيد العلامة مع المعرّف الذي أنشأته القاعدة
  Future<BookmarkModel> insertBookmark(BookmarkModel bookmark) async {
    final db = await database;
    final id = await db.insert(AppConstants.tableBookmarks, bookmark.toJson());
    return bookmark.copyWith(id: id);
  }

  Future<void> updateBookmarkLabel(int id, String? label) async {
    final db = await database;
    await db.update(
      AppConstants.tableBookmarks,
      {'label': label},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteBookmark(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableBookmarks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── الملاحظات ─────────────────────────────────────────────────────

  Future<List<NoteModel>> getAllNotes() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableNotes,
      orderBy: 'created_at DESC',
    );
    return rows.map(NoteModel.fromJson).toList();
  }

  Future<NoteModel> insertNote(NoteModel note) async {
    final db = await database;
    final id = await db.insert(AppConstants.tableNotes, note.toJson());
    return note.copyWith(id: id);
  }

  Future<void> updateNoteText(int id, String text, DateTime updatedAt) async {
    final db = await database;
    await db.update(
      AppConstants.tableNotes,
      {'text': text, 'updated_at': updatedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableNotes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── سجل الاستماع ──────────────────────────────────────────────────

  /// يضيف ثوانيَ إلى يوم (بلا UPSERT لأن SQLite في أندرويد القديم لا يدعمه)
  Future<void> addListening(String day, int seconds) async {
    if (seconds <= 0) return;
    final db = await database;
    final updated = await db.rawUpdate(
      'UPDATE ${AppConstants.tableListeningLog} SET seconds = seconds + ? WHERE day = ?',
      [seconds, day],
    );
    if (updated == 0) {
      await db.insert(AppConstants.tableListeningLog, {
        'day': day,
        'seconds': seconds,
      });
    }
  }

  Future<Map<String, int>> getListeningLog() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableListeningLog);
    return {for (final r in rows) r['day'] as String: r['seconds'] as int};
  }

  // ── استعادة نسخة احتياطية ────────────────────────────────────────

  Future<BackupMergeResult> mergeBackup(
    BackupData data, {
    required String Function(String fileName) voicePath,
  }) async =>
      mergeBackupInto(await database, data, voicePath: voicePath);

  /// يدمج النسخة في عملية واحدة: إن فشل أي جزء لا يتغير شيء.
  /// قواعد الدمج في backup_format.dart. [voicePath] يحوّل اسم ملف
  /// الملاحظة الصوتية في النسخة إلى مساره على هذا الجهاز.
  @visibleForTesting
  static Future<BackupMergeResult> mergeBackupInto(
    Database db,
    BackupData data, {
    required String Function(String fileName) voicePath,
  }) {
    return db.transaction((txn) async {
      var progressUpdated = 0;
      final localProgress = {
        for (final row in await txn.query(AppConstants.tableProgress))
          row['lesson_id'] as int: ProgressModel.fromJson(row),
      };
      for (final incoming in data.progress) {
        final local = localProgress[incoming.lessonId];
        final merged = mergeProgress(local, incoming);
        if (local != null && sameProgress(local, merged)) continue;
        await txn.insert(
          AppConstants.tableProgress,
          merged.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        progressUpdated++;
      }

      var daysUpdated = 0;
      final localLog = {
        for (final row in await txn.query(AppConstants.tableListeningLog))
          row['day'] as String: row['seconds'] as int,
      };
      for (final entry in data.listeningLog.entries) {
        final local = localLog[entry.key];
        final merged = mergeListeningDay(local, entry.value);
        if (merged == local) continue;
        await txn.insert(
          AppConstants.tableListeningLog,
          {'day': entry.key, 'seconds': merged},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        daysUpdated++;
      }

      var bookmarksAdded = 0;
      final bookmarkKeys = {
        for (final row in await txn.query(AppConstants.tableBookmarks))
          annotationKey(
            row['lesson_id'] as int,
            row['position'] as int,
            DateTime.parse(row['created_at'] as String),
          ),
      };
      for (final b in data.bookmarks) {
        if (!bookmarkKeys
            .add(annotationKey(b.lessonId, b.position, b.createdAt))) {
          continue;
        }
        await txn.insert(
          AppConstants.tableBookmarks,
          b.toJson()..remove('id'),
        );
        bookmarksAdded++;
      }

      var notesAdded = 0;
      final noteKeys = {
        for (final row in await txn.query(AppConstants.tableNotes))
          annotationKey(
            row['lesson_id'] as int,
            row['position'] as int,
            DateTime.parse(row['created_at'] as String),
          ),
      };
      for (final n in data.notes) {
        if (!noteKeys.add(annotationKey(n.lessonId, n.position, n.createdAt))) {
          continue;
        }
        final row = n.toJson()..remove('id');
        if (n.audioPath != null) row['audio_path'] = voicePath(n.audioPath!);
        await txn.insert(AppConstants.tableNotes, row);
        notesAdded++;
      }

      return BackupMergeResult(
        progressUpdated: progressUpdated,
        daysUpdated: daysUpdated,
        bookmarksAdded: bookmarksAdded,
        notesAdded: notesAdded,
      );
    });
  }
}
