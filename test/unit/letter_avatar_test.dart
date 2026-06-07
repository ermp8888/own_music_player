import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/helpers/avatar_color_helper.dart';

void main() {
  const avatarColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6B6B),
    Color(0xFF00D4AA),
    Color(0xFFFF9800),
    Color(0xFF3D5AFE),
    Color(0xFFE91E8C),
  ];

  test('same title always gets same color', () {
    final color1 = AvatarColorHelper.getColor('Tum Hi Ho');
    final color2 = AvatarColorHelper.getColor('Tum Hi Ho');
    expect(color1, equals(color2));
  });

  test('color is always from defined palette', () {
    final testTitles = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'Z', '1', '9'];
    for (final title in testTitles) {
      final color = AvatarColorHelper.getColor(title);
      expect(avatarColors.contains(color), isTrue,
          reason: 'Color for "$title" not in palette');
    }
  });

  test('empty title does not crash', () {
    expect(() => AvatarColorHelper.getColor(''), returnsNormally);
  });

  test('all 6 colors are reachable', () {
    // Find a title that produces each color
    final seenColors = <Color>{};
    for (int i = 0; i < 100; i++) {
      final title = String.fromCharCode(65 + i); // A, B, C...
      seenColors.add(AvatarColorHelper.getColor(title));
      if (seenColors.length == 6) break;
    }
    expect(seenColors.length, 6,
        reason: 'Not all 6 palette colors are reachable');
  });
}
