import 'package:al_daa_wal_dawaa/data/local/download_manager.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, error }

final downloadStatusProvider =
    StateNotifierProvider<DownloadNotifier, Map<int, DownloadStatus>>(
  (ref) => DownloadNotifier(ref),
);

final downloadProgressProvider =
    StateProvider.family<double, int>((ref, lessonId) => 0.0);

final storageUsedProvider = FutureProvider<double>((ref) async {
  return DownloadManager.instance.getStorageUsedMB();
});

class DownloadNotifier extends StateNotifier<Map<int, DownloadStatus>> {
  DownloadNotifier(this._ref) : super({});

  final Ref _ref;

  DownloadStatus statusFor(int lessonId) =>
      state[lessonId] ?? DownloadStatus.notDownloaded;

  void setStatus(int lessonId, DownloadStatus status) {
    state = {...state, lessonId: status};
  }

  /// التقدم يُحدَّث من هنا لا من الـ widget — زر التحميل قد يُتلف أثناء
  /// السكرول أو التنقل، واستخدام ref الخاص به بعدها يرمي استثناءً يوقف التحميل
  Future<void> downloadLesson(LessonModel lesson) async {
    if (statusFor(lesson.id) == DownloadStatus.downloading) return;

    final already = await DownloadManager.instance.isDownloaded(lesson.id);
    if (already) {
      setStatus(lesson.id, DownloadStatus.downloaded);
      return;
    }

    // تحميل سابق للدرس نفسه (ثم حذفه) يترك القيمة عند 100%
    _ref.read(downloadProgressProvider(lesson.id).notifier).state = 0;
    setStatus(lesson.id, DownloadStatus.downloading);

    try {
      await DownloadManager.instance.downloadLesson(
        lessonId: lesson.id,
        url: lesson.fileUrl,
        onProgress: (p) =>
            _ref.read(downloadProgressProvider(lesson.id).notifier).state = p,
      );
      setStatus(lesson.id, DownloadStatus.downloaded);
      _ref.invalidate(storageUsedProvider);
    } catch (e, st) {
      debugPrint('[DL] ❌ downloadLesson failed: $e\n$st');
      setStatus(lesson.id, DownloadStatus.error);
      rethrow;
    }
  }

  Future<void> deleteLesson(int lessonId) async {
    await DownloadManager.instance.deleteLesson(lessonId);
    setStatus(lessonId, DownloadStatus.notDownloaded);
  }

  Future<void> cancelDownload(int lessonId) async {
    await DownloadManager.instance.cancelDownload(lessonId);
    setStatus(lessonId, DownloadStatus.notDownloaded);
  }

  Future<void> loadInitialStatuses(List<int> lessonIds) async {
    final map = <int, DownloadStatus>{};
    for (final id in lessonIds) {
      final downloaded = await DownloadManager.instance.isDownloaded(id);
      map[id] =
          downloaded ? DownloadStatus.downloaded : DownloadStatus.notDownloaded;
    }
    state = map;
  }
}
