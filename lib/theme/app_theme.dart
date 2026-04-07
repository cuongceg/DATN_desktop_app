import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2B579A),
      onPrimary: Colors.white,
      secondary: Color(0xFF0078D4),
      onSecondary: Colors.white,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF1C1D21),
      outline: Color(0xFFC2C8D1),
      tertiary: Color(0xFF0F766E),
      onTertiary: Colors.white,
      surfaceContainerHighest: Color(0xFFE8ECF3),
      onSurfaceVariant: Color(0xFF454C57),
      inverseSurface: Color(0xFF2C313A),
      onInverseSurface: Color(0xFFF2F4F8),
      inversePrimary: Color(0xFFA5C8FF),
      shadow: Color(0x33000000),
      scrim: Color(0x66000000),
      surfaceTint: Color(0xFF2B579A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFA5C8FF),
      onPrimary: Color(0xFF003062),
      secondary: Color(0xFF70B8FF),
      onSecondary: Color(0xFF002D4F),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: Color(0xFF11131A),
      onSurface: Color(0xFFE7EAF0),
      outline: Color(0xFF8992A0),
      tertiary: Color(0xFF6ED7CC),
      onTertiary: Color(0xFF003732),
      surfaceContainerHighest: Color(0xFF252A34),
      onSurfaceVariant: Color(0xFFC5CBD5),
      inverseSurface: Color(0xFFE7EAF0),
      onInverseSurface: Color(0xFF2A2E36),
      inversePrimary: Color(0xFF2B579A),
      shadow: Color(0x99000000),
      scrim: Color(0x66000000),
      surfaceTint: Color(0xFFA5C8FF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF171A22),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
