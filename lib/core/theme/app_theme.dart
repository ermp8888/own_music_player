import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configuration - Design System
class AppTheme {
  AppTheme._();

  // Color Tokens
  static const Color backgroundPrimary = Color(0xFF0A0A0F);
  static const Color backgroundSurface = Color(0xFF141420);
  static const Color backgroundCard = Color(0xFF1C1C2E);
  static const Color primaryAccent = Color(0xFF6C63FF);
  static const Color primaryAccentLight = Color(0xFF8B85FF);
  static const Color secondaryAccent = Color(0xFF00D4AA);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9B9BAA);
  static const Color textDisabled = Color(0xFF4A4A5A);
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4CAF50);
  static const Color divider = Color(0xFF2A2A3A);

  // Additional Color Accent Tokens
  static const Color orangeAccent = Color(0xFFF5A962);
  static const Color orangeAccentLight = Color(0xFFE8945A);
  static const Color purpleAccent = Color(0xFF9B7FE6);
  static const Color purpleAccentLight = Color(0xFFB49AFF);
  static const Color pinkAccent = Color(0xFFEC4899);
  static const Color pinkAccentLight = Color(0xFFF472B6);
  static const Color blueAccent = Color(0xFF6366F1);
  static const Color blueAccentLight = Color(0xFF8B5CF6);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color greenAccentLight = Color(0xFF34D399);
  static const Color redAccent = Color(0xFFFF4757);
  static const Color redAccentLight = Color(0xFFFF6B81);

  // Avatar Colors
  static const Color avatarColor1 = Color(0xFF6C63FF);
  static const Color avatarColor2 = Color(0xFFFF6B6B);
  static const Color avatarColor3 = Color(0xFF00D4AA);
  static const Color avatarColor4 = Color(0xFFFF9800);
  static const Color avatarColor5 = Color(0xFF3D5AFE);
  static const Color avatarColor6 = Color(0xFFE91E8C);

  // Shape Tokens
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double chipRadius = 50.0;
  static const double inputRadius = 12.0;
  static const double bottomSheetRadius = 24.0;
  static const double thumbnailRadius = 12.0;

  // Spacing Tokens
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryAccent.withOpacity(0.08), // #6C63FF15
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get activeShadow => [
        BoxShadow(
          color: primaryAccent.withOpacity(0.25), // #6C63FF40
          blurRadius: 12,
        ),
      ];

  // Typography Getters
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 15.0,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 11.0,
        fontWeight: FontWeight.normal,
        color: textDisabled,
      );

  // Material ThemeData Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundPrimary,
      cardColor: backgroundCard,
      dividerColor: divider,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: backgroundSurface,
        error: error,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: label,
        labelMedium: label,
        labelSmall: caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: displayMedium,
        iconTheme: const IconThemeData(
          color: textPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAccent,
        foregroundColor: textPrimary,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryAccent,
          side: const BorderSide(color: primaryAccent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primaryAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: bodyMedium.copyWith(color: textSecondary),
        labelStyle: label,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryAccent,
        inactiveTrackColor: divider,
        thumbColor: textPrimary,
        overlayColor: primaryAccent.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F0F1A),
        selectedItemColor: primaryAccent,
        unselectedItemColor: textDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: backgroundCard,
        contentTextStyle: bodyMedium.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(bottomSheetRadius),
        ),
        titleTextStyle: titleLarge,
        contentTextStyle: bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(bottomSheetRadius),
          ),
        ),
      ),
    );
  }
}
