import 'package:flutter/material.dart';

/// Theme constants - Colors and gradients for the app
class ThemeConstants {
  ThemeConstants._();

  // Primary colors - Blue accent
  static const Color primaryColor = Color(0xFF4D7CFE); // Blue accent
  static const Color primaryLight = Color(0xFF6B93FF);
  static const Color primaryDark = Color(0xFF3A5FCC);

  // Accent colors
  static const Color accentColor = Color(0xFF5B6EF7); // Purple-blue
  static const Color accentLight = Color(0xFF7B8CFF);
  static const Color accentDark = Color(0xFF4558CC);

  // Teal accent for album art
  static const Color tealAccent = Color(0xFF2D8B7A);
  static const Color tealLight = Color(0xFF3DAA96);
  
  // Orange/Coral accent
  static const Color coralAccent = Color(0xFFF5A962);
  
  // Background colors - Darker theme
  static const Color backgroundColor = Color(0xFF0D0F14);
  static const Color surfaceColor = Color(0xFF131620);
  static const Color cardColor = Color(0xFF1A1D28);
  static const Color cardColorLight = Color(0xFF242836);

  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Status colors
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  // Glassmorphism
  static const Color glassColor = Color(0x1AFFFFFF);
  static const Color glassBorderColor = Color(0x20FFFFFF);
  static const double glassBlur = 10.0;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, accentColor],
  );

  static const LinearGradient youtubeImportGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4D5BD4),
      Color(0xFF6B7BF7),
      Color(0xFF8B9BFF),
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF131620),
      Color(0xFF0D0F14),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF242836),
      Color(0xFF1A1D28),
    ],
  );

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1D28),
      Color(0xFF0D0F14),
    ],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D8B7A),
      Color(0xFF3DAA96),
    ],
  );

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
}
