import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key for storing the download location in SharedPreferences
const String _downloadLocationKey = 'download_location';

/// Default download directory name
const String defaultDownloadFolder = 'MyMusicApp';

/// Provider for the download location
final downloadLocationProvider = StateNotifierProvider<DownloadLocationNotifier, String>((ref) {
  return DownloadLocationNotifier();
});

/// Notifier for managing download location
class DownloadLocationNotifier extends StateNotifier<String> {
  DownloadLocationNotifier() : super('') {
    _loadSavedLocation();
  }

  /// Load saved location from preferences
  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocation = prefs.getString(_downloadLocationKey);
    
    if (savedLocation != null && savedLocation.isNotEmpty) {
      state = savedLocation;
    } else {
      // Set default location
      final defaultPath = await getDefaultDownloadPath();
      state = defaultPath;
    }
  }

  /// Get default download path
  static Future<String> getDefaultDownloadPath() async {
    if (Platform.isAndroid) {
      // Use Downloads folder on Android
      final downloadPath = '/storage/emulated/0/Download/$defaultDownloadFolder';
      return downloadPath;
    }
    // Fallback to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$defaultDownloadFolder';
  }

  /// Set new download location
  Future<void> setLocation(String path) async {
    state = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadLocationKey, path);
    
    // Ensure directory exists
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Get current download path (non-async for sync access)
  String get downloadPath => state;

  /// Get full path for a filename
  String getFullPath(String filename) {
    return '$state/$filename';
  }

  /// Available download locations
  static List<DownloadLocation> getAvailableLocations() {
    return [
      DownloadLocation(
        name: 'Downloads Folder',
        path: '/storage/emulated/0/Download/$defaultDownloadFolder',
        icon: '📥',
      ),
    ];
  }
}

/// Model for a download location option
class DownloadLocation {
  final String name;
  final String path;
  final String icon;

  DownloadLocation({
    required this.name,
    required this.path,
    required this.icon,
  });
}
