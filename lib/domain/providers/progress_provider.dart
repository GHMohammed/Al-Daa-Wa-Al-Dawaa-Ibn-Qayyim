import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/download_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// تقدم كل الدروس (lessonId → التقدم) — مصدر حيّ يحدّثه المشغّل عند كل حفظ،
/// بدلاً من لقطة lessonsProvider التي لا تتغير أثناء الاستماع
final progressMapProvider =
    StateNotifierProvider<ProgressNotifier, Map<int, ProgressModel>>(
  (ref) => ProgressNotifier(),
);

class ProgressNotifier extends StateNotifier<Map<int, ProgressModel>> {
  ProgressNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getAllProgress();
    if (!mounted) return;
    // ما حُفظ أثناء التحميل أحدث مما في القاعدة
    state = {for (final p in all) p.lessonId: p, ...state};
  }

  void update(ProgressModel progress) {
    state = {...state, progress.lessonId: progress};
  }
}

bool isProgressCompleted(ProgressModel p) =>
    p.completed || AppConstants.isLessonCompleted(p.position, p.totalDuration);

final completedCountProvider = Provider<int>((ref) {
  return ref
      .watch(progressMapProvider)
      .values
      .where(isProgressCompleted)
      .length;
});

final overallProgressProvider = Provider<double>((ref) {
  return ref.watch(completedCountProvider) / AppConstants.totalLessons;
});

/// تقريبي: مجموع آخر موضع وصل إليه المستمع في كل درس
final totalHoursProvider = Provider<double>((ref) {
  final totalSeconds = ref
      .watch(progressMapProvider)
      .values
      .fold<int>(0, (sum, p) => sum + p.position);
  return totalSeconds / 3600.0;
});

final downloadedCountProvider = Provider<int>((ref) {
  return ref
      .watch(downloadStatusProvider)
      .values
      .where((s) => s == DownloadStatus.downloaded)
      .length;
});

/// الدروس مرتبة من الأحدث استماعاً
final recentProgressProvider = Provider<List<ProgressModel>>((ref) {
  return ref.watch(progressMapProvider).values.toList()
    ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
});
