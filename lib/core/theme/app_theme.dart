import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.primary,
    primaryColor: AppColors.primary,

    inputDecorationTheme: InputDecorationTheme(
      filled: true,                       // IMPORTANT : active le fond
      fillColor: AppColors.white,         // fond blanc
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),

      labelStyle: const TextStyle(
        color: AppColors.primary,
      ),

      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.white),
        borderRadius: BorderRadius.circular(12),
      ),

      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.white),
        borderRadius: BorderRadius.circular(12),
      ),

      border: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}
