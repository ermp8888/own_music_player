import 'package:permission_handler/permission_handler.dart';
import '../utils/platform_utils.dart';

/// Service for handling permissions across platforms
class PermissionService {
  PermissionService._();

  /// Request storage/audio permissions for music scanning
  static Future<bool> requestStoragePermission() async {
    if (PlatformUtils.isDesktop) {
      return true; // No runtime permissions needed on desktop
    }

    if (PlatformUtils.isAndroid) {
      // Try audio permission first (Android 13+)
      var status = await Permission.audio.request();
      if (status.isGranted) return true;

      // Fallback to storage permission
      status = await Permission.storage.request();
      if (status.isGranted) return true;

      // Try manage external storage for broader access
      status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }

    if (PlatformUtils.isIOS) {
      final status = await Permission.mediaLibrary.request();
      return status.isGranted;
    }

    return false;
  }

  /// Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    if (PlatformUtils.isDesktop) return true;

    if (PlatformUtils.isAndroid) {
      final audioGranted = await Permission.audio.isGranted;
      final storageGranted = await Permission.storage.isGranted;
      final manageGranted = await Permission.manageExternalStorage.isGranted;
      return audioGranted || storageGranted || manageGranted;
    }

    if (PlatformUtils.isIOS) {
      return await Permission.mediaLibrary.isGranted;
    }

    return false;
  }

  /// Request notification permission (for background playback)
  static Future<bool> requestNotificationPermission() async {
    if (PlatformUtils.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Check all required permissions
  static Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'storage': await hasStoragePermission(),
      'notification': await Permission.notification.isGranted,
    };
  }

  /// Open app settings
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
