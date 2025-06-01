import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF1A3E6E);
  static const Color secondaryColor = Color(0xFF3D6AA4);
  static const Color accentColor = Color(0xFF01569A);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textColor = Colors.white;
  static const Color buttonColor = Color(0xFF1A3E6E);
}

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primaryColor,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      background: AppColors.backgroundColor,
    ),
    scaffoldBackgroundColor: AppColors.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.textColor,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      ),
    ),
  );
}
