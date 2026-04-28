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
  static const Color darkBackground = Color(0xFF0F0F1A); // Synced with Subscription Screen
  static const Color darkSurface = Color(0xFF1E1E2C); 
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);

  static TextTheme _buildTextTheme(TextTheme base, Color primary, Color secondary) {
    // UNIFIED FONT FAMILY: POPPINS (Primary) & INTER (Subtitle/Simple Details)
    return GoogleFonts.poppinsTextTheme(base).copyWith(
      displayLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.inter(color: secondary, fontWeight: FontWeight.w500, letterSpacing: 0.2), // Subtitle Font
      bodyLarge: GoogleFonts.poppins(color: primary, fontSize: 16),
      bodyMedium: GoogleFonts.poppins(color: secondary, fontSize: 14),
      bodySmall: GoogleFonts.inter(color: secondary, fontSize: 12), // Subtle Detail Font
      labelLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
