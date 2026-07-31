import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:al_daa_wal_dawaa/data/remote/archive_service.dart';
import 'package:al_daa_wal_dawaa/domain/providers/download_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LessonWithProgress {
  final LessonModel lesson;
  final ProgressModel? progress;
  final String? localPath;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;

  const LessonWithProgress({
    required this.lesson,
    this.progress,
    this.localPath,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0,
  });
}

final lessonsProvider = FutureProvider<List<LessonWithProgress>>((ref) async {
  // لا نضع ref.watch(downloadStatusProvider) هنا لأنه يُسبب إعادة بناء
  // القائمة الكاملة (مع فقدان موضع التمرير) عند كل تغيير في حالة التحميل.
  // DownloadButton يتابع downloadStatusProvider مباشرة بدون وسيط.

  final lessons = await ArchiveService.instance.loadLessons();
  final downloads = await DatabaseHelper.instance.getAllDownloads();
  final allProgress = await DatabaseHelper.instance.getAllProgress();
  final progressMap = {for (final p in allProgress) p.lessonId: p};

  final downloadNotifier = ref.read(downloadStatusProvider.notifier);
  if (ref.read(downloadStatusProvider).isEmpty) {
    await downloadNotifier.loadInitialStatuses(lessons.map((l) => l.id).toList());
  }

  final statuses = ref.read(downloadStatusProvider);

  return lessons.map((lesson) {
    final status = statuses[lesson.id] ?? DownloadStatus.notDownloaded;
    final localPath = downloads[lesson.id];

    return LessonWithProgress(
      lesson: lesson,
      progress: progressMap[lesson.id],
      localPath: localPath,
      isDownloaded: status == DownloadStatus.downloaded,
      isDownloading: status == DownloadStatus.downloading,
      downloadProgress: ref.read(downloadProgressProvider(lesson.id)),
    );
  }).toList();
});

final lessonByIdProvider =
    Provider.family<LessonWithProgress?, int>((ref, lessonId) {
  final lessonsAsync = ref.watch(lessonsProvider);
  return lessonsAsync.whenOrNull(
    data: (lessons) {
      try {
        return lessons.firstWhere((l) => l.lesson.id == lessonId);
      } catch (_) {
        return null;
      }
    },
  );
});
