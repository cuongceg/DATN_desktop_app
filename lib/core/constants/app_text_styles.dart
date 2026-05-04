import 'package:flutter/material.dart';

class AppTextStyles {
  // Lexend - Headlines & Display
  static const String headlineFont = 'Lexend';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: headlineFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    letterSpacing: -0.72, // -0.02em
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: headlineFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  // Inter - Body & Labels
  static const String bodyFont = 'Inter';

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static const TextStyle labelCaps = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.6, // 0.05em
  );

  static const TextStyle tableHeader = TextStyle(
    fontFamily: bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13,
  );
}
