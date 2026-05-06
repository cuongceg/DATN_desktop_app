import "package:flutter/material.dart";
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiaryContainer,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      surfaceTint: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(borderRadius: AppSizes.brMedium),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSizes.brMedium,
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSizes.brMedium,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
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
