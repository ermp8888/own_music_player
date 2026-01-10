import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/file_scanner_service.dart';
import '../../../player/presentation/providers/player_provider.dart';

/// Library state
class LibraryState {
  final List<Song> songs;
  final List<Song> recentlyPlayed;
  final List<Song> mostPlayed;
  final bool isLoading;
  final bool isScanning;
  final String? errorMessage;
  final SortOrder sortOrder;

  const LibraryState({
    this.songs = const [],
    this.recentlyPlayed = const [],
    this.mostPlayed = const [],
    this.isLoading = false,
    this.isScanning = false,
    this.errorMessage,
    this.sortOrder = SortOrder.title,
  });

  LibraryState copyWith({
    List<Song>? songs,
    List<Song>? recentlyPlayed,
    List<Song>? mostPlayed,
    bool? isLoading,
    bool? isScanning,
    String? errorMessage,
    SortOrder? sortOrder,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      mostPlayed: mostPlayed ?? this.mostPlayed,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  List<Song> get sortedSongs {
    final sorted = List<Song>.from(songs);
    switch (sortOrder) {
      case SortOrder.title:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOrder.artist:
        sorted.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case SortOrder.album:
        sorted.sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
        break;
      case SortOrder.dateAdded:
        sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortOrder.duration:
        sorted.sort((a, b) => a.duration.compareTo(b.duration));
        break;
    }
    return sorted;
  }
}

enum SortOrder { title, artist, album, dateAdded, duration }

/// Library state notifier
class LibraryStateNotifier extends StateNotifier<LibraryState> {
  final AppDatabase _database;
  final FileScannerService _scanner;

  LibraryStateNotifier(this._database, this._scanner) : super(const LibraryState()) {
    loadLibrary();
  }

  /// Load library from database
  Future<void> loadLibrary() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final songs = await _database.getAllSongs();
      final recentlyPlayed = await _database.getRecentlyPlayed();
      final mostPlayed = await _database.getMostPlayed();
      
      state = state.copyWith(
        songs: songs,
        recentlyPlayed: recentlyPlayed,
        mostPlayed: mostPlayed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load library: $e',
      );
    }
  }

  /// Scan for music files
  Future<void> scanMusic([String? customPath]) async {
    state = state.copyWith(isScanning: true, errorMessage: null);
    try {
      await _scanner.scanMusic(customPath);
      await loadLibrary();
      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Failed to scan music: $e',
      );
    }
  }

  /// Quick rescan for new files only
  Future<void> quickRescan() async {
    state = state.copyWith(isScanning: true, errorMessage: null);
    try {
      await _scanner.quickRescan();
      await loadLibrary();
      state = state.copyWith(isScanning: false);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Failed to rescan: $e',
      );
    }
  }

  /// Remove missing songs
  Future<void> cleanupMissing() async {
    try {
      await _scanner.cleanupMissingSongs();
      await loadLibrary();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to cleanup: $e');
    }
  }

  /// Set sort order
  void setSortOrder(SortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  /// Refresh recently played and most played
  Future<void> refreshSmartPlaylists() async {
    try {
      final recentlyPlayed = await _database.getRecentlyPlayed();
      final mostPlayed = await _database.getMostPlayed();
      state = state.copyWith(
        recentlyPlayed: recentlyPlayed,
        mostPlayed: mostPlayed,
      );
    } catch (e) {
      // Silently fail
    }
  }
}

/// File scanner provider
final fileScannerProvider = Provider<FileScannerService>((ref) {
  final database = ref.watch(databaseProvider);
  return FileScannerService(database);
});

/// Library state provider
final libraryProvider = StateNotifierProvider<LibraryStateNotifier, LibraryState>((ref) {
  final database = ref.watch(databaseProvider);
  final scanner = ref.watch(fileScannerProvider);
  return LibraryStateNotifier(database, scanner);
});

/// Songs stream provider (for real-time updates)
final songsStreamProvider = StreamProvider<List<Song>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchAllSongs();
});
