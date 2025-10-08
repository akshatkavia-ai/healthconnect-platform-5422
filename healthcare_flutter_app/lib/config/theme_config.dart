import 'package:flutter/material.dart';

/// PUBLIC_INTERFACE
class ThemeConfig {
  /// Ocean Professional color palette and theme
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFFF59E0B);
  static const Color success = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF111827);

  /// PUBLIC_INTERFACE
  /// Returns the application's ThemeData using Material 3 and Ocean Professional colors.
  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
      // background removed (deprecated in Flutter 3.18+); use surface/scaffoldBackgroundColor instead
      error: error,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: text,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 1.5,
        shadowColor: Colors.black.withAlpha(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: text),
        hintStyle: TextStyle(color: text.withAlpha(120)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withAlpha(30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withAlpha(40)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
        ),
        bodyMedium: TextStyle(color: text),
      ),
    );
  }
}
