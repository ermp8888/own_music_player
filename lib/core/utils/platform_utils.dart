import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform detection utilities
class PlatformUtils {
  PlatformUtils._();

  /// Check if running on mobile (Android/iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Check if running on desktop (Windows/Linux/macOS)
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Get platform name
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    return 'Unknown';
  }

  /// Get default music directory based on platform
  static Future<String?> getDefaultMusicDirectory() async {
    if (kIsWeb) return null;

    if (Platform.isAndroid) {
      return '/storage/emulated/0/Music';
    }
    if (Platform.isIOS) {
      return null; // iOS doesn't have a standard music directory
    }
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      return userProfile != null ? '$userProfile\\Music' : null;
    }
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      return home != null ? '$home/Music' : null;
    }
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      return home != null ? '$home/Music' : null;
    }
    return null;
  }

  /// Get downloads directory based on platform
  static Future<String?> getDownloadsDirectory() async {
    if (kIsWeb) return null;

    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    }
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      return userProfile != null ? '$userProfile\\Downloads' : null;
    }
    if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      return home != null ? '$home/Downloads' : null;
    }
    return null;
  }
}
