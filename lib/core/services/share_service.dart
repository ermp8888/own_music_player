import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';

/// Service for sharing songs and app content
class ShareService {
  /// Share a song file with other apps
  static Future<void> shareSong(Song song) async {
    final file = File(song.filePath);
    
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(song.filePath)],
        text: '🎵 ${song.title} - ${song.artist}',
        subject: song.title,
      );
    } else {
      // If file doesn't exist, share song info
      await Share.share(
        '🎵 Now playing: ${song.title} by ${song.artist}',
        subject: song.title,
      );
    }
  }

  /// Share multiple songs
  static Future<void> shareSongs(List<Song> songs) async {
    final files = <XFile>[];
    
    for (final song in songs) {
      final file = File(song.filePath);
      if (await file.exists()) {
        files.add(XFile(song.filePath));
      }
    }
    
    if (files.isNotEmpty) {
      await Share.shareXFiles(
        files,
        text: '🎵 Sharing ${files.length} songs from DownTune',
      );
    }
  }

  /// Share app
  static Future<void> shareApp() async {
    await Share.share(
      'Check out DownTune - A beautiful music player app for Android!\n\n'
      'Download songs from YouTube and enjoy your music offline.\n\n'
      'Download: https://github.com/ermp8888/own_music_player',
      subject: 'DownTune - Music Player App',
    );
  }

  /// Share song info (text only, no file)
  static Future<void> shareSongInfo(Song song) async {
    await Share.share(
      '🎵 Listening to: ${song.title}\n'
      '🎤 Artist: ${song.artist}\n'
      '📱 Shared from DownTune',
      subject: song.title,
    );
  }
}
