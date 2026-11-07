import 'package:al_daa_wal_dawaa/data/local/database_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// مفتاح اليوم في السجل: YYYY-MM-DD بالتوقيت المحلي
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// آخر [n] أيام تنتهي باليوم (الأقدم أولاً) مع ثواني الاستماع لكل يوم
List<({DateTime day, int seconds})> lastDays(
  Map<String, int> log,
  DateTime today, {
  int n = 7,
}) {
  final base = DateTime(today.year, today.month, today.day);
  return [
    for (var i = n - 1; i >= 0; i--)
      () {
        final d = base.subtract(Duration(days: i));
        return (day: d, seconds: log[dayKey(d)] ?? 0);
      }(),
  ];
}

/// الأيام المتتالية التي استُمع فيها دقيقة على الأقل.
/// اليوم الحالي لا يكسر السلسلة إن لم يُستمع فيه بعد (تبدأ من الأمس).
int listeningStreak(Map<String, int> log, DateTime today,
    {int minSeconds = 60}) {
  var d = DateTime(today.year, today.month, today.day);
  if ((log[dayKey(d)] ?? 0) < minSeconds) {
    d = d.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while ((log[dayKey(d)] ?? 0) >= minSeconds) {
    streak++;
    d = d.subtract(const Duration(days: 1));
  }
  return streak;
}

/// سجل الاستماع اليومي (يوم → ثوانٍ)، يضيف إليه المشغّل أثناء التشغيل
final listeningLogProvider =
    StateNotifierProvider<ListeningLogNotifier, Map<String, int>>(
  (ref) => ListeningLogNotifier(),
);

class ListeningLogNotifier extends StateNotifier<Map<String, int>> {
  ListeningLogNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final log = await DatabaseHelper.instance.getListeningLog();
    if (!mounted) return;
    // ما أضيف أثناء التحميل يُجمع مع المحفوظ
    state = {
      ...log,
      for (final e in state.entries) e.key: (log[e.key] ?? 0) + e.value,
    };
  }

  Future<void> add(int seconds, {DateTime? at}) async {
    if (seconds <= 0) return;
    final key = dayKey(at ?? DateTime.now());
    state = {...state, key: (state[key] ?? 0) + seconds};
    await DatabaseHelper.instance.addListening(key, seconds);
  }
}
