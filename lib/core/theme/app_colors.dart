import 'package:flutter/material.dart';

/// اللوحة الخام — تغيير الهوية البصرية يكون هنا فقط.
/// لا تُستخدم مباشرة في الواجهات؛ استخدم [AppColorTokens] عبر `context.colors`.
abstract final class AppPalette {
  static const Color green900 = Color(0xFF0F6E56);
  static const Color green600 = Color(0xFF1D9E75);
  static const Color green200 = Color(0xFFB8E6D5);
  static const Color green50 = Color(0xFFE1F5EE);
  static const Color greenDark = Color(0xFF2A4A40);
  static const Color greenDarker = Color(0xFF1C3A31);

  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF5F5F5);
  static const Color neutral100 = Color(0xFFF2F2F7);
  static const Color neutral150 = Color(0xFFEEEEEE);
  static const Color neutral800 = Color(0xFF2A2A2A);
  static const Color neutral900 = Color(0xFF1E1E1E);
  static const Color neutral950 = Color(0xFF121212);

  static const Color red600 = Color(0xFFD32F2F);
  static const Color red300 = Color(0xFFEF9A9A);
  static const Color success600 = Color(0xFF2E7D32);
  static const Color success100 = Color(0xFFC8E6C9);
  static const Color success300 = Color(0xFF81C784);
  static const Color success900 = Color(0xFF1B3A1E);
}

/// ألوان الهوية الثابتة في الوضعين (رأس الصفحات الملوّن، الأزرار الرئيسية)
abstract final class AppColors {
  static const Color primary = AppPalette.green900;
  static const Color secondary = AppPalette.green600;
}

/// ألوان دلالية تتبدّل بين الفاتح والداكن — `context.colors.accentContainer`
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.brand,
    required this.accent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.header,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.onHeaderTrack,
    required this.track,
    required this.textMuted,
    required this.textSubtle,
    required this.success,
    required this.successContainer,
    required this.danger,
    required this.shadow,
  });

  /// اللون الأساسي للهوية (أزرار رئيسية، أيقونات مميزة)
  final Color brand;

  /// لون التمييز (مؤشرات التقدم، الحالة النشطة)
  final Color accent;

  /// خلفية هادئة بلون الهوية (شارات، مربعات الأيقونات)
  final Color accentContainer;
  final Color onAccentContainer;

  /// رأس الصفحة الملوّن والمشغّل المصغّر
  final Color header;
  final Color onHeader;
  final Color onHeaderMuted;
  final Color onHeaderTrack;

  /// مسار أشرطة/دوائر التقدم الفارغ
  final Color track;

  /// نص ثانوي (60%) ونص خافت (45%)
  final Color textMuted;
  final Color textSubtle;

  final Color success;
  final Color successContainer;
  final Color danger;
  final Color shadow;

  static const light = AppColorTokens(
    brand: AppPalette.green900,
    accent: AppPalette.green600,
    accentContainer: AppPalette.green50,
    onAccentContainer: AppPalette.green900,
    header: AppPalette.green900,
    onHeader: AppPalette.neutral0,
    onHeaderMuted: Color(0xB3FFFFFF),
    onHeaderTrack: Color(0x3DFFFFFF),
    track: AppPalette.green200,
    textMuted: Color(0x99000000),
    textSubtle: Color(0x73000000),
    success: AppPalette.success600,
    successContainer: AppPalette.success100,
    danger: AppPalette.red600,
    shadow: Color(0x1A000000),
  );

  static const dark = AppColorTokens(
    brand: AppPalette.green600,
    accent: AppPalette.green600,
    accentContainer: AppPalette.greenDarker,
    onAccentContainer: AppPalette.green200,
    header: AppPalette.green900,
    onHeader: AppPalette.neutral0,
    onHeaderMuted: Color(0xB3FFFFFF),
    onHeaderTrack: Color(0x3DFFFFFF),
    track: AppPalette.greenDark,
    textMuted: Color(0x99FFFFFF),
    textSubtle: Color(0x73FFFFFF),
    success: AppPalette.success300,
    successContainer: AppPalette.success900,
    danger: AppPalette.red300,
    shadow: Color(0x40000000),
  );

  @override
  AppColorTokens copyWith({
    Color? brand,
    Color? accent,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? header,
    Color? onHeader,
    Color? onHeaderMuted,
    Color? onHeaderTrack,
    Color? track,
    Color? textMuted,
    Color? textSubtle,
    Color? success,
    Color? successContainer,
    Color? danger,
    Color? shadow,
  }) {
    return AppColorTokens(
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      header: header ?? this.header,
      onHeader: onHeader ?? this.onHeader,
      onHeaderMuted: onHeaderMuted ?? this.onHeaderMuted,
      onHeaderTrack: onHeaderTrack ?? this.onHeaderTrack,
      track: track ?? this.track,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorTokens lerp(AppColorTokens? other, double t) {
    if (other == null) return this;
    return AppColorTokens(
      brand: Color.lerp(brand, other.brand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer:
          Color.lerp(onAccentContainer, other.onAccentContainer, t)!,
      header: Color.lerp(header, other.header, t)!,
      onHeader: Color.lerp(onHeader, other.onHeader, t)!,
      onHeaderMuted: Color.lerp(onHeaderMuted, other.onHeaderMuted, t)!,
      onHeaderTrack: Color.lerp(onHeaderTrack, other.onHeaderTrack, t)!,
      track: Color.lerp(track, other.track, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppColorTokensContext on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
}
