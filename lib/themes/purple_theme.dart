import 'package:flutter/material.dart';

/// Purple Theme for Instagram-style app
/// Premium purple palette inspired by logo design
class PurpleTheme {
  // Primary Colors
  static const Color primaryPurple = Color(0xFF7B3FE4);      // Rich royal purple
  static const Color deepViolet = Color(0xFF5E2F9C);       // Deep violet for dark accents
  static const Color lavender = Color(0xFFB19CD9);         // Soft lavender
  static const Color lightLavender = Color(0xFFE6E6FA);     // Very light lavender for backgrounds
  
  // Secondary Accents
  static const Color magentaPurple = Color(0xFF9B59B6);     // Magenta-purple gradient
  static const Color softPurple = Color(0xFF9B7EBD);        // Soft purple for subtle accents
  
  // Neutral Colors
  static const Color pureWhite = Color(0xFFFFFFFF);        // Clean white
  static const Color softWhite = Color(0xFFF8F9FA);         // Off-white for cards
  static const Color lightGray = Color(0xFF8E8E93);        // Light gray text
  static const Color mediumGray = Color(0xFF636366);       // Medium gray
  static const Color darkGray = Color(0xFF48484A);         // Dark gray
  static const Color deepCharcoal = Color(0xFF1C1C1E);     // Deep charcoal for dark mode
  
  // Special Colors
  static const Color storyGradientStart = Color(0xFF7B3FE4);  // Purple gradient start
  static const Color storyGradientEnd = Color(0xFFB19CD9);    // Lavender gradient end
  static const Color likeActive = Color(0xFFE91E63);          // Keep red for likes (Instagram standard)
  static const Color errorRed = Color(0xFFFF3B30);           // Error red
  static const Color successGreen = Color(0xFF34C759);        // Success green

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, lavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient storyGradient = LinearGradient(
    colors: [storyGradientStart, storyGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primaryPurple, magentaPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryPurple,
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: lavender,
      surface: pureWhite,
      background: pureWhite,
      error: errorRed,
      onPrimary: pureWhite,
      onSecondary: deepViolet,
      onSurface: deepCharcoal,
      onBackground: deepCharcoal,
    ),
    
    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: pureWhite,
      foregroundColor: deepCharcoal,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: deepCharcoal,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: deepCharcoal,
        size: 28,
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: pureWhite,
        elevation: 2,
        shadowColor: primaryPurple.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPurple,
        side: const BorderSide(color: primaryPurple, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: softWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lightGray.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      labelStyle: const TextStyle(color: mediumGray),
      hintStyle: TextStyle(color: lightGray.withOpacity(0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: pureWhite,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: deepCharcoal,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: deepCharcoal,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: deepCharcoal,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: deepCharcoal,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: deepCharcoal,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        color: deepCharcoal,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: TextStyle(
        color: deepCharcoal,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: primaryPurple,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: deepCharcoal,
      size: 24,
    ),

    // Tab Bar Theme
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryPurple,
      unselectedLabelColor: lightGray,
      indicatorColor: primaryPurple,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: pureWhite,
      selectedItemColor: primaryPurple,
      unselectedItemColor: lightGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: pureWhite,
      elevation: 4,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryPurple;
        }
        return lightGray;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryPurple.withOpacity(0.3);
        }
        return lightGray.withOpacity(0.2);
      }),
    ),

    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryPurple;
        }
        return pureWhite;
      }),
      checkColor: MaterialStateProperty.all(pureWhite),
      side: const BorderSide(color: lightGray, width: 1.5),
    ),

    // Radio Theme
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryPurple;
        }
        return lightGray;
      }),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryPurple,
      linearTrackColor: lightLavender,
      circularTrackColor: lightLavender,
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: deepCharcoal,
      contentTextStyle: const TextStyle(color: pureWhite),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: lightLavender,
      thickness: 0.5,
      space: 1,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryPurple,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: lavender,
      surface: Color(0xFF2C2C2E),
      background: deepCharcoal,
      error: errorRed,
      onPrimary: pureWhite,
      onSecondary: deepCharcoal,
      onSurface: pureWhite,
      onBackground: pureWhite,
    ),
    
    // App Bar Theme (Dark)
    appBarTheme: const AppBarTheme(
      backgroundColor: deepCharcoal,
      foregroundColor: pureWhite,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: pureWhite,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: pureWhite,
        size: 28,
      ),
    ),

    // Button Themes (Dark)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: pureWhite,
        elevation: 3,
        shadowColor: primaryPurple.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lavender,
        side: const BorderSide(color: lavender, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lavender,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Input Decoration Theme (Dark)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: mediumGray.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: mediumGray.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
      labelStyle: const TextStyle(color: lightGray),
      hintStyle: TextStyle(color: mediumGray.withOpacity(0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Card Theme (Dark)
    cardTheme: CardThemeData(
      color: const Color(0xFF2C2C2E),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),

    // Text Theme (Dark)
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: pureWhite,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: pureWhite,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: pureWhite,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: pureWhite,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: pureWhite,
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: TextStyle(
        color: pureWhite,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: TextStyle(
        color: pureWhite,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: lavender,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Icon Theme (Dark)
    iconTheme: const IconThemeData(
      color: pureWhite,
      size: 24,
    ),

    // Tab Bar Theme (Dark)
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryPurple,
      unselectedLabelColor: lightGray,
      indicatorColor: primaryPurple,
      labelStyle: TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),

    // Bottom Navigation Bar Theme (Dark)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: deepCharcoal,
      selectedItemColor: primaryPurple,
      unselectedItemColor: lightGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Floating Action Button Theme (Dark)
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: pureWhite,
      elevation: 4,
    ),
  );
}

// Custom Color Extension for easy access
extension PurpleThemeExtension on ThemeData {
  Color get primaryPurple => PurpleTheme.primaryPurple;
  Color get deepViolet => PurpleTheme.deepViolet;
  Color get lavender => PurpleTheme.lavender;
  Color get lightLavender => PurpleTheme.lightLavender;
  Color get storyGradientStart => PurpleTheme.storyGradientStart;
  Color get storyGradientEnd => PurpleTheme.storyGradientEnd;
}