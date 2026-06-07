import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Helper to generate deterministic background colors for letter avatars based on title
class AvatarColorHelper {
  AvatarColorHelper._();

  static const List<Color> avatarColors = [
    AppTheme.avatarColor1,
    AppTheme.avatarColor2,
    AppTheme.avatarColor3,
    AppTheme.avatarColor4,
    AppTheme.avatarColor5,
    AppTheme.avatarColor6,
  ];

  static Color getColor(String title) {
    if (title.isEmpty) {
      return avatarColors[0];
    }
    // Use the sum of all code units to make the color distribution more varied but still deterministic
    final charCode = title.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final index = charCode % avatarColors.length;
    return avatarColors[index];
  }
}
