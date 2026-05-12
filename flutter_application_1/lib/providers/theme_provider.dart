import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // ==================== ЦВЕТА ====================
  // Общие
  static const Color primaryPurple = Color(0xFFA58EFF);
  static const Color accentPink = Color(0xFFF2C9D4);
  static const Color textGrey = Color(0xFF9094A6);

  // Светлая тема
  static const Color lightBg = Colors.white;
  static const Color lightSurface = Color(0xFFF8F9FB);
  static const Color lightTextPrimary = Color(0xFF1E1E2E);
  static const Color lightBorder = Color(0xFFEEEEEE);
  static const Color lightCardBg = Colors.white;

  // Тёмная тема
  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkTextPrimary = Color(0xFFE8E8F0);
  static const Color darkBorder = Color(0xFF2A2A3E);
  static const Color darkCardBg = Color(0xFF16162A);

  // ==================== ТЕМЫ ====================
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    primaryColor: primaryPurple,
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: accentPink,
      surface: lightSurface,
      onSurface: lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(
        color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: GoogleFonts.robotoTextTheme(),
    cardTheme: CardThemeData(
      color: lightCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: primaryPurple,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: accentPink,
      surface: darkSurface,
      onSurface: darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(
        color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      color: darkCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
    ),
  );
}

// ==================== РАСШИРЕНИЕ КОНТЕКСТА ====================
// Удобные геттеры для частого использования цветов темы
extension ThemeContextExt on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor => isDark ? ThemeProvider.darkBg : ThemeProvider.lightBg;
  Color get surfaceColor => isDark ? ThemeProvider.darkSurface : ThemeProvider.lightSurface;
  Color get textPrimary => isDark ? ThemeProvider.darkTextPrimary : ThemeProvider.lightTextPrimary;
  Color get borderColor => isDark ? ThemeProvider.darkBorder : ThemeProvider.lightBorder;
  Color get cardBg => isDark ? ThemeProvider.darkCardBg : ThemeProvider.lightCardBg;
  Color get textSecondary => isDark ? Colors.white60 : ThemeProvider.textGrey;

  // Glass-эффект цвета
  Color get glassColor => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.7);
  Color get glassBorder => isDark
      ? Colors.white.withValues(alpha: 0.1)
      : Colors.white.withValues(alpha: 0.3);
}
