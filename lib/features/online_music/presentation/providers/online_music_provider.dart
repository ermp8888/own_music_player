import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/download_location_provider.dart';
import '../../../local_music/presentation/providers/library_provider.dart';
import '../../../youtube_import/presentation/screens/downloads_screen.dart';
import '../../data/repositories/online_music_repository.dart';
import '../../../player/presentation/providers/player_provider.dart';

/// Provider for holding the search query
final onlineMusicSearchQueryProvider = StateProvider<String>((ref) {
  return 'latest bollywood';
});

/// FutureProvider that fetches the songs matching the current search query
final onlineMusicSongsProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  final query = ref.watch(onlineMusicSearchQueryProvider);
  final repository = ref.watch(onlineMusicRepositoryProvider);
  
  if (query.trim().isEmpty) {
    return [];
  }
  
  return repository.searchSongs(query);
});

enum OnlineDownloadStatus { idle, downloading, complete, error }

class OnlineDownloadState {
  final OnlineDownloadStatus status;
  final double progress;
  final String? songTitle;
  final String? errorMessage;

  const OnlineDownloadState({
    this.status = OnlineDownloadStatus.idle,
    this.progress = 0.0,
    this.songTitle,
    this.errorMessage,
  });

  OnlineDownloadState copyWith({
    OnlineDownloadStatus? status,
    double? progress,
    String? songTitle,
    String? errorMessage,
  }) {
    return OnlineDownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      songTitle: songTitle ?? this.songTitle,
      errorMessage: errorMessage,
    );
  }
}

class OnlineMusicDownloadNotifier extends StateNotifier<OnlineDownloadState> {
  final Ref _ref;

  OnlineMusicDownloadNotifier(this._ref) : super(const OnlineDownloadState());

  Future<void> downloadSong(Song song, {String? customPath}) async {
    if (state.status == OnlineDownloadStatus.downloading) return;

    try {
      state = OnlineDownloadState(
        status: OnlineDownloadStatus.downloading,
        progress: 0.0,
        songTitle: song.title,
      );

      // 1. Get download location
      String outputDir;
      if (customPath != null && customPath.isNotEmpty) {
        outputDir = customPath;
      } else {
        final locationNotifier = _ref.read(downloadLocationProvider.notifier);
        outputDir = _ref.read(downloadLocationProvider);
        if (outputDir.isEmpty) {
          outputDir = await DownloadLocationNotifier.getDefaultDownloadPath();
          await locationNotifier.setLocation(outputDir);
        }
      }

      // 2. Ensure output directory exists
      final dir = Directory(outputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 3. Prepare unique safe path
      final cleanTitle = song.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      final cleanArtist = song.artist.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      final fileName = '$cleanTitle - $cleanArtist';
      
      final uri = Uri.parse(song.filePath);
      final ext = uri.path.contains('.mp4') ? '.mp4' : (uri.path.contains('.m4a') ? '.m4a' : '.mp3');
      
      var outputPath = '$outputDir/$fileName$ext';
      var counter = 1;
      while (await File(outputPath).exists()) {
        outputPath = '$outputDir/$fileName ($counter)$ext';
        counter++;
      }

      // 4. Start HTTP client request
      final client = http.Client();
      final request = http.Request('GET', uri);
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Server returned status code ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      var downloadedBytes = 0;
      final file = File(outputPath);
      final sink = file.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0) {
          state = state.copyWith(progress: downloadedBytes / totalBytes);
        }
      });

      await sink.flush();
      await sink.close();
      client.close();

      // 5. Register in local database
      final database = _ref.read(databaseProvider);
      final stat = await file.stat();
      await database.upsertSong(
        SongsCompanion.insert(
          filePath: outputPath,
          title: song.title,
          artist: Value(song.artist),
          album: Value(song.album),
          duration: Value(song.duration),
          fileSize: Value(stat.size),
          albumArtPath: Value(song.albumArtPath),
        ),
      );

      // 6. Refresh library
      _ref.read(libraryProvider.notifier).loadLibrary();
      _ref.invalidate(downloadedSongsProvider);

      state = state.copyWith(
        status: OnlineDownloadStatus.complete,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        status: OnlineDownloadStatus.error,
        errorMessage: e.toString().split('\n').first,
      );
    }
  }

  void reset() {
    state = const OnlineDownloadState();
  }
}

final onlineMusicDownloadProvider =
    StateNotifierProvider<OnlineMusicDownloadNotifier, OnlineDownloadState>((ref) {
  return OnlineMusicDownloadNotifier(ref);
});
