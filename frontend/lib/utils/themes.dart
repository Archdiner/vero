import 'package:flutter/material.dart';

/// A class that defines the color schemes for the Roomio app
class AppColors {
  // Primary blue tones (branded)
  static const Color primaryBlue = Color(0xFF4A90E2); // Sky blue
  static const Color primaryLightBlue = Color(0xFFB3D4FC); // Accent/light blue
  static const Color primaryDarkBlue = Color(0xFF2C3E50); // Deep indigo/blue-gray

  // Accent colors (optional, for success/warning/feedback)
  static const Color success = Color(0xFF2ECC71); // Soft green
  static const Color error = Color(0xFFFF6B6B); // Coral/red
  static const Color warning = Color(0xFFFFB74D); // Orange
  static const Color info = Color(0xFF81D4FA); // Light blue

  // Neutral backgrounds
  static const Color background = Color(0xFF121212); // App background (black-ish)
  static const Color surface = Color(0xFF1E1E1E);     // Containers/surfaces
  static const Color cardBackground = Color(0xFF2A2A2A); // Cards

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5); // Muted gray-blue
  static const Color textDisabled = Colors.white38;

  // Other UI
  static const Color divider = Color(0xFF424242);
  static const Color inputBackground = Color(0xFF2F2F2F);
  static const Color iconColor = Color(0xFFB0BEC5); // Matches textSecondary
}

/// Primary theme data for the app
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primaryBlue,
      primaryColorLight: AppColors.primaryLightBlue,
      primaryColorDark: AppColors.primaryDarkBlue,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryLightBlue,
        background: Colors.white,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.black87,
        onSurface: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[200],
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBlue,
      primaryColorLight: AppColors.primaryLightBlue,
      primaryColorDark: AppColors.primaryDarkBlue,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryLightBlue,
        background: AppColors.background,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppColors.inputBackground,
        filled: true,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textDisabled),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textPrimary),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.iconColor,
      ),
    );
  }
}


// Extension methods for easier theme access in widgets
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  Color get primaryColor => colorScheme.primary;
  Color get primaryLightColor => AppColors.primaryLightBlue;
  Color get primaryDarkColor => AppColors.primaryDarkBlue;
  
  Color get textPrimaryColor => AppColors.textPrimary;
  Color get textSecondaryColor => AppColors.textSecondary;
}
