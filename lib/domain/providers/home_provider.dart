import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/data/models/progress_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/download_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/lessons_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/player_provider.dart';
import 'package:al_daa_wal_dawaa/domain/providers/progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LessonFilter {
  all('الكل'),
  inProgress('قيد الاستماع'),
  completed('المكتملة'),
  downloaded('المحفوظة');

  const LessonFilter(this.label);
  final String label;
}

final lessonFilterProvider =
    StateProvider<LessonFilter>((ref) => LessonFilter.all);

/// الدروس بعد تطبيق التصفية المختارة في الرئيسية
final filteredLessonsProvider = Provider<AsyncValue<List<LessonModel>>>((ref) {
  final filter = ref.watch(lessonFilterProvider);
  final progress = ref.watch(progressMapProvider);
  final downloads = ref.watch(downloadStatusProvider);

  return ref.watch(lessonsProvider).whenData((items) {
    final lessons = items.map((i) => i.lesson);
    bool done(LessonModel l) {
      final p = progress[l.id];
      return p != null && isProgressCompleted(p);
    }

    return switch (filter) {
      LessonFilter.all => lessons.toList(),
      LessonFilter.completed => lessons.where(done).toList(),
      LessonFilter.inProgress => lessons
          .where((l) => !done(l) && (progress[l.id]?.position ?? 0) > 0)
          .toList(),
      LessonFilter.downloaded => lessons
          .where((l) => downloads[l.id] == DownloadStatus.downloaded)
          .toList(),
    };
  });
});

class ContinueItem {
  const ContinueItem({required this.lesson, this.progress});

  final LessonModel lesson;
  final ProgressModel? progress;

  bool get isFresh => (progress?.position ?? 0) == 0;
}

/// الدرس المعروض في بطاقة «أكمل الاستماع»:
/// الدرس المحمّل في المشغّل، وإلا آخر درس غير مكتمل استُمع إليه،
/// وإلا أول درس لم يكتمل. null إذا اكتمل الكتاب كله.
final continueLessonProvider = Provider<ContinueItem?>((ref) {
  final lessons =
      ref.watch(lessonsProvider).valueOrNull?.map((i) => i.lesson).toList();
  if (lessons == null || lessons.isEmpty) return null;

  final progress = ref.watch(progressMapProvider);
  final current = ref.watch(playerProvider.select((s) => s.currentLesson));

  LessonModel? byId(int id) {
    for (final l in lessons) {
      if (l.id == id) return l;
    }
    return null;
  }

  LessonModel? pick = current;
  if (pick == null) {
    final recent = progress.values
        .where((p) => !isProgressCompleted(p) && p.position > 0)
        .toList()
      ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
    if (recent.isNotEmpty) pick = byId(recent.first.lessonId);
  }
  pick ??= lessons.cast<LessonModel?>().firstWhere(
    (l) {
      final p = progress[l!.id];
      return p == null || !isProgressCompleted(p);
    },
    orElse: () => null,
  );

  if (pick == null) return null;
  return ContinueItem(lesson: pick, progress: progress[pick.id]);
});
