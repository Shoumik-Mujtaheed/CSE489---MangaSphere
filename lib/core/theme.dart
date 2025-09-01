import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color appBackground = Color(0xFF1A1A1A);
  static const Color iconColor = Color(0xFF750000);
  static const Color widgetBorder = Color(0xFF300000);

  static ThemeData darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: appBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: iconColor,
        brightness: Brightness.dark,
        primary: iconColor,
        secondary: iconColor,
        background: appBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBackground,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF111111),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: widgetBorder, width: 1.0),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      iconTheme: const IconThemeData(color: iconColor),
      dividerColor: widgetBorder,
    );

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0E0E0E),
        hintStyle: const TextStyle(color: Colors.white70),
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: widgetBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: iconColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: widgetBorder, width: 1.0),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: widgetBorder, width: 1.0),
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Colors.white),
      ),
    );
  }
}
