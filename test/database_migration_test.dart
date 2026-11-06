import 'dart:io';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Set<String>> _tables(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  );
  return rows.map((r) => r['name'] as String).toSet();
}

void main() {
  late Directory tempDir;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('db_migration_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('upgrading a v1 database keeps progress and adds v2 tables', () async {
    final path = p.join(tempDir.path, 'app.db');

    // مخطط الإصدار 1.0.0 كما شُحن للمستخدمين
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE progress (
              lesson_id INTEGER PRIMARY KEY,
              position INTEGER NOT NULL,
              total_duration INTEGER NOT NULL,
              completed INTEGER NOT NULL,
              last_played TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE downloads (
              lesson_id INTEGER PRIMARY KEY,
              local_path TEXT NOT NULL,
              downloaded_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    await v1.insert('progress', {
      'lesson_id': 7,
      'position': 1234,
      'total_duration': 3000,
      'completed': 0,
      'last_played': '2026-11-01T10:00:00.000',
    });
    await v1.close();

    final v2 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: DatabaseHelper.onCreate,
        onUpgrade: DatabaseHelper.onUpgrade,
      ),
    );

    expect(await v2.getVersion(), 2);
    expect(
      await _tables(v2),
      containsAll([
        AppConstants.tableProgress,
        AppConstants.tableDownloads,
        AppConstants.tableBookmarks,
        AppConstants.tableNotes,
      ]),
    );
    final progress = await v2.query('progress');
    expect(progress, hasLength(1));
    expect(progress.first['position'], 1234);

    await v2.insert(AppConstants.tableNotes, {
      'lesson_id': 7,
      'position': 600,
      'text': 'ملاحظة',
      'created_at': '2026-11-07T00:00:00.000',
      'updated_at': '2026-11-07T00:00:00.000',
    });
    expect(await v2.query(AppConstants.tableNotes), hasLength(1));
    await v2.close();
  });

  test('fresh install creates all tables', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onCreate: DatabaseHelper.onCreate,
        onUpgrade: DatabaseHelper.onUpgrade,
      ),
    );
    expect(
      await _tables(db),
      containsAll([
        AppConstants.tableProgress,
        AppConstants.tableDownloads,
        AppConstants.tableBookmarks,
        AppConstants.tableNotes,
      ]),
    );
    await db.close();
  });
}
