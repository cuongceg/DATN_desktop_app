import 'package:flutter/material.dart';

class GlassTheme {
  // --- Dark theme ---
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface    = Color(0x1AFFFFFF); // white 10%
  static const Color darkBorder     = Color(0x33FFFFFF); // white 20%
  static const Color darkText       = Color(0xFFFFFFFF);
  static const Color darkSubText    = Color(0x99FFFFFF); // white 60%
  static const Color accent         = Color(0xFF6C63FF); // purple accent

  // --- Light theme ---
  static const Color lightBackground = Color(0xFFF0F4FF);
  static const Color lightSurface    = Color(0x99FFFFFF); // white 60%
  static const Color lightBorder     = Color(0x33000000); // black 20%
  static const Color lightText       = Color(0xFF1A1A2E);
  static const Color lightSubText    = Color(0x991A1A2E); // dark 60%

  // --- Blur ---
  static const double blurStrength = 12.0;
  static const double cardRadius   = 16.0;
  static const double panelRadius  = 20.0;
}
