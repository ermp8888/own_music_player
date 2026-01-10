import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../player/presentation/providers/player_provider.dart';

/// Playlist state
class PlaylistsState {
  final List<Playlist> playlists;
  final List<Playlist> userPlaylists;
  final List<Playlist> smartPlaylists;
  final bool isLoading;
  final String? errorMessage;

  const PlaylistsState({
    this.playlists = const [],
    this.userPlaylists = const [],
    this.smartPlaylists = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    List<Playlist>? userPlaylists,
    List<Playlist>? smartPlaylists,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      userPlaylists: userPlaylists ?? this.userPlaylists,
      smartPlaylists: smartPlaylists ?? this.smartPlaylists,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Playlists state notifier
class PlaylistsStateNotifier extends StateNotifier<PlaylistsState> {
  final AppDatabase _database;

  PlaylistsStateNotifier(this._database) : super(const PlaylistsState()) {
    loadPlaylists();
  }

  /// Load all playlists
  Future<void> loadPlaylists() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final playlists = await _database.getAllPlaylists();
      final userPlaylists = await _database.getUserPlaylists();
      final smartPlaylists = await _database.getSmartPlaylists();
      
      state = state.copyWith(
        playlists: playlists,
        userPlaylists: userPlaylists,
        smartPlaylists: smartPlaylists,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load playlists: $e',
      );
    }
  }

  /// Create a new playlist
  Future<int> createPlaylist(String name, {String? description}) async {
    try {
      final id = await _database.createPlaylist(name, description: description);
      await loadPlaylists();
      return id;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create playlist: $e');
      return -1;
    }
  }

  /// Update playlist
  Future<void> updatePlaylist(int id, {String? name, String? description}) async {
    try {
      await _database.updatePlaylist(id, name: name, description: description);
      await loadPlaylists();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update playlist: $e');
    }
  }

  /// Delete playlist
  Future<void> deletePlaylist(int id) async {
    try {
      await _database.deletePlaylist(id);
      await loadPlaylists();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete playlist: $e');
    }
  }

  /// Add song to playlist
  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    try {
      await _database.addSongToPlaylist(playlistId, songId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add song: $e');
    }
  }

  /// Remove song from playlist
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    try {
      await _database.removeSongFromPlaylist(playlistId, songId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove song: $e');
    }
  }

  /// Reorder songs in playlist
  Future<void> reorderSongs(int playlistId, List<int> songIds) async {
    try {
      await _database.reorderPlaylistSongs(playlistId, songIds);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to reorder songs: $e');
    }
  }
}

/// Playlists state provider
final playlistsProvider = StateNotifierProvider<PlaylistsStateNotifier, PlaylistsState>((ref) {
  final database = ref.watch(databaseProvider);
  return PlaylistsStateNotifier(database);
});

/// Playlist songs provider
final playlistSongsProvider = FutureProvider.family<List<Song>, int>((ref, playlistId) async {
  final database = ref.watch(databaseProvider);
  return database.getPlaylistSongs(playlistId);
});

/// Playlist songs stream provider
final playlistSongsStreamProvider = StreamProvider.family<List<Song>, int>((ref, playlistId) {
  final database = ref.watch(databaseProvider);
  return database.watchPlaylistSongs(playlistId);
});

/// Single playlist provider
final playlistProvider = FutureProvider.family<Playlist?, int>((ref, playlistId) async {
  final database = ref.watch(databaseProvider);
  return database.getPlaylistById(playlistId);
});
