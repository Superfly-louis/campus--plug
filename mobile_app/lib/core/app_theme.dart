import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constants.dart';

class AppTheme {
  static ThemeData get light {
    final syne = GoogleFonts.syneTextTheme();
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.syne().fontFamily,
      textTheme: syne.apply(
        bodyColor: AppConstants.textPrimary,
        displayColor: AppConstants.textPrimary,
      ),
      primaryColor: AppConstants.primaryColor,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        primary: AppConstants.primaryColor,
        surface: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.authPillRadius),
          borderSide: const BorderSide(color: AppConstants.inputBorderOrange),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.authPillRadius),
          borderSide: const BorderSide(color: AppConstants.inputBorderOrange),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.authPillRadius),
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppConstants.authButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.authPillRadius),
          ),
          textStyle: GoogleFonts.syne(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
