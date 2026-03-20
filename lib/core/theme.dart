import 'package:flutter/material.dart';

class AppTheme {
  // Light mode colors
  static const Color sage = Color(0xFF7C9E87);
  static const Color sageLight = Color(0xFFA8C4B0);
  static const Color mint = Color(0xFFC8E6C9);
  static const Color moss = Color(0xFF4A6741);
  static const Color cream = Color(0xFFF4F2EB);
  static const Color textDark = Color(0xFF2E4A20);
  static const Color textMid = Color(0xFF5A7A4A);
  static const Color textLight = Color(0xFF8AAA70);

  // Dark mode colors
  static const Color darkBg = Color(0xFF182818);
  static const Color darkCard = Color(0xFF1E301E);
  static const Color darkText = Color(0xFFB0D4A8);
  static const Color darkTextMid = Color(0xFF5A8060);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sage,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: cream,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sage,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
    );
  }
}