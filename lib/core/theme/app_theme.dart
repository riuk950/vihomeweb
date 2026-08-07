import 'package:flutter/material.dart';

const Color _backgroundColor = Color(0xFFFAFAFA);
const Color _fillColor = Color(0xFFEAEAF0);
const Color _primaryColor = Color(0xFF0E4E82);

// Azure Horizon (light) — sistema de diseño del panel de administración.
const Color azurePrimary = Color(0xFF003760);
const Color azureOnPrimary = Color(0xFFFFFFFF);
const Color azurePrimaryContainer = Color(0xFF0E4E82);
const Color azureOnPrimaryContainer = Color(0xFF8EC0FB);
const Color azureSecondary = Color(0xFF535F70);
const Color azureOnSecondary = Color(0xFFFFFFFF);
const Color azureSecondaryContainer = Color(0xFFD7E3F8);
const Color azureOnSecondaryContainer = Color(0xFF596576);
const Color azureTertiary = Color(0xFF6E5D16);
const Color azureOnTertiary = Color(0xFFFFFFFF);
const Color azureTertiaryContainer = Color(0xFFBFA45C);
const Color azureOnTertiaryContainer = Color(0xFF4C3E00);
const Color azureError = Color(0xFFBA1A1A);
const Color azureOnError = Color(0xFFFFFFFF);
const Color azureErrorContainer = Color(0xFFFFDAD6);
const Color azureOnErrorContainer = Color(0xFF93000A);
const Color azureBackground = Color(0xFFFAF9FD);
const Color azureOnSurface = Color(0xFF1A1C1F);
const Color azureSurfaceLow = Color(0xFFF4F3F7);
const Color azureSurfaceContainer = Color(0xFFEEEDF1);
const Color azureSurfaceHigh = Color(0xFFE9E7EC);
const Color azureSurfaceHighest = Color(0xFFE3E2E6);
const Color azureSurfaceVariant = Color(0xFFE3E2E6);
const Color azureOnSurfaceVariant = Color(0xFF42474F);
const Color azureOutline = Color(0xFF727780);
const Color azureOutlineVariant = Color(0xFFC2C7D1);

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

  // Azure Horizon — panel de administración (Corporate Modernism, M3).
  static ThemeData get azureLight {
    const scheme = ColorScheme.light(
      primary: azurePrimary,
      onPrimary: azureOnPrimary,
      primaryContainer: azurePrimaryContainer,
      onPrimaryContainer: azureOnPrimaryContainer,
      secondary: azureSecondary,
      onSecondary: azureOnSecondary,
      secondaryContainer: azureSecondaryContainer,
      onSecondaryContainer: azureOnSecondaryContainer,
      tertiary: azureTertiary,
      onTertiary: azureOnTertiary,
      tertiaryContainer: azureTertiaryContainer,
      onTertiaryContainer: azureOnTertiaryContainer,
      error: azureError,
      onError: azureOnError,
      errorContainer: azureErrorContainer,
      onErrorContainer: azureOnErrorContainer,
      surface: azureBackground,
      onSurface: azureOnSurface,
      surfaceContainerHighest: azureSurfaceHighest,
      onSurfaceVariant: azureOnSurfaceVariant,
      outline: azureOutline,
      outlineVariant: azureOutlineVariant,
      surfaceTint: Color(0xFF2A6196),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: azureBackground,
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: azureBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: azureOutlineVariant),
        ),
      ),
      dividerTheme: const DividerThemeData(color: azureOutlineVariant),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: azureSurfaceLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: azureOutlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: azurePrimary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: azureOnSurfaceVariant,
          side: const BorderSide(color: azureOutline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
