import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/purple_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;
  
  static final ThemeData _lightTheme = PurpleTheme.lightTheme.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(PurpleTheme.lightTheme.textTheme),
  );
  
  static final ThemeData _darkTheme = PurpleTheme.darkTheme.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(PurpleTheme.darkTheme.textTheme),
  );
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }
  
  // Helper method to get text style based on theme
  static TextStyle getTextStyle(BuildContext context, {
    bool isBold = false,
    double? fontSize,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return TextStyle(
      color: color ?? theme.colorScheme.onBackground,
      fontSize: fontSize ?? 16,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
    );
  }
}
