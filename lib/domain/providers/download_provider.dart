import 'package:al_daa_wal_dawaa/data/local/download_manager.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, error }

final downloadStatusProvider =
    StateNotifierProvider<DownloadNotifier, Map<int, DownloadStatus>>(
  (ref) => DownloadNotifier(),
);

final downloadProgressProvider =
    StateProvider.family<double, int>((ref, lessonId) => 0.0);

final storageUsedProvider = FutureProvider<double>((ref) async {
  return DownloadManager.instance.getStorageUsedMB();
});

class DownloadNotifier extends StateNotifier<Map<int, DownloadStatus>> {
  DownloadNotifier() : super({});

  DownloadStatus statusFor(int lessonId) =>
      state[lessonId] ?? DownloadStatus.notDownloaded;

  void setStatus(int lessonId, DownloadStatus status) {
    state = {...state, lessonId: status};
  }

  Future<void> downloadLesson(
    LessonModel lesson,
    void Function(double progress) onProgress,
  ) async {
    if (statusFor(lesson.id) == DownloadStatus.downloading) return;

    final already = await DownloadManager.instance.isDownloaded(lesson.id);
    if (already) {
      setStatus(lesson.id, DownloadStatus.downloaded);
      return;
    }

    setStatus(lesson.id, DownloadStatus.downloading);

    try {
      await DownloadManager.instance.downloadLesson(
        lessonId: lesson.id,
        url: lesson.fileUrl,
        onProgress: onProgress,
      );
      setStatus(lesson.id, DownloadStatus.downloaded);
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
      map[id] = downloaded
          ? DownloadStatus.downloaded
          : DownloadStatus.notDownloaded;
    }
    state = map;
  }
}
