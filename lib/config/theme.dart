import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundDark = Color(0xFF0A1628);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color turquoise = Color(0xFF4ECDC4);
  static const Color skyBlue = Color(0xFF45B7D1);
  static const Color sageGreen = Color(0xFF96CEB4);
  static const Color softYellow = Color(0xFFFFEAA7);
  static const Color plum = Color(0xFFDDA0DD);
  static const Color orange = Color(0xFFFF8C42);
  static const Color mint = Color(0xFFA8E6CF);
  static const Color pink = Color(0xFFFFB3BA);
  static const Color seafoam = Color(0xFFB5EAD7);
  static const Color lavender = Color(0xFFC7CEEA);
  static const Color lime = Color(0xFFE2F0CB);

  static const List<Color> tileColors = [
    coral,
    turquoise,
    skyBlue,
    sageGreen,
    softYellow,
    plum,
    orange,
    mint,
    pink,
    seafoam,
    lavender,
    lime,
  ];

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color overlayDark = Color(0xCC000000);
  static const Color starColor = Color(0xFFFFD700);
  static const Color coinColor = Color(0xFFFFD700);

  static ThemeData get themeData => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        primaryColor: coral,
        colorScheme: const ColorScheme.dark(
          primary: coral,
          secondary: turquoise,
          surface: Color(0xFF1A2A44),
        ),
        fontFamily: 'Permanent Marker',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: coral,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Permanent Marker',
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: turquoise, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
