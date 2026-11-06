/// المسافات على شبكة 4 — استخدمها بدل الأرقام المتفرقة في الواجهات
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// أنصاف أقطار الزوايا
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;
}

abstract final class AppSizes {
  /// أصغر مساحة لمس مريحة (إرشادات Material وإمكانية الوصول)
  static const double minTapTarget = 48;
}
