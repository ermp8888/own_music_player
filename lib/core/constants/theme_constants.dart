import 'package:flutter/material.dart';
import 'package:my_music_app/core/theme/app_theme.dart';

/// Theme constants - Colors and gradients for the app, delegating to AppTheme
class ThemeConstants {
  ThemeConstants._();

  // Primary colors
  static const Color primaryColor = AppTheme.primaryAccent;
  static const Color primaryLight = AppTheme.primaryAccentLight;
  static const Color primaryDark = AppTheme.primaryAccent;

  // Accent colors
  static const Color accentColor = AppTheme.primaryAccent;
  static const Color accentLight = AppTheme.primaryAccentLight;
  static const Color accentDark = AppTheme.primaryAccent;

  // Teal accent
  static const Color tealAccent = AppTheme.secondaryAccent;
  static const Color tealLight = AppTheme.secondaryAccent;
  
  // Orange/Coral accent
  static const Color coralAccent = AppTheme.secondaryAccent;
  
  // Background colors
  static const Color backgroundColor = AppTheme.backgroundPrimary;
  static const Color surfaceColor = AppTheme.backgroundSurface;
  static const Color cardColor = AppTheme.backgroundCard;
  static const Color cardColorLight = AppTheme.backgroundCard;

  // Text colors
  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color textMuted = AppTheme.textSecondary;

  // Status colors
  static const Color successColor = AppTheme.success;
  static const Color errorColor = AppTheme.error;
  static const Color warningColor = AppTheme.secondaryAccent;

  // Glassmorphism
  static const Color glassColor = Color(0x1AFFFFFF);
  static const Color glassBorderColor = AppTheme.divider;
  static const double glassBlur = 10.0;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryLight],
  );

  static const LinearGradient youtubeImportGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.primaryAccent,
      AppTheme.primaryAccentLight,
    ],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppTheme.backgroundSurface,
      AppTheme.backgroundPrimary,
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.backgroundCard,
      AppTheme.backgroundSurface,
    ],
  );

  static const LinearGradient playerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppTheme.backgroundCard,
      AppTheme.backgroundPrimary,
    ],
  );

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppTheme.secondaryAccent,
      AppTheme.primaryAccent,
    ],
  );

  // Shadows
  static List<BoxShadow> cardShadow = AppTheme.cardShadow;
  static List<BoxShadow> glowShadow = AppTheme.activeShadow;

  // Border radius
  static const double radiusSmall = AppTheme.sm;
  static const double radiusMedium = AppTheme.cardRadius;
  static const double radiusLarge = AppTheme.bottomSheetRadius;
  static const double radiusXLarge = AppTheme.bottomSheetRadius;
}
