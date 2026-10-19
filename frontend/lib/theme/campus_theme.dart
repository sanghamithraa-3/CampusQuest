import 'package:flutter/material.dart';

abstract final class CampusColors {
  static const navy = Color(0xFF202447);
  static const indigo = Color(0xFF474A8A);
  static const lavender = Color(0xFFEEEDFA);
  static const lavenderStrong = Color(0xFFD9D7F3);
  static const paper = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF24263B);
  static const muted = Color(0xFF74768B);
  static const line = Color(0xFFE8E7EF);
  static const mint = Color(0xFFE5F3ED);
  static const green = Color(0xFF34745A);
  static const amber = Color(0xFFF6E8C9);
}

abstract final class CampusSpace {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

ThemeData buildCampusTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CampusColors.indigo,
    primary: CampusColors.indigo,
    secondary: CampusColors.green,
    surface: CampusColors.surface,
    error: const Color(0xFFB94C55),
  );
  final textTheme = ThemeData.light().textTheme.apply(
    bodyColor: CampusColors.ink,
    displayColor: CampusColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CampusColors.paper,
    textTheme: textTheme.copyWith(
      headlineLarge: textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: CampusColors.navy,
      ),
      headlineMedium: textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: CampusColors.navy,
      ),
      headlineSmall: textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: CampusColors.navy,
      ),
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: CampusColors.navy,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: CampusColors.navy,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        height: 1.5,
        color: CampusColors.ink,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(
        height: 1.45,
        color: CampusColors.muted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CampusColors.paper,
      foregroundColor: CampusColors.navy,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: CampusColors.navy,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: CampusColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: CampusColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CampusColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CampusColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CampusColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CampusColors.indigo, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CampusColors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CampusColors.indigo,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        side: const BorderSide(color: CampusColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerColor: CampusColors.line,
  );
}
