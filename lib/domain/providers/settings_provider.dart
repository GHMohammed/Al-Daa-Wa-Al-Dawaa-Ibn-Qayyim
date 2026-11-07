import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يُعيَّن من main بعد تحميل SharedPreferences، حتى تُطبَّق السمة من أول إطار
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'يجب تهيئة sharedPrefsProvider من main عبر override',
  ),
);

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.autoplayNext = true,
  });

  final ThemeMode themeMode;

  /// تشغيل الدرس التالي تلقائياً عند انتهاء الدرس الحالي
  final bool autoplayNext;

  AppSettings copyWith({ThemeMode? themeMode, bool? autoplayNext}) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        autoplayNext: autoplayNext ?? this.autoplayNext,
      );
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(ref.watch(sharedPrefsProvider)),
);

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._prefs)
      : super(
          AppSettings(
            themeMode:
                ThemeMode.values.asNameMap()[_prefs.getString(_themeKey)] ??
                    ThemeMode.system,
            autoplayNext: _prefs.getBool(_autoplayKey) ?? true,
          ),
        );

  static const _themeKey = 'theme_mode';
  static const _autoplayKey = 'autoplay_next';

  final SharedPreferences _prefs;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> setAutoplayNext(bool value) async {
    state = state.copyWith(autoplayNext: value);
    await _prefs.setBool(_autoplayKey, value);
  }
}
