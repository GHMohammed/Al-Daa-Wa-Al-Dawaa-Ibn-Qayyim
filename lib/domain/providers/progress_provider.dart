import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final overallProgressProvider = Provider<double>((ref) {
  final lessonsAsync = ref.watch(lessonsProvider);
  return lessonsAsync.when(
    data: (lessons) {
      if (lessons.isEmpty) return 0;
      final completed = lessons.where((l) {
        final p = l.progress;
        if (p == null) return false;
        return p.completed ||
            AppConstants.isLessonCompleted(p.position, p.totalDuration);
      }).length;
      return completed / AppConstants.totalLessons;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final lessonProgressProvider = Provider.family<double, int>((ref, lessonId) {
  final lesson = ref.watch(lessonByIdProvider(lessonId));
  if (lesson?.progress == null) return 0;
  return lesson!.progress!.percentage;
});

final completedCountProvider = Provider<int>((ref) {
  final lessonsAsync = ref.watch(lessonsProvider);
  return lessonsAsync.when(
    data: (lessons) => lessons.where((l) {
      final p = l.progress;
      if (p == null) return false;
      return p.completed ||
          AppConstants.isLessonCompleted(p.position, p.totalDuration);
    }).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final totalHoursProvider = FutureProvider<double>((ref) async {
  return DatabaseHelper.instance.getTotalListeningHours();
});

final downloadedCountProvider = Provider<int>((ref) {
  final lessonsAsync = ref.watch(lessonsProvider);
  return lessonsAsync.when(
    data: (lessons) => lessons.where((l) => l.isDownloaded).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final recentProgressProvider = FutureProvider((ref) async {
  return DatabaseHelper.instance.getAllProgress();
});
