import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/backup/backup_format.dart';
import 'package:al_daa_wal_dawaa/data/backup/backup_service.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/models/annotation_model.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _t0 = DateTime(2026, 11, 1, 10);
final _t1 = DateTime(2026, 11, 5, 10);

ProgressModel _progress(
  int id,
  int position,
  DateTime played, {
  bool completed = false,
}) =>
    ProgressModel(
      lessonId: id,
      position: position,
      totalDuration: 3000,
      completed: completed,
      lastPlayed: played,
    );

BackupData _sample() => BackupData(
      progress: [
        _progress(1, 2900, _t0, completed: true),
        _progress(2, 600, _t1),
      ],
      listeningLog: {'2026-11-01': 1200, '2026-11-05': 300},
      bookmarks: [
        BookmarkModel(
            lessonId: 2, position: 120, label: 'فائدة', createdAt: _t1),
      ],
      notes: [
        NoteModel(
          lessonId: 2,
          position: 200,
          text: 'ملاحظة',
          createdAt: _t1,
          updatedAt: _t1,
        ),
        NoteModel(
          lessonId: 1,
          position: 50,
          audioPath: 'lesson_1_42.m4a',
          createdAt: _t0,
          updatedAt: _t0,
        ),
      ],
      prefs: {
        'theme_mode': 'dark',
        'reading_position': ['3', '7'],
      },
    );

Uint8List _zip(Map<String, String> entries) {
  final archive = Archive();
  entries.forEach((name, content) {
    archive.addFile(ArchiveFile.string(name, content));
  });
  return ZipEncoder().encodeBytes(archive);
}

String _manifestJson({String app = kBackupApp, int format = kBackupFormat}) =>
    jsonEncode({
      'app': app,
      'format': format,
      'app_version': '1.1.0',
      'created_at': _t1.toIso8601String(),
      'counts': {
        'completed_lessons': 1,
        'bookmarks': 1,
        'notes': 2,
        'voice_notes': 1,
      },
    });

void main() {
  group('merge rules', () {
    test('a completed lesson stays completed whatever is newer', () {
      final local = _progress(1, 2900, _t0, completed: true);
      final incoming = _progress(1, 100, _t1); // أُعيد سماعه من أوله
      final merged = mergeProgress(local, incoming);
      expect(merged.completed, isTrue);
      expect(merged.position, 100); // الموضع من الأحدث
    });

    test('the position comes from the most recently played copy', () {
      final local = _progress(2, 900, _t1);
      final incoming = _progress(2, 400, _t0);
      expect(mergeProgress(local, incoming).position, 900);
      expect(mergeProgress(null, incoming).position, 400);
    });

    test('a listening day keeps the larger value, never the sum', () {
      expect(mergeListeningDay(300, 1200), 1200);
      expect(mergeListeningDay(1200, 300), 1200);
      expect(mergeListeningDay(null, 300), 300);
    });
  });

  group('file format', () {
    test('data survives encode and decode', () {
      final decoded = BackupData.decode(_sample().encode());
      expect(decoded.progress.map((e) => e.lessonId), [1, 2]);
      expect(decoded.progress.first.completed, isTrue);
      expect(decoded.listeningLog, {'2026-11-01': 1200, '2026-11-05': 300});
      expect(decoded.bookmarks.single.label, 'فائدة');
      expect(decoded.bookmarks.single.id, isNull);
      expect(decoded.notes.map((n) => n.audioPath), [null, 'lesson_1_42.m4a']);
      expect(decoded.prefs['reading_position'], ['3', '7']);
    });

    test('a valid file is read with its summary', () {
      final preview = BackupService.read(
        _zip({kManifestEntry: _manifestJson(), kDataEntry: _sample().encode()}),
      );
      expect(preview.manifest.notes, 2);
      expect(preview.manifest.voiceNotes, 1);
      expect(preview.data.progress, hasLength(2));
    });

    test('rejects files that are not a backup of this app', () {
      Matcher fails(String message) => throwsA(
            isA<BackupException>()
                .having((e) => e.message, 'message', contains(message)),
          );

      expect(
        () => BackupService.read(Uint8List.fromList(utf8.encode('not a zip'))),
        fails('ليس نسخة'),
      );
      expect(
        () => BackupService.read(_zip({'readme.txt': 'hello'})),
        fails('ليس نسخة'),
      );
      expect(
        () => BackupService.read(
          _zip({
            kManifestEntry: _manifestJson(app: 'other_app'),
            kDataEntry: '{}',
          }),
        ),
        fails('ليس نسخة'),
      );
      expect(
        () => BackupService.read(
          _zip({
            kManifestEntry: _manifestJson(format: kBackupFormat + 1),
            kDataEntry: '{}',
          }),
        ),
        fails('بإصدار أحدث'),
      );
      expect(
        () => BackupService.read(
          _zip({kManifestEntry: _manifestJson(), kDataEntry: '{broken'}),
        ),
        fails('تالف'),
      );
    });
  });

  group('merging into the database', () {
    late Directory tempDir;
    late Database db;

    setUpAll(sqfliteFfiInit);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('backup_test');
      db = await databaseFactoryFfi.openDatabase(
        p.join(tempDir.path, 'app.db'),
        options: OpenDatabaseOptions(
          version: AppConstants.dbVersion,
          onCreate: DatabaseHelper.onCreate,
        ),
      );
    });

    tearDown(() async {
      await db.close();
      await tempDir.delete(recursive: true);
    });

    String voicePath(String name) => '/data/voice_notes/$name';

    test('restores everything into an empty database', () async {
      final result = await DatabaseHelper.mergeBackupInto(
        db,
        _sample(),
        voicePath: voicePath,
      );
      expect(result.progressUpdated, 2);
      expect(result.daysUpdated, 2);
      expect(result.bookmarksAdded, 1);
      expect(result.notesAdded, 2);

      final notes = await db.query(AppConstants.tableNotes);
      expect(
        notes.map((n) => n['audio_path']),
        containsAll([null, '/data/voice_notes/lesson_1_42.m4a']),
      );
    });

    test('importing the same backup twice changes nothing', () async {
      await DatabaseHelper.mergeBackupInto(db, _sample(), voicePath: voicePath);
      final again = await DatabaseHelper.mergeBackupInto(
        db,
        _sample(),
        voicePath: voicePath,
      );
      expect(again.isEmpty, isTrue);
      expect(await db.query(AppConstants.tableBookmarks), hasLength(1));
      expect(await db.query(AppConstants.tableNotes), hasLength(2));
      final log = await db.query(AppConstants.tableListeningLog);
      expect(
        log.firstWhere((r) => r['day'] == '2026-11-01')['seconds'],
        1200,
      );
    });

    test('keeps local data and only adds what is missing', () async {
      await db.insert(
        AppConstants.tableProgress,
        _progress(2, 1500, DateTime(2026, 11, 6)).toJson(), // أحدث من النسخة
      );
      await db.insert(
        AppConstants.tableListeningLog,
        {'day': '2026-11-05', 'seconds': 900},
      );
      await db.insert(
        AppConstants.tableBookmarks,
        BookmarkModel(lessonId: 5, position: 10, createdAt: _t0).toJson(),
      );

      final result = await DatabaseHelper.mergeBackupInto(
        db,
        _sample(),
        voicePath: voicePath,
      );

      final lesson2 = await db.query(
        AppConstants.tableProgress,
        where: 'lesson_id = 2',
      );
      expect(lesson2.single['position'], 1500); // المحلي أحدث فيبقى
      final day = await db.query(
        AppConstants.tableListeningLog,
        where: "day = '2026-11-05'",
      );
      expect(day.single['seconds'], 900); // الأكبر
      expect(await db.query(AppConstants.tableBookmarks), hasLength(2));
      expect(result.progressUpdated, 1); // الدرس 1 فقط
    });
  });
}
