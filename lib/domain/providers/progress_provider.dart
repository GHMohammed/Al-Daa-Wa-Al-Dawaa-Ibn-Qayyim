import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';
import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/download_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/listening_stats.dart';
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

/// ساعات الاستماع: من السجل اليومي (وقت حقيقي). السجل بدأ في الإصدار 1.1،
/// فلمن استمع قبله نأخذ الأكبر بينه وبين التقدير القديم (مجموع آخر المواضع)
final totalHoursProvider = Provider<double>((ref) {
  final logged =
      ref.watch(listeningLogProvider).values.fold<int>(0, (a, b) => a + b);
  final estimated = ref
      .watch(progressMapProvider)
      .values
      .fold<int>(0, (sum, p) => sum + p.position);
  return (logged > estimated ? logged : estimated) / 3600.0;
});

/// الثواني الباقية لإتمام الشرح — بالمدد الحقيقية حين تُعرف، والتقديرية لغيرها
final remainingSecondsProvider = Provider<int>((ref) {
  final lessons = ref.watch(lessonsProvider).valueOrNull;
  if (lessons == null) return 0;
  final progress = ref.watch(progressMapProvider);
  var remaining = 0;
  for (final item in lessons) {
    final p = progress[item.lesson.id];
    if (p != null && isProgressCompleted(p)) continue;
    final total = p?.totalDuration ?? item.lesson.duration;
    remaining += (total - (p?.position ?? 0)).clamp(0, total);
  }
  return remaining;
});

/// آخر 7 أيام (الأقدم أولاً) مع ثواني الاستماع
final weekListeningProvider =
    Provider<List<({DateTime day, int seconds})>>((ref) {
  return lastDays(ref.watch(listeningLogProvider), DateTime.now());
});

final listeningStreakProvider = Provider<int>((ref) {
  return listeningStreak(ref.watch(listeningLogProvider), DateTime.now());
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
