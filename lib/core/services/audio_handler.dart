import 'dart:io' show Platform;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../database/app_database.dart';

/// Background audio handler for media controls integration
class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  late final AudioPlayer _player;
  late final AndroidEqualizer? _equalizer;
  final AppDatabase _database;

  final _playlist = ConcatenatingAudioSource(children: []);
  List<Song> _songs = [];
  int _currentIndex = -1;

  MyAudioHandler(this._database) {
    if (Platform.isAndroid) {
      _equalizer = AndroidEqualizer();
      _player = AudioPlayer(
        audioPipeline: AudioPipeline(
          androidAudioEffects: [_equalizer!],
        ),
      );
    } else {
      _equalizer = null;
      _player = AudioPlayer();
    }
    _init();
  }

  void _init() {
    // Handle playback state changes
    _player.playbackEventStream.listen(_broadcastState);

    // Handle current index changes
    _player.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex) {
        _currentIndex = index;
        if (_songs.isNotEmpty && index < _songs.length) {
          _updateCurrentMediaItem(_songs[index]);
          // Update play count in database
          _database.updatePlayCount(_songs[index].id);
        }
      }
    });

    // Handle player completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // All tracks finished
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.completed,
        ));
      }
    });
  }

  void _updateCurrentMediaItem(Song song) {
    final item = MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.duration),
      artUri: song.albumArtPath != null
          ? (song.albumArtPath!.startsWith('http')
              ? Uri.parse(song.albumArtPath!)
              : Uri.file(song.albumArtPath!))
          : null,
    );
    mediaItem.add(item);
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _currentIndex,
    ));
  }

  /// Load and play a list of songs
  Future<void> loadPlaylist(List<Song> songs, {int startIndex = 0}) async {
    _songs = songs;
    _currentIndex = startIndex;

    await _playlist.clear();
    await _playlist.addAll(
      songs.map((song) {
        if (song.filePath.startsWith('http://') || song.filePath.startsWith('https://')) {
          return AudioSource.uri(Uri.parse(song.filePath));
        } else {
          return AudioSource.file(song.filePath);
        }
      }).toList(),
    );

    // Update queue
    queue.add(songs
        .map((song) => MediaItem(
              id: song.id.toString(),
              title: song.title,
              artist: song.artist,
              album: song.album,
              duration: Duration(milliseconds: song.duration),
              artUri: song.albumArtPath != null
                  ? (song.albumArtPath!.startsWith('http')
                      ? Uri.parse(song.albumArtPath!)
                      : Uri.file(song.albumArtPath!))
                  : null,
            ))
        .toList());

    await _player.setAudioSource(_playlist, initialIndex: startIndex);
    if (songs.isNotEmpty) {
      _updateCurrentMediaItem(songs[startIndex]);
    }
  }

  /// Play a single song
  Future<void> playSong(Song song) async {
    await loadPlaylist([song], startIndex: 0);
    await play();
  }

  /// Insert a song to play next in the queue
  Future<void> playNext(Song song) async {
    // If the queue is empty, just play it
    if (_songs.isEmpty) {
      await loadPlaylist([song], startIndex: 0);
      return;
    }

    final insertIndex = _currentIndex + 1;
    
    // Check if the song is already the next song to avoid duplicate insertion if tapped multiple times
    if (insertIndex < _songs.length && _songs[insertIndex].id == song.id) {
      return;
    }

    // Insert into local song list
    _songs.insert(insertIndex, song);

    // Create AudioSource
    final AudioSource source;
    if (song.filePath.startsWith('http://') || song.filePath.startsWith('https://')) {
      source = AudioSource.uri(Uri.parse(song.filePath));
    } else {
      source = AudioSource.file(song.filePath);
    }

    // Insert into player playlist
    await _playlist.insert(insertIndex, source);

    // Update queue list
    final newQueue = _songs
        .map((s) => MediaItem(
              id: s.id.toString(),
              title: s.title,
              artist: s.artist,
              album: s.album,
              duration: Duration(milliseconds: s.duration),
              artUri: s.albumArtPath != null
                  ? (s.albumArtPath!.startsWith('http')
                      ? Uri.parse(s.albumArtPath!)
                      : Uri.file(s.albumArtPath!))
                  : null,
            ))
        .toList();
    queue.add(newQueue);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _songs.length - 1) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_currentIndex > 0) {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _songs.length) {
      await _player.seek(Duration.zero, index: index);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final shuffleEnabled = shuffleMode == AudioServiceShuffleMode.all;
    await _player.setShuffleModeEnabled(shuffleEnabled);
  }

  /// Get current position stream
  Stream<Duration> get positionStream => _player.positionStream;

  /// Get buffered position stream
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Get duration stream
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Get playing stream
  Stream<bool> get playingStream => _player.playingStream;

  /// Get current index
  int get currentIndex => _currentIndex;

  /// Get current songs list
  List<Song> get songs => _songs;

  /// Get current song
  Song? get currentSong =>
      _currentIndex >= 0 && _currentIndex < _songs.length
          ? _songs[_currentIndex]
          : null;

  /// Combined stream for position, buffered position, and duration
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        positionStream,
        bufferedPositionStream,
        durationStream,
        (position, buffered, duration) =>
            PositionData(position, buffered, duration ?? Duration.zero),
      );

  /// Set playback speed
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  /// Get volume stream
  Stream<double> get volumeStream => _player.volumeStream;

  /// Set volume
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  /// Enable or disable the Android Equalizer effect
  Future<void> setEqualizerEnabled(bool enabled) async {
    if (_equalizer != null) {
      await _equalizer!.setEnabled(enabled);
    }
  }

  /// Set the gain of a specific Android Equalizer frequency band
  Future<void> setEqualizerBandGain(int index, double gain) async {
    if (_equalizer != null) {
      try {
        final params = await _equalizer!.parameters;
        if (params.bands.length > index) {
          await params.bands[index].setGain(gain);
        }
      } catch (e) {
        // Handle or ignore if not initialized
      }
    }
  }

  /// Clean up
  Future<void> dispose() async {
    await _player.dispose();
  }
}

/// Data class for position information
class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
