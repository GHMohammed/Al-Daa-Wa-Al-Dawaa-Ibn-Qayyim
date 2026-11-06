import 'package:al_daa_wal_dawaa/core/theme/app_colors.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_spacing.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// الثيم الفاتح والداكن — مبني بالكامل من رموز التصميم (app_colors / app_typography / app_spacing)
abstract final class AppTheme {
  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        tokens: AppColorTokens.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.green900,
          primary: AppPalette.green900,
          secondary: AppPalette.green600,
          surface: AppPalette.neutral50,
          error: AppPalette.red600,
          brightness: Brightness.light,
        ),
        scaffold: AppPalette.neutral100,
        card: AppPalette.neutral0,
        divider: AppPalette.neutral150,
        appBar: AppPalette.green900,
        navBar: AppPalette.neutral0,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        tokens: AppColorTokens.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.green600,
          primary: AppPalette.green600,
          secondary: AppPalette.green600,
          surface: AppPalette.neutral900,
          error: AppPalette.red300,
          brightness: Brightness.dark,
        ),
        scaffold: AppPalette.neutral950,
        card: AppPalette.neutral900,
        divider: AppPalette.neutral800,
        appBar: AppPalette.neutral900,
        navBar: AppPalette.neutral900,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppColorTokens tokens,
    required ColorScheme colorScheme,
    required Color scaffold,
    required Color card,
    required Color divider,
    required Color appBar,
    required Color navBar,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: scaffold,
      dividerColor: divider,
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 1.5,
        shadowColor: tokens.shadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accent,
        linearTrackColor: tokens.track,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: tokens.accent,
        thumbColor: tokens.brand,
        inactiveTrackColor: tokens.track,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: tokens.brand,
        unselectedItemColor: tokens.textSubtle,
        backgroundColor: navBar,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.brand,
        foregroundColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),
    );
  }
}
