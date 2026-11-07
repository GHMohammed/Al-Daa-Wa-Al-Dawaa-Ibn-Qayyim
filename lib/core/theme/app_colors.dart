import 'package:flutter/material.dart';

/// اللوحة الخام — تغيير الهوية البصرية يكون هنا فقط.
/// لا تُستخدم مباشرة في الواجهات؛ استخدم [AppColorTokens] عبر `context.colors`.
abstract final class AppPalette {
  // الأخضر — هوية التطبيق
  static const Color green950 = Color(0xFF0E3D2E);
  static const Color green900 = Color(0xFF104533);
  static const Color green700 = Color(0xFF17694A);
  static const Color green400 = Color(0xFF3CAA7A);
  static const Color green100 = Color(0xFFE6F0EA);
  static const Color green800Ink = Color(0xFF145C40);
  static const Color greenDarkSurface = Color(0xFF17302A);
  static const Color greenMist = Color(0xFFA9C3B6);
  static const Color greenMintInk = Color(0xFF93D1B2);

  // الذهبي — للتمييز (التقدم الجزئي، زر التشغيل في البطاقة، الزخرفة)
  static const Color gold500 = Color(0xFFC6A253);
  static const Color gold400 = Color(0xFFD5B366);
  // ذهبي داكن للنص على الخلفيات الفاتحة (تباين 5:1 مع paper)
  static const Color gold700Ink = Color(0xFF85652A);
  static const Color sand = Color(0xFFB9A57A);
  static const Color sandDark = Color(0xFF5E7A6C);

  // المحايدات بلمسة خضراء
  static const Color paper = Color(0xFFF6F7F4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE3E7E1);
  static const Color ring = Color(0xFFCDD5D0);
  static const Color ink = Color(0xFF13241C);
  static const Color inkSoft = Color(0xFF41524A);
  static const Color inkMute = Color(0xFF5E6D65);

  static const Color night = Color(0xFF0D1310);
  static const Color nightCard = Color(0xFF141C19);
  static const Color nightLine = Color(0xFF1E2925);
  static const Color nightRing = Color(0xFF37453F);
  static const Color moon = Color(0xFFE7EDE9);
  static const Color moonSoft = Color(0xFFC2CDC7);
  static const Color moonMute = Color(0xFF8D9D95);

  static const Color red600 = Color(0xFFC0392B);
  static const Color red300 = Color(0xFFEF9A9A);
}

/// ألوان الهوية الثابتة في الوضعين
abstract final class AppColors {
  static const Color primary = AppPalette.green700;
  static const Color hero = AppPalette.green950;
  static const Color gold = AppPalette.gold500;
}

/// ألوان دلالية تتبدّل بين الفاتح والداكن — `context.colors.gold`
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.brand,
    required this.accent,
    required this.gold,
    required this.onGold,
    required this.goldInk,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.header,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.onHeaderTrack,
    required this.track,
    required this.ringTrack,
    required this.pattern,
    required this.textSecondary,
    required this.textMuted,
    required this.textSubtle,
    required this.success,
    required this.successContainer,
    required this.danger,
    required this.shadow,
  });

  /// الأخضر الأساسي (أزرار التشغيل، الدروس المكتملة، شريط الإنجاز)
  final Color brand;

  /// مؤشرات التقدم العامة
  final Color accent;

  /// الذهبي: التقدم الجزئي في الدرس، زر بطاقة «أكمل الاستماع»، الزخرفة على الأخضر
  final Color gold;
  final Color onGold;

  /// الذهبي للنص والأيقونات الصغيرة على سطح الصفحة (لا على الأخضر العميق)؛
  /// [gold] أفتح من أن يُقرأ نصاً على الخلفية الفاتحة
  final Color goldInk;

  /// خلفية هادئة بلون الهوية (الشارات، أدوات المشغّل، عنصر التنقل النشط)
  final Color accentContainer;
  final Color onAccentContainer;

  /// السطح الأخضر العميق (بطاقة «أكمل الاستماع»، غلاف المشغّل، المشغّل المصغّر)
  final Color header;
  final Color onHeader;
  final Color onHeaderMuted;
  final Color onHeaderTrack;

  /// مسار أشرطة التقدم الفارغ والفواصل
  final Color track;

  /// إطار دوائر الدروس التي لم تبدأ
  final Color ringTrack;

  /// خطوط الزخرفة على خلفية الصفحة
  final Color pattern;

  /// نص ثانوي، ونص خافت، ونص أخفت
  final Color textSecondary;
  final Color textMuted;
  final Color textSubtle;

  final Color success;
  final Color successContainer;
  final Color danger;
  final Color shadow;

  static const light = AppColorTokens(
    brand: AppPalette.green700,
    accent: AppPalette.green700,
    gold: AppPalette.gold500,
    onGold: AppPalette.green950,
    goldInk: AppPalette.gold700Ink,
    accentContainer: AppPalette.green100,
    onAccentContainer: AppPalette.green800Ink,
    header: AppPalette.green950,
    onHeader: AppPalette.white,
    onHeaderMuted: AppPalette.greenMist,
    onHeaderTrack: Color(0x33FFFFFF),
    track: AppPalette.line,
    ringTrack: AppPalette.ring,
    pattern: AppPalette.sand,
    textSecondary: AppPalette.inkSoft,
    textMuted: AppPalette.inkMute,
    textSubtle: AppPalette.inkMute,
    success: AppPalette.green700,
    successContainer: AppPalette.green100,
    danger: AppPalette.red600,
    shadow: Color(0x14000000),
  );

  static const dark = AppColorTokens(
    brand: AppPalette.green400,
    accent: AppPalette.green400,
    gold: AppPalette.gold400,
    onGold: AppPalette.green900,
    goldInk: AppPalette.gold400,
    accentContainer: AppPalette.greenDarkSurface,
    onAccentContainer: AppPalette.greenMintInk,
    header: AppPalette.green900,
    onHeader: AppPalette.white,
    onHeaderMuted: AppPalette.greenMist,
    onHeaderTrack: Color(0x33FFFFFF),
    track: AppPalette.nightLine,
    ringTrack: AppPalette.nightRing,
    pattern: AppPalette.sandDark,
    textSecondary: AppPalette.moonSoft,
    textMuted: AppPalette.moonMute,
    textSubtle: AppPalette.moonMute,
    success: AppPalette.green400,
    successContainer: AppPalette.greenDarkSurface,
    danger: AppPalette.red300,
    shadow: Color(0x40000000),
  );

  @override
  AppColorTokens copyWith({
    Color? brand,
    Color? accent,
    Color? gold,
    Color? onGold,
    Color? goldInk,
    Color? accentContainer,
    Color? onAccentContainer,
    Color? header,
    Color? onHeader,
    Color? onHeaderMuted,
    Color? onHeaderTrack,
    Color? track,
    Color? ringTrack,
    Color? pattern,
    Color? textSecondary,
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
      gold: gold ?? this.gold,
      onGold: onGold ?? this.onGold,
      goldInk: goldInk ?? this.goldInk,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
      header: header ?? this.header,
      onHeader: onHeader ?? this.onHeader,
      onHeaderMuted: onHeaderMuted ?? this.onHeaderMuted,
      onHeaderTrack: onHeaderTrack ?? this.onHeaderTrack,
      track: track ?? this.track,
      ringTrack: ringTrack ?? this.ringTrack,
      pattern: pattern ?? this.pattern,
      textSecondary: textSecondary ?? this.textSecondary,
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
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorTokens(
      brand: l(brand, other.brand),
      accent: l(accent, other.accent),
      gold: l(gold, other.gold),
      onGold: l(onGold, other.onGold),
      goldInk: l(goldInk, other.goldInk),
      accentContainer: l(accentContainer, other.accentContainer),
      onAccentContainer: l(onAccentContainer, other.onAccentContainer),
      header: l(header, other.header),
      onHeader: l(onHeader, other.onHeader),
      onHeaderMuted: l(onHeaderMuted, other.onHeaderMuted),
      onHeaderTrack: l(onHeaderTrack, other.onHeaderTrack),
      track: l(track, other.track),
      ringTrack: l(ringTrack, other.ringTrack),
      pattern: l(pattern, other.pattern),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textSubtle: l(textSubtle, other.textSubtle),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      danger: l(danger, other.danger),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppColorTokensContext on BuildContext {
  AppColorTokens get colors => Theme.of(this).extension<AppColorTokens>()!;
}
