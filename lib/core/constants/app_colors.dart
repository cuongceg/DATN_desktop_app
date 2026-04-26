import 'package:flutter/material.dart';

class AppColors {
  // Core Palette
  static const Color primary = Color(0xFF0040E0);
  static const Color primaryContainer = Color(0xFF2E5BFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF731BE5);
  static const Color secondaryContainer = Color(0xFF8D42FF);
  static const Color onSecondary = Color(0xFFFFFFFF);

  static const Color tertiary = Color(0xFF005E67);
  static const Color tertiaryContainer = Color(0xFF007984);
  static const Color onTertiary = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFFF7F9FB);
  static const Color surfaceContainer = Color(0xFFECEEF0);

  static const Color outline = Color(0xFF747688);
  static const Color outlineVariant = Color(0xFFC4C5D9);

  static const Color white = Color(0xFFFFFFFF);

  // Glassmorphism Strategy
  static const Color glassWhite = Color(0x66FFFFFF); // rgba(255, 255, 255, 0.4)
  static const Color glassWhiteHigh = Color(
    0xB3FFFFFF,
  ); // rgba(255, 255, 255, 0.7)
  static const Color glassWhiteHover = Color(
    0x33FFFFFF,
  ); // rgba(255, 255, 255, 0.2)

  static const Color luminousBorder = Color(0xCCFFFFFF); // high-opacity white

  // Semantic Colors
  static const Color onSurface = Color(0xFF191C1E);
  static const Color onSurfaceVariant = Color(0xFF434656);
  static const Color error = Color(0xFFBA1A1A);
}
