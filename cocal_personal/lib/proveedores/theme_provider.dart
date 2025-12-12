// lib/proveedores/theme_provider.dart (Create this file)
import 'package:flutter/material.dart';
import '../estilos/app_theme.dart'; // Estilos

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = const Color(0xFF1B753F);

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  final List<Color> availableColors = [
    const Color(0xFF1B753F),
    const Color(0xFF69F0AE),
    const Color(0xFFFF5252),
    const Color(0xFFD50000),
    const Color(0xFFFF4081),
    const Color(0xFFE040FB),
    const Color(0xFFAA00FF),
    const Color(0xFF651FFF),
    const Color(0xFF3D5AFE),
    const Color(0xFF2979FF),
    const Color(0xFF00B0FF),
    const Color(0xFF00E5FF),
    const Color(0xFF1DE9B6),
    const Color(0xFF76FF03),
    const Color(0xFFC6FF00),
    const Color(0xFFFFEA00),
    const Color(0xFFFFC400),
    const Color(0xFFFF9100),
    const Color(0xFFFF3D00),
  ];

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return AppTheme.create(
      accentColor: _accentColor,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
    );
  }

  ThemeData get darkTheme {
    return AppTheme.create(
      accentColor: _accentColor,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
    );
  }
}
