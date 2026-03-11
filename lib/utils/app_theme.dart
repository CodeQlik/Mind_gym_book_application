import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color secondaryColor = Color(0xFF764BA2);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FD);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF2D3142);
  static const Color lightTextSecondary = Color(0xFF9E9E9E);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212); // Deep dark grey, almost black
  static const Color darkSurface = Color(0xFF1E1E1E); // Slightly lighter for cards
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);

  static TextTheme _buildTextTheme(TextTheme base, Color primary, Color secondary) {
    return GoogleFonts.outfitTextTheme(base).copyWith(
      displayLarge: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.roboto(color: primary),
      bodyMedium: GoogleFonts.roboto(color: secondary),
      bodySmall: GoogleFonts.roboto(color: secondary),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: lightTextPrimary),
      titleTextStyle: TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: _buildTextTheme(ThemeData.light().textTheme, lightTextPrimary, lightTextSecondary),
    iconTheme: const IconThemeData(color: lightTextPrimary),
    dividerColor: Colors.grey.shade200,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: darkTextPrimary),
      titleTextStyle: TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: _buildTextTheme(ThemeData.dark().textTheme, darkTextPrimary, darkTextSecondary),
    iconTheme: const IconThemeData(color: darkTextPrimary),
    dividerColor: Colors.grey.shade800,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
  );
}
