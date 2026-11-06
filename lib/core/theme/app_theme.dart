import 'package:al_daa_wal_dawaa/core/theme/app_colors.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_spacing.dart';
import 'package:al_daa_wal_dawaa/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// الثيم الفاتح والداكن — مبني بالكامل من رموز التصميم (app_colors / app_typography / app_spacing)
abstract final class AppTheme {
  static ThemeData get lightTheme => _build(
        brightness: Brightness.light,
        tokens: AppColorTokens.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.green700,
          primary: AppPalette.green700,
          secondary: AppPalette.gold500,
          surface: AppPalette.white,
          onSurface: AppPalette.ink,
          error: AppPalette.red600,
          brightness: Brightness.light,
        ),
        scaffold: AppPalette.paper,
        card: AppPalette.white,
        divider: AppPalette.line,
        ink: AppPalette.ink,
      );

  static ThemeData get darkTheme => _build(
        brightness: Brightness.dark,
        tokens: AppColorTokens.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.green400,
          primary: AppPalette.green400,
          secondary: AppPalette.gold400,
          surface: AppPalette.nightCard,
          onSurface: AppPalette.moon,
          error: AppPalette.red300,
          brightness: Brightness.dark,
        ),
        scaffold: AppPalette.night,
        card: AppPalette.nightCard,
        divider: AppPalette.nightLine,
        ink: AppPalette.moon,
      );

  static ThemeData _build({
    required Brightness brightness,
    required AppColorTokens tokens,
    required ColorScheme colorScheme,
    required Color scaffold,
    required Color card,
    required Color divider,
    required Color ink,
  }) {
    final isDark = brightness == Brightness.dark;
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
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: divider),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.brand,
        linearTrackColor: tokens.track,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: tokens.brand,
        inactiveTrackColor: tokens.track,
        thumbColor: tokens.brand,
        overlayColor: tokens.brand.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.accentContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? AppTypography.medium
                : AppTypography.regular,
            color: states.contains(WidgetState.selected)
                ? tokens.onAccentContainer
                : tokens.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? tokens.onAccentContainer
                : tokens.textMuted,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.brand,
        foregroundColor: Colors.white,
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          fontFamily: AppTypography.fontFamily,
          color: ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
