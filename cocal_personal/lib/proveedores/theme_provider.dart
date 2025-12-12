// lib/proveedores/theme_provider.dart (Create this file)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../estilos/app_theme.dart'; // Estilos

class ThemeProvider with ChangeNotifier {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyFontFamily = 'font_family';

  ThemeMode _themeMode = ThemeMode.light;
  Color _accentColor = const Color(0xFF1B753F);
  String _fontFamily = 'Roboto';

  ThemeProvider() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  String get fontFamily => _fontFamily;

  Color get secondaryColor => _secondaryColors[_accentColor] ?? Colors.teal;

  final Map<Color, Color> _secondaryColors = {
    const Color(0xFF1B753F): const Color(0xFF81C784),
    const Color(0xFF69F0AE): const Color(0xFF2E7D32),
    const Color(0xFFFF5252): const Color(0xFFC62828),
    const Color(0xFFD50000): const Color(0xFFFF8A80),
    const Color(0xFFFF4081): const Color(0xFFAD1457),
    const Color(0xFFE040FB): const Color(0xFF7B1FA2),
    const Color(0xFFAA00FF): const Color(0xFFEA80FC),
    const Color(0xFF651FFF): const Color(0xFFB388FF),
    const Color(0xFF3D5AFE): const Color(0xFF8C9EFF),
    const Color(0xFF2979FF): const Color(0xFF1565C0),
    const Color(0xFF00B0FF): const Color(0xFF0277BD),
    const Color(0xFF00E5FF): const Color(0xFF0097A7),
    const Color(0xFF1DE9B6): const Color(0xFF00695C),
    const Color(0xFF76FF03): const Color(0xFF558B2F),
    const Color(0xFFC6FF00): const Color(0xFF9E9D24),
    const Color(0xFFFFEA00): const Color(0xFFFBC02D),
    const Color(0xFFFFC400): const Color(0xFFFF8F00),
    const Color(0xFFFF9100): const Color(0xFFEF6C00),
    const Color(0xFFFF3D00): const Color(0xFFD84315),
  };

  List<Color> get availableColors => _secondaryColors.keys.toList();

  final List<String> availableFonts = [
    'Roboto',
    'Lato',
    'Montserrat',
    'Space Mono',
    'Delius',
    'Schoolbell',
  ];

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Theme Mode
    final modeIndex = prefs.getInt(_keyThemeMode) ?? 1; // Default to Light (1)
    if (modeIndex == 0)
      _themeMode = ThemeMode.system;
    else if (modeIndex == 1)
      _themeMode = ThemeMode.light;
    else
      _themeMode = ThemeMode.dark;

    // 2. Load Accent Color
    final colorValue = prefs.getInt(_keyAccentColor);
    if (colorValue != null) {
      final loadedColor = Color(colorValue);
      _accentColor = _secondaryColors.keys.firstWhere(
        (k) => k.value == loadedColor.value,
        orElse: () => loadedColor,
      );
    }

    _fontFamily = prefs.getString(_keyFontFamily) ?? 'Roboto';

    notifyListeners();
  }

  // --- SAVING LOGIC ---

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    int index = 1;
    if (mode == ThemeMode.system) index = 0;
    if (mode == ThemeMode.dark) index = 2;
    await prefs.setInt(_keyThemeMode, index);
  }

  void setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAccentColor, color.value);
  }

  void setFontFamily(String font) async {
    _fontFamily = font;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFontFamily, font);
  }

  void setFontSizeFactor(double scale) async {
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
  }

  ThemeData get lightTheme {
    return AppTheme.create(
      accentColor: _accentColor,
      secondaryColor: secondaryColor,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
    );
  }

  ThemeData get darkTheme {
    return AppTheme.create(
      accentColor: _accentColor,
      secondaryColor: secondaryColor,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
    );
  }
}
