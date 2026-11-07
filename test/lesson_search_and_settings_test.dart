import 'package:al_daa_wal_dawaa/data/models/lesson_model.dart';
import 'package:al_daa_wal_dawaa/domain/providers/settings_provider.dart';
import 'package:al_daa_wal_dawaa/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LessonModel _lesson(int id, String title) =>
    LessonModel(id: id, title: title, duration: 60, fileUrl: '');

void main() {
  group('searchLessons', () {
    final lessons = [
      _lesson(1, 'المقدمة'),
      _lesson(2, 'من قوله: ومن تأثير معاصي الله في الأرض'),
      _lesson(12, 'فصل في التوبة وشروطها'),
    ];

    test('matches the lesson number exactly', () {
      expect(searchLessons(lessons, '12').map((l) => l.id), [12]);
      expect(searchLessons(lessons, '3'), isEmpty);
    });

    test('ignores hamza and ta marbuta differences', () {
      expect(searchLessons(lessons, 'تاثير').map((l) => l.id), [2]);
      expect(searchLessons(lessons, 'التوبه').map((l) => l.id), [12]);
    });

    test('requires every word', () {
      expect(searchLessons(lessons, 'التوبة شروطها').map((l) => l.id), [12]);
      expect(searchLessons(lessons, 'التوبة الأرض'), isEmpty);
      expect(searchLessons(lessons, '  '), isEmpty);
    });
  });

  test('app settings default, persist and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        );

    final first = make();
    expect(first.read(appSettingsProvider).themeMode, ThemeMode.system);
    expect(first.read(appSettingsProvider).autoplayNext, isTrue);
    await first.read(appSettingsProvider.notifier).setThemeMode(ThemeMode.dark);
    await first.read(appSettingsProvider.notifier).setAutoplayNext(false);
    first.dispose();

    final second = make();
    expect(second.read(appSettingsProvider).themeMode, ThemeMode.dark);
    expect(second.read(appSettingsProvider).autoplayNext, isFalse);
    second.dispose();
  });
}
