import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF242424);
  static const Color card = Color(0xFF2C2C2C);
  static const Color orange = Color(0xFFFF9800);
  static const Color orangeLight = Color(0xFFFFB74D);
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFF44336);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyDark = Color(0xFF616161);
  static const Color bottomBar = Color(0xFF1E1E1E);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.orange,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.orange,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.white),
        bodyMedium: TextStyle(color: AppColors.grey),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bottomBar,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.grey,
      ),
    );
  }
}