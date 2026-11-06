import 'package:flutter/material.dart';

/// المقياس الطباعي بخط ثمانية — الألوان تأتي من الثيم، هنا الأحجام والأوزان فقط.
/// ارتفاع السطر أعلى من الافتراضي لأن الحروف العربية أطول صعوداً ونزولاً.
abstract final class AppTypography {
  static const String fontFamily = 'Thmanyah Sans';

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight black = FontWeight.w900;

  static const TextTheme textTheme = TextTheme(
    displaySmall: TextStyle(fontSize: 34, fontWeight: black, height: 1.3),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: bold, height: 1.35),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: bold, height: 1.4),
    titleLarge: TextStyle(fontSize: 20, fontWeight: bold, height: 1.4),
    titleMedium: TextStyle(fontSize: 16, fontWeight: medium, height: 1.5),
    titleSmall: TextStyle(fontSize: 14, fontWeight: medium, height: 1.5),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: regular, height: 1.7),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: regular, height: 1.6),
    bodySmall: TextStyle(fontSize: 12, fontWeight: regular, height: 1.5),
    labelLarge: TextStyle(fontSize: 14, fontWeight: medium, height: 1.4),
    labelMedium: TextStyle(fontSize: 12, fontWeight: medium, height: 1.4),
    labelSmall: TextStyle(fontSize: 11, fontWeight: medium, height: 1.4),
  );
}
