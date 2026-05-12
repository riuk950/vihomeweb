import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFFFAFAFA);
const Color _fillColor = Color(0xFFEAEAF0);
const Color _primaryColor = Color(0xFF0E4E82);

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      fontFamily: 'Manrope',
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: _primaryColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: _backgroundColor,
        surfaceTintColor: _backgroundColor,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF16A1F4),
        brightness: Brightness.dark,
      ),
      fontFamily: 'Poppins',
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static void initialize() {
    // TODO: Inicializar tema si es necesario
  }
}
