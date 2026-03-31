import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color glassLight = Color(0x66F5F0E6);
  static const Color primaryLight = Color(0xFF4A4238);
  static const Color accentLight = Color(0xFFD4C9B5);
  static const Color shadowLight = Color(0x08000000);

  // Dark Theme Colors
  static const Color surfaceDark = Color(0xFF000000); // Pitch Black OLED
  static const Color glassDark = Color(
    0x331A1816,
  ); // Çok koyu transparan sepya/gri
  static const Color primaryDark = Color(0xFFF5F5F7); // Accent White
  static const Color accentDark = Color(0xFF8C7F6B); // Koyu altın
  static const Color shadowDark = Color(0x1A000000);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surfaceLight,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: accentLight,
        surface: surfaceLight,
        onSurface: primaryLight,
      ),
      iconTheme: const IconThemeData(color: primaryLight),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: primaryLight,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: primaryLight,
        ),
        labelMedium: TextStyle(fontWeight: FontWeight.w300, color: Colors.grey),
        bodyMedium: TextStyle(color: primaryLight),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceLight,
        modalBackgroundColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: accentDark,
        surface: surfaceDark,
        onSurface: primaryDark,
      ),
      iconTheme: const IconThemeData(color: primaryDark),
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: primaryDark,
        ),
        displayMedium: const TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: primaryDark,
        ),
        labelMedium: TextStyle(
          fontWeight: FontWeight.w300,
          color: Colors.grey.shade400,
        ),
        bodyMedium: const TextStyle(color: primaryDark),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        modalBackgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }
}
