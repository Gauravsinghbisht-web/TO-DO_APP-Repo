import 'package:flutter/material.dart';

abstract final class TaskFlowColors {
  static const primary = Color(0xFF4D41DF);
  static const primaryContainer = Color(0xFF675DF9);
  static const secondary = Color(0xFF4B41E1);
  static const tertiary = Color(0xFF006947);
  static const background = Color(0xFFFCF8FF);
  static const surface = Color(0xFFFFFFFF);
  static const lavenderContainer = Color(0xFFF6F2FF);
  static const mainText = Color(0xFF181445);
  static const secondaryText = Color(0xFF464555);
  static const outline = Color(0xFF777587);
  static const outlineVariant = Color(0xFFC7C4D8);
}

abstract final class TaskFlowTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: TaskFlowColors.primary,
      onPrimary: TaskFlowColors.surface,
      primaryContainer: TaskFlowColors.primaryContainer,
      onPrimaryContainer: TaskFlowColors.surface,
      secondary: TaskFlowColors.secondary,
      onSecondary: TaskFlowColors.surface,
      tertiary: TaskFlowColors.tertiary,
      onTertiary: TaskFlowColors.surface,
      surface: TaskFlowColors.surface,
      onSurface: TaskFlowColors.mainText,
      onSurfaceVariant: TaskFlowColors.secondaryText,
      surfaceContainerLow: TaskFlowColors.lavenderContainer,
      surfaceContainer: Color(0xFFEFEBFF),
      surfaceContainerHigh: Color(0xFFE9E5FF),
      surfaceContainerHighest: Color(0xFFE3DFFF),
      outline: TaskFlowColors.outline,
      outlineVariant: TaskFlowColors.outlineVariant,
      error: Color(0xFFBA1A1A),
      onError: TaskFlowColors.surface,
    );

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    );
    const cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
    const inputBorderRadius = BorderRadius.all(Radius.circular(16));

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TaskFlowColors.background,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 44,
          height: 52 / 44,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.03 * 44,
          color: TaskFlowColors.mainText,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          height: 40 / 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * 32,
          color: TaskFlowColors.mainText,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          height: 28 / 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01 * 22,
          color: TaskFlowColors.mainText,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          height: 24 / 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01 * 18,
          color: TaskFlowColors.mainText,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 22 / 16,
          fontWeight: FontWeight.w500,
          color: TaskFlowColors.mainText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w400,
          color: TaskFlowColors.mainText,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w400,
          color: TaskFlowColors.secondaryText,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.01 * 12,
          color: TaskFlowColors.secondaryText,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 18 / 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.02 * 14,
          color: TaskFlowColors.mainText,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.04 * 12,
          color: TaskFlowColors.secondaryText,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          height: 14 / 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.06 * 10,
          color: TaskFlowColors.secondaryText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: buttonShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: buttonShape,
          side: const BorderSide(color: TaskFlowColors.outlineVariant),
        ),
      ),
      cardTheme: const CardThemeData(
        color: TaskFlowColors.surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TaskFlowColors.lavenderContainer,
        border: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: const BorderSide(color: TaskFlowColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: inputBorderRadius,
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
        ),
      ),
    );
  }
}
