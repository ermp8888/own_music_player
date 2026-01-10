import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../utils/platform_utils.dart';
import 'package:drift/drift.dart';

/// Service for scanning local music files
class FileScannerService {
  final AppDatabase _database;

  /// Supported audio file extensions
  static const List<String> supportedExtensions = [
    '.mp3', '.m4a', '.wav', '.flac', '.aac', '.ogg', '.wma', '.opus', '.webm'
  ];

  FileScannerService(this._database);

  /// Request storage permission
  Future<bool> requestPermission() async {
    if (PlatformUtils.isAndroid) {
      // Try multiple permission approaches
      
      // For Android 13+, we need audio permission
      var audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;

      // Fallback to storage permission for older Android
      var storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      // Try manage external storage for Android 11+
      var manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    }

    if (PlatformUtils.isIOS) {
      final status = await Permission.mediaLibrary.request();
      return status.isGranted;
    }

    // Desktop platforms don't require runtime permissions
    return true;
  }

  /// Check if permission is granted
  Future<bool> hasPermission() async {
    if (PlatformUtils.isAndroid) {
      final audioGranted = await Permission.audio.isGranted;
      final storageGranted = await Permission.storage.isGranted;
      final manageGranted = await Permission.manageExternalStorage.isGranted;
      return audioGranted || storageGranted || manageGranted;
    }

    if (PlatformUtils.isIOS) {
      return await Permission.mediaLibrary.isGranted;
    }

    return true;
  }

  /// Get all possible music directories on Android
  Future<List<String>> _getMusicDirectories() async {
    final dirs = <String>[];
    
    // Common Android music directories
    final commonPaths = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/storage/emulated/0/Download/MyMusicApp', // App downloads
      '/storage/emulated/0/DCIM',
      '/storage/emulated/0/Ringtones',
      '/storage/emulated/0/Notifications',
      '/storage/emulated/0/Podcasts',
      '/storage/emulated/0/Alarms',
      '/storage/emulated/0/Audio',
      '/storage/emulated/0/Recordings',
      '/storage/emulated/0/Android/media',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
      '/storage/emulated/0/Telegram/Telegram Audio',
      '/storage/emulated/0/Samsung Music',
      '/storage/emulated/0/SamsungMusic',
    ];
    
    for (final path in commonPaths) {
      if (await Directory(path).exists()) {
        dirs.add(path);
      }
    }
    
    // Also check external storage directories
    try {
      final externalDirs = await getExternalStorageDirectories();
      if (externalDirs != null) {
        for (final dir in externalDirs) {
          // Go up to the root of external storage
          var parent = dir.parent.parent.parent.parent;
          final musicDir = Directory('${parent.path}/Music');
          final downloadDir = Directory('${parent.path}/Download');
          
          if (await musicDir.exists()) dirs.add(musicDir.path);
          if (await downloadDir.exists()) dirs.add(downloadDir.path);
        }
      }
    } catch (e) {
      // Ignore errors
    }
    
    return dirs.toSet().toList(); // Remove duplicates
  }

  /// Scan for music files on Android/iOS - scans entire device storage
  Future<List<Song>> scanMusicMobile() async {
    final hasAccess = await hasPermission();
    if (!hasAccess) {
      final granted = await requestPermission();
      if (!granted) return [];
    }

    final List<Song> savedSongs = [];
    
    // Scan the entire internal storage
    final rootDirs = [
      '/storage/emulated/0',  // Primary internal storage
    ];
    
    // Also check for SD cards
    try {
      final storageDir = Directory('/storage');
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list()) {
          if (entity is Directory) {
            final name = entity.path.split('/').last;
            // Skip emulated (already added) and self
            if (name != 'emulated' && name != 'self' && !name.startsWith('.')) {
              rootDirs.add(entity.path);
            }
          }
        }
      }
    } catch (e) {
      // Ignore SD card detection errors
    }

    // Directories to skip (Android system folders that cause issues)
    final skipDirs = {
      'Android/data',
      'Android/obb', 
      '.thumbnails',
      '.cache',
      'cache',
      'Cache',
    };

    for (final rootPath in rootDirs) {
      final rootDir = Directory(rootPath);
      try {
        if (await rootDir.exists()) {
          await _scanDirectoryRecursive(rootDir, savedSongs, skipDirs);
        }
      } catch (e) {
        // Skip inaccessible directories
      }
    }

    return savedSongs;
  }

  /// Recursively scan directory for music files
  Future<void> _scanDirectoryRecursive(
    Directory dir,
    List<Song> savedSongs,
    Set<String> skipDirs,
  ) async {
    try {
      await for (final entity in dir.list(followLinks: false)) {
        // Check if this directory should be skipped
        final relativePath = entity.path.replaceFirst('/storage/emulated/0/', '');
        if (skipDirs.any((skip) => relativePath.startsWith(skip))) {
          continue;
        }

        if (entity is Directory) {
          // Skip hidden directories
          final name = entity.path.split('/').last;
          if (!name.startsWith('.')) {
            await _scanDirectoryRecursive(entity, savedSongs, skipDirs);
          }
        } else if (entity is File) {
          final ext = '.${entity.path.split('.').last.toLowerCase()}';
          if (supportedExtensions.contains(ext)) {
            try {
              final stat = await entity.stat();
              // Skip very small files (likely not real audio)
              if (stat.size < 10000) continue;
              
              final title = _extractTitleFromPath(entity.path);

              final id = await _database.upsertSong(
                SongsCompanion.insert(
                  filePath: entity.path,
                  title: title,
                  artist: const Value('Unknown Artist'),
                  album: const Value('Unknown Album'),
                  duration: const Value(0),
                  fileSize: Value(stat.size),
                ),
              );
              final savedSong = await _database.getSongById(id);
              if (savedSong != null) {
                savedSongs.add(savedSong);
              }
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }
    } catch (e) {
      // Skip directories we can't access
    }
  }

  /// Scan a directory for music files
  Future<List<Song>> _scanDirectory(Directory dir) async {
    final List<Song> savedSongs = [];

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = '.${entity.path.split('.').last.toLowerCase()}';
          if (supportedExtensions.contains(ext)) {
            try {
              final stat = await entity.stat();
              final title = _extractTitleFromPath(entity.path);

              final id = await _database.upsertSong(
                SongsCompanion.insert(
                  filePath: entity.path,
                  title: title,
                  artist: const Value('Unknown Artist'),
                  album: const Value('Unknown Album'),
                  duration: const Value(0),
                  fileSize: Value(stat.size),
                ),
              );
              final savedSong = await _database.getSongById(id);
              if (savedSong != null) {
                savedSongs.add(savedSong);
              }
            } catch (e) {
              // Skip files we can't read
            }
          }
        }
      }
    } catch (e) {
      // Skip directories we can't access
    }

    return savedSongs;
  }

  /// Scan for music files on desktop
  Future<List<Song>> scanMusicDesktop([String? customPath]) async {
    final musicDir = customPath ?? await PlatformUtils.getDefaultMusicDirectory();
    if (musicDir == null) return [];

    final dir = Directory(musicDir);
    if (!await dir.exists()) return [];

    return _scanDirectory(dir);
  }

  /// Scan music files (auto-detects platform)
  Future<List<Song>> scanMusic([String? customPath]) async {
    if (PlatformUtils.isMobile) {
      return scanMusicMobile();
    } else {
      return scanMusicDesktop(customPath);
    }
  }

  /// Quick rescan - only add new files
  Future<List<Song>> quickRescan() async {
    final existingSongs = await _database.getAllSongs();
    final existingPaths = existingSongs.map((s) => s.filePath).toSet();

    if (PlatformUtils.isMobile) {
      final hasAccess = await hasPermission();
      if (!hasAccess) return [];

      final musicDirs = await _getMusicDirectories();
      final List<Song> newSongs = [];

      for (final musicDir in musicDirs) {
        final dir = Directory(musicDir);
        try {
          if (await dir.exists()) {
            await for (final entity in dir.list(recursive: true, followLinks: false)) {
              if (entity is File && !existingPaths.contains(entity.path)) {
                final ext = '.${entity.path.split('.').last.toLowerCase()}';
                if (supportedExtensions.contains(ext)) {
                  try {
                    final stat = await entity.stat();
                    final title = _extractTitleFromPath(entity.path);

                    final id = await _database.upsertSong(
                      SongsCompanion.insert(
                        filePath: entity.path,
                        title: title,
                        artist: const Value('Unknown Artist'),
                        album: const Value('Unknown Album'),
                        duration: const Value(0),
                        fileSize: Value(stat.size),
                      ),
                    );
                    final savedSong = await _database.getSongById(id);
                    if (savedSong != null) {
                      newSongs.add(savedSong);
                    }
                  } catch (e) {
                    // Skip files we can't read
                  }
                }
              }
            }
          }
        } catch (e) {
          // Skip directories we can't access
        }
      }
      return newSongs;
    }

    return [];
  }

  /// Remove songs that no longer exist on disk
  Future<int> cleanupMissingSongs() async {
    final songs = await _database.getAllSongs();
    int removedCount = 0;

    for (final song in songs) {
      final file = File(song.filePath);
      if (!await file.exists()) {
        await _database.deleteSong(song.id);
        removedCount++;
      }
    }

    return removedCount;
  }

  String _extractTitleFromPath(String path) {
    final fileName = path.split(Platform.pathSeparator).last;
    final nameWithoutExt = fileName.split('.').first;
    return nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ');
  }
}
