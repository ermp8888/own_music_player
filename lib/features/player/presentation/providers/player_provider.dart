import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/audio_handler.dart';
import '../../../../core/helpers/favorite_helper.dart';

/// Database provider
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Audio handler provider
final audioHandlerProvider = Provider<MyAudioHandler>((ref) {
  throw UnimplementedError('Must be overridden in main');
});

/// Current song provider
final currentSongProvider = StreamProvider<Song?>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  return audioHandler.mediaItem.map((item) {
    if (item == null) return null;
    return audioHandler.currentSong;
  });
});

/// Playing state provider
final isPlayingProvider = StreamProvider<bool>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  return audioHandler.playingStream;
});

/// Position data provider
final positionDataProvider = StreamProvider<PositionData>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  return audioHandler.positionDataStream;
});

/// Playback state provider
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  return audioHandler.playbackState;
});

/// Queue provider
final queueProvider = StreamProvider<List<MediaItem>>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  return audioHandler.queue;
});

/// Player state notifier for controlling playback
class PlayerStateNotifier extends StateNotifier<PlayerState> {
  final MyAudioHandler _audioHandler;
  final AppDatabase _database;

  PlayerStateNotifier(this._audioHandler, this._database)
      : super(const PlayerState());

  /// Play a song from the library
  Future<void> playSong(Song song, {List<Song>? queue, int startIndex = 0}) async {
    final songs = queue ?? [song];
    final index = queue?.indexOf(song) ?? 0;
    
    await _audioHandler.loadPlaylist(songs, startIndex: index);
    await _audioHandler.play();
    
    state = state.copyWith(
      currentQueue: songs,
      currentIndex: index,
    );
  }

  /// Insert a song to play next in the queue
  Future<void> playNext(Song song) async {
    await _audioHandler.playNext(song);
    state = state.copyWith(
      currentQueue: _audioHandler.songs,
      currentIndex: _audioHandler.playbackState.value.queueIndex ?? state.currentIndex,
    );
  }

  /// Play/pause toggle
  Future<void> togglePlay() async {
    if (_audioHandler.playbackState.value.playing) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  /// Skip to next
  Future<void> next() async {
    await _audioHandler.skipToNext();
  }

  /// Skip to previous
  Future<void> previous() async {
    await _audioHandler.skipToPrevious();
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  /// Toggle shuffle
  Future<void> toggleShuffle() async {
    final newState = !state.shuffleEnabled;
    await _audioHandler.setShuffleMode(
      newState ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
    state = state.copyWith(shuffleEnabled: newState);
  }

  /// Cycle repeat mode
  Future<void> cycleRepeatMode() async {
    final modes = [RepeatMode.off, RepeatMode.all, RepeatMode.one];
    final currentIndex = modes.indexOf(state.repeatMode);
    final nextMode = modes[(currentIndex + 1) % modes.length];
    
    await _audioHandler.setRepeatMode(
      nextMode == RepeatMode.off
          ? AudioServiceRepeatMode.none
          : nextMode == RepeatMode.one
              ? AudioServiceRepeatMode.one
              : AudioServiceRepeatMode.all,
    );
    
    state = state.copyWith(repeatMode: nextMode);
  }

  /// Toggle favorite for current song
  Future<void> toggleFavorite() async {
    final currentSong = _audioHandler.currentSong;
    if (currentSong == null) return;

    await FavoriteHelper.toggleFavorite(
      database: _database,
      song: currentSong,
    );
  }
}

/// Player state
class PlayerState {
  final List<Song> currentQueue;
  final int currentIndex;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;

  const PlayerState({
    this.currentQueue = const [],
    this.currentIndex = -1,
    this.shuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
  });

  PlayerState copyWith({
    List<Song>? currentQueue,
    int? currentIndex,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
  }) {
    return PlayerState(
      currentQueue: currentQueue ?? this.currentQueue,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

enum RepeatMode { off, all, one }

/// Player state notifier provider
final playerStateProvider =
    StateNotifierProvider<PlayerStateNotifier, PlayerState>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  final database = ref.watch(databaseProvider);
  return PlayerStateNotifier(audioHandler, database);
});

/// Global mini player dismiss state - shared across all screens
final miniPlayerDismissedProvider = StateProvider<bool>((ref) => false);

/// Favorite status provider for current song - triggers UI updates when favorite changes
final currentSongFavoriteProvider = StateProvider<bool>((ref) => false);
