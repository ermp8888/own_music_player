import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/providers/download_location_provider.dart';

/// Settings Screen with app options
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadLocation = ref.watch(downloadLocationProvider);

    return Material(
      color: Colors.transparent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
        
        // App Section
        _buildSectionHeader('App'),
        _buildSettingsTile(
          icon: Icons.share_rounded,
          title: 'Share App',
          subtitle: 'Share DownTune APK with friends',
          onTap: () => _shareApp(context),
        ),
        _buildSettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: 'App information and credits',
          onTap: () => _showAboutDialog(context),
        ),

        const SizedBox(height: 24),

        // Storage Section
        _buildSectionHeader('Storage'),
        _buildSettingsTile(
          icon: Icons.folder_open_rounded,
          title: 'Download Location',
          subtitle: _getDisplayPath(downloadLocation),
          onTap: () => _showLocationPicker(context, ref),
        ),

        const SizedBox(height: 24),

        // Playback Section
        _buildSectionHeader('Playback'),
        _buildSettingsTile(
          icon: Icons.high_quality_rounded,
          title: 'Audio Quality',
          subtitle: 'High (320kbps)',
          onTap: () {},
        ),

        const SizedBox(height: 40),

        // Version info
        Center(
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: ThemeConstants.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'DownTune',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _getDisplayPath(String path) {
    // Show a user-friendly path
    if (path.contains('/Music/')) {
      return 'Music/${path.split('/Music/').last}';
    } else if (path.contains('/Download/')) {
      return 'Downloads/${path.split('/Download/').last}';
    } else if (path.contains('/0/')) {
      return 'Internal Storage/${path.split('/0/').last}';
    }
    return path;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: ThemeConstants.primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: ThemeConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeConstants.cardColorLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ThemeConstants.textPrimary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: ThemeConstants.textMuted,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right_rounded,
          color: ThemeConstants.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }

  void _shareApp(BuildContext context) async {
    // Try multiple approaches to share the APK
    
    // Approach 1: Check if we have the APK in Downloads folder
    final downloadApkPath = '/storage/emulated/0/Download/DownTune.apk';
    if (await File(downloadApkPath).exists()) {
      await Share.shareXFiles(
        [XFile(downloadApkPath)],
        text: '📱 DownTune - Music Player App\n\nInstall this APK to enjoy offline music!',
        subject: 'DownTune App',
      );
      return;
    }
    
    // Approach 2: Try to access the app's own APK via data directory
    // On Android, the installed APK is at /data/app/[package]/base.apk
    final possibleApkPaths = [
      '/data/app/com.example.my_music_app-1/base.apk',
      '/data/app/com.example.my_music_app-2/base.apk',
      '/data/app/~~random/com.example.my_music_app/base.apk',
    ];
    
    for (final path in possibleApkPaths) {
      try {
        final apkFile = File(path);
        if (await apkFile.exists()) {
          // Copy to cache for sharing (we can't share directly from /data/app)
          final cacheDir = await getTemporaryDirectory();
          final sharePath = '${cacheDir.path}/DownTune.apk';
          await apkFile.copy(sharePath);
          
          await Share.shareXFiles(
            [XFile(sharePath)],
            text: '📱 DownTune - Music Player App\n\nInstall this APK to enjoy offline music!',
            subject: 'DownTune App',
          );
          return;
        }
      } catch (e) {
        // Continue to next path
      }
    }
    
    // Approach 3: Copy APK from app's own directory to Downloads and share
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final parentDir = appDir.parent.parent.parent.parent;
      // Try to find base.apk in the app's installation directory
      final apkPath = '${parentDir.path}/base.apk';
      final apkFile = File(apkPath);
      
      if (await apkFile.exists()) {
        final sharePath = '/storage/emulated/0/Download/DownTune.apk';
        await apkFile.copy(sharePath);
        
        await Share.shareXFiles(
          [XFile(sharePath)],
          text: '📱 DownTune - Music Player App\n\nInstall this APK to enjoy offline music!',
          subject: 'DownTune App',
        );
        return;
      }
    } catch (e) {
      // Continue to fallback
    }
    
    // Final fallback - create the APK in Downloads for manual sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('To share the app, please copy the APK to Downloads folder'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, WidgetRef ref) {
    final locations = DownloadLocationNotifier.getAvailableLocations();
    final currentLocation = ref.read(downloadLocationProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose Download Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ThemeConstants.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Preset locations
            ...locations.map((location) => ListTile(
              leading: Text(location.icon, style: const TextStyle(fontSize: 24)),
              title: Text(location.name),
              subtitle: Text(
                location.path.replaceAll('/storage/emulated/0/', ''),
                style: TextStyle(
                  color: ThemeConstants.textMuted,
                  fontSize: 12,
                ),
              ),
              trailing: currentLocation == location.path
                  ? Icon(Icons.check_circle, color: ThemeConstants.primaryColor)
                  : null,
              onTap: () async {
                await ref.read(downloadLocationProvider.notifier).setLocation(location.path);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Download location set to ${location.name}')),
                );
              },
            )),
            const Divider(),
            // Browse folder option
            ListTile(
              leading: const Text('📂', style: TextStyle(fontSize: 24)),
              title: const Text('Browse Folder'),
              subtitle: Text(
                'Choose any folder on your device',
                style: TextStyle(
                  color: ThemeConstants.textMuted,
                  fontSize: 12,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _browseFolder(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _browseFolder(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Download Folder',
      );
      
      if (result != null) {
        await ref.read(downloadLocationProvider.notifier).setLocation(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download location set to: ${result.split('/').last}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not access folder picker')),
      );
    }
  }


  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: ThemeConstants.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'DownTune',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ThemeConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: ThemeConstants.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'A modern music player app with YouTube downloading capabilities. '
              'Enjoy your favorite music offline with a beautiful dark interface.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ThemeConstants.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ThemeConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(Icons.download_rounded, 'Download from YouTube'),
            _buildFeatureItem(Icons.library_music_rounded, 'Local music library'),
            _buildFeatureItem(Icons.playlist_play_rounded, 'Custom playlists'),
            _buildFeatureItem(Icons.favorite_rounded, 'Liked songs'),
            _buildFeatureItem(Icons.share_rounded, 'Share music'),
            const SizedBox(height: 20),
            Text(
              'Made with ❤️',
              style: TextStyle(
                fontSize: 12,
                color: ThemeConstants.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ThemeConstants.primaryColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: ThemeConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
