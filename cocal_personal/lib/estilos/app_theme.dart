import 'package:flutter/material.dart';

/// Colores de la paleta de colroes que definimos nosotros jiji
class AppColors {
  // principal
  static const Color primary = Color(0xFF1B753F);
  // resaltos / call-to-action
  static const Color accent = Color(0xFF36A05B);
  // fondo claro
  static const Color background = Color(0xFFF7F7F7);
  // hover / estados sutiles
  static const Color hover = Color(0xFFABBCB0);

  // textos
  static const Color onPrimary = Colors.white;      // texto sobre botones/appbar
  static const Color bodyText = Colors.black87;     // texto normal sobre fondo claro
}

///Tema de la app
class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: Colors.white,
      background: AppColors.background,
      onPrimary: AppColors.onPrimary,
      onSurface: AppColors.bodyText,
      onBackground: AppColors.bodyText,
      outline: AppColors.hover,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // Botones elevados (primarios)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.hover,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Botones de texto (secundarios / links)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hover),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hover),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),

      // Snackbars
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: TextStyle(color: AppColors.onPrimary),
        behavior: SnackBarBehavior.floating,
      ),

      // Loaders
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.accent),

      // Tipografía base
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
        bodyMedium: TextStyle(color: AppColors.bodyText),
      ),
    );
  }
}
