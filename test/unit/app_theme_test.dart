import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tokens', () {
    test('AppTheme has correct background primary color', () {
      expect(AppTheme.backgroundPrimary, const Color(0xFF0A0A0F));
    });

    test('AppTheme has correct primary accent color', () {
      expect(AppTheme.primaryAccent, const Color(0xFF6C63FF));
    });

    test('AppTheme has correct secondary accent color', () {
      expect(AppTheme.secondaryAccent, const Color(0xFF00D4AA));
    });

    test('AppTheme has correct error color', () {
      expect(AppTheme.error, const Color(0xFFFF6B6B));
    });

    test('AppTheme card border radius is 16px', () {
      expect(AppTheme.cardRadius, 16.0);
    });

    test('AppTheme button border radius is 12px', () {
      expect(AppTheme.buttonRadius, 12.0);
    });

    test('AppTheme chip border radius is 50px', () {
      expect(AppTheme.chipRadius, 50.0);
    });

    test('AppTheme spacing values are correct', () {
      expect(AppTheme.xs, 4.0);
      expect(AppTheme.sm, 8.0);
      expect(AppTheme.md, 16.0);
      expect(AppTheme.lg, 24.0);
      expect(AppTheme.xl, 32.0);
      expect(AppTheme.xxl, 48.0);
    });

    test('No hardcoded colors exist outside AppTheme', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final colorRegex = RegExp(r'Color\(0x[fF]{2}[0-9a-fA-F]{6}\)');

      final violations = <String>[];

      for (final file in dartFiles) {
        // Skip app_theme.dart and theme_constants.dart (which delegates to AppTheme)
        if (file.path.endsWith('app_theme.dart') ||
            file.path.endsWith('theme_constants.dart') ||
            file.path.endsWith('.g.dart')) {
          continue;
        }

        final content = file.readAsStringSync();
        final matches = colorRegex.allMatches(content);
        for (final match in matches) {
          violations.add('${file.path}: ${match.group(0)}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Hardcoded Color(0xFF...) instances found outside app_theme.dart / theme_constants.dart:\n'
            '${violations.join('\n')}',
      );
    });
  });
}
