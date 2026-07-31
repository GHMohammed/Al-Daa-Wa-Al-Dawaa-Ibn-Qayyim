import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

  /// مجموع ساعات الاستماع (من المواضع المحفوظة للدروس المكتملة وجزئياً)
  Future<double> getTotalListeningHours() async {
    final all = await getAllProgress();
    final totalSeconds = all.fold<int>(0, (sum, p) => sum + p.position);
    return totalSeconds / 3600.0;
  }
}
