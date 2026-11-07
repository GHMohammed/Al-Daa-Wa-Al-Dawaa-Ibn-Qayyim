import 'package:al_daa_wal_dawaa/domain/providers/listening_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 5, 22, 30);

  test('dayKey pads month and day', () {
    expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
  });

  test('lastDays returns oldest first, ending today, across a month edge', () {
    final days = lastDays({'2026-03-05': 120, '2026-02-28': 60}, today);
    expect(days, hasLength(7));
    expect(dayKey(days.first.day), '2026-02-27');
    expect(dayKey(days.last.day), '2026-03-05');
    expect(days.last.seconds, 120);
    expect(days[1].seconds, 60);
    expect(days[2].seconds, 0);
  });

  group('listeningStreak', () {
    test('counts consecutive days including today', () {
      final log = {'2026-03-05': 90, '2026-03-04': 600, '2026-03-03': 61};
      expect(listeningStreak(log, today), 3);
    });

    test('today without listening does not break the streak', () {
      final log = {'2026-03-04': 600, '2026-03-03': 300};
      expect(listeningStreak(log, today), 2);
    });

    test('a gap or a too-short day ends it', () {
      final log = {
        '2026-03-05': 300,
        '2026-03-04': 30, // أقل من دقيقة
        '2026-03-03': 300,
      };
      expect(listeningStreak(log, today), 1);
      expect(listeningStreak({}, today), 0);
    });
  });
}
