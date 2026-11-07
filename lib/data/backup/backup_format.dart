import 'dart:convert';
import 'dart:math' as math;

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/models/annotation_model.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';

/// صيغة ملف النسخة الاحتياطية اليدوية (docs/manual-backup-plan.md).
/// يُرفع الرقم عند تغيير شكل data.json، ويُرفض ما هو أحدث من التطبيق.
const int kBackupFormat = 1;

/// علامة تميّز نسخ هذا التطبيق عن أي ملف zip آخر
const String kBackupApp = 'al_daa_wal_dawaa';

const String kManifestEntry = 'manifest.json';
const String kDataEntry = 'data.json';
const String kVoiceNotesDir = 'voice_notes/';

/// خطأ برسالة جاهزة للعرض للمستخدم
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BackupManifest {
  const BackupManifest({
    required this.format,
    required this.appVersion,
    required this.createdAt,
    required this.completedLessons,
    required this.bookmarks,
    required this.notes,
    required this.voiceNotes,
  });

  final int format;
  final String appVersion;
  final DateTime createdAt;
  final int completedLessons;
  final int bookmarks;
  final int notes;
  final int voiceNotes;

  Map<String, Object> toJson() => {
        'app': kBackupApp,
        'format': format,
        'app_version': appVersion,
        'created_at': createdAt.toIso8601String(),
        'counts': {
          'completed_lessons': completedLessons,
          'bookmarks': bookmarks,
          'notes': notes,
          'voice_notes': voiceNotes,
        },
      };

  /// يرمي [BackupException] إن لم يكن الملف نسخة من هذا التطبيق
  /// أو كان بصيغة أحدث من التي يفهمها
  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    if (json['app'] != kBackupApp) {
      throw const BackupException('هذا الملف ليس نسخة احتياطية من التطبيق');
    }
    final format = json['format'] as int? ?? 0;
    if (format > kBackupFormat) {
      throw const BackupException(
        'أُنشئت هذه النسخة بإصدار أحدث من التطبيق، حدّث التطبيق ثم أعد المحاولة',
      );
    }
    final counts = json['counts'] as Map<String, dynamic>? ?? const {};
    return BackupManifest(
      format: format,
      appVersion: json['app_version'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      completedLessons: counts['completed_lessons'] as int? ?? 0,
      bookmarks: counts['bookmarks'] as int? ?? 0,
      notes: counts['notes'] as int? ?? 0,
      voiceNotes: counts['voice_notes'] as int? ?? 0,
    );
  }
}

/// محتوى data.json. في الملاحظات الصوتية يحمل [NoteModel.audioPath]
/// اسم الملف داخل voice_notes/ فقط، لأن المسار الكامل يختلف بين الهواتف.
class BackupData {
  const BackupData({
    this.progress = const [],
    this.listeningLog = const {},
    this.bookmarks = const [],
    this.notes = const [],
    this.prefs = const {},
  });

  final List<ProgressModel> progress;
  final Map<String, int> listeningLog;
  final List<BookmarkModel> bookmarks;
  final List<NoteModel> notes;

  /// إعدادات SharedPreferences المختارة (انظر BackupService)
  final Map<String, Object> prefs;

  String encode() => jsonEncode({
        'progress': [for (final p in progress) p.toJson()],
        'listening_log': listeningLog,
        // المعرّف المحلي لا معنى له على جهاز آخر
        'bookmarks': [
          for (final b in bookmarks) b.toJson()..remove('id'),
        ],
        'notes': [for (final n in notes) n.toJson()..remove('id')],
        'prefs': prefs,
      });

  factory BackupData.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    List<Map<String, dynamic>> rows(String key) =>
        (json[key] as List? ?? const []).cast<Map<String, dynamic>>();
    return BackupData(
      progress: rows('progress').map(ProgressModel.fromJson).toList(),
      listeningLog: (json['listening_log'] as Map<String, dynamic>? ?? {})
          .map((day, seconds) => MapEntry(day, seconds as int)),
      bookmarks: rows('bookmarks').map(BookmarkModel.fromJson).toList(),
      notes: rows('notes').map(NoteModel.fromJson).toList(),
      prefs: (json['prefs'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value as Object)),
    );
  }
}

/// ما تغيّر فعلاً بعد الاستعادة — للرسالة التي تُعرض للمستخدم
class BackupMergeResult {
  const BackupMergeResult({
    this.progressUpdated = 0,
    this.daysUpdated = 0,
    this.bookmarksAdded = 0,
    this.notesAdded = 0,
  });

  final int progressUpdated;
  final int daysUpdated;
  final int bookmarksAdded;
  final int notesAdded;

  bool get isEmpty =>
      progressUpdated == 0 &&
      daysUpdated == 0 &&
      bookmarksAdded == 0 &&
      notesAdded == 0;
}

// ── قواعد الدمج: لا يُحذف شيء، وتكرار الاستيراد لا يكرر شيئاً ─────────

bool _isCompleted(ProgressModel p) =>
    p.completed || AppConstants.isLessonCompleted(p.position, p.totalDuration);

/// الموضع من الأحدث استماعاً، والإكمال لا يُسحب إن تحقق في أحدهما
ProgressModel mergeProgress(ProgressModel? local, ProgressModel incoming) {
  if (local == null) return incoming;
  final newer =
      incoming.lastPlayed.isAfter(local.lastPlayed) ? incoming : local;
  return newer.copyWith(
    completed: _isCompleted(local) || _isCompleted(incoming),
  );
}

bool sameProgress(ProgressModel a, ProgressModel b) =>
    a.position == b.position &&
    a.totalDuration == b.totalDuration &&
    a.completed == b.completed &&
    a.lastPlayed.isAtSameMomentAs(b.lastPlayed);

/// الأكبر لا المجموع، حتى لا تتضاعف الساعات عند استيراد النسخة مرتين
int mergeListeningDay(int? local, int incoming) =>
    math.max(local ?? 0, incoming);

/// علامة أو ملاحظة هي نفسها إن اتفقت في الدرس والموضع ووقت الإنشاء
String annotationKey(int lessonId, int position, DateTime createdAt) =>
    '$lessonId|$position|${createdAt.microsecondsSinceEpoch}';
