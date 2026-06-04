import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../local_music/presentation/providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/waveform_visualization.dart';

/// Full screen player with clean modern design
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool? _isFavorite;

  Widget _buildPlaceholderArt() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Abstract wave pattern placeholder
        Positioned(
          right: 20,
          top: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'MODERN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'MUSIC',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.3),
          size: 80,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final positionData = ref.watch(positionDataProvider);
    final playerState = ref.watch(playerStateProvider);

    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      body: SafeArea(
        child: currentSong.when(
          data: (song) {
            if (song == null) {
              return const Center(
                child: Text('No song playing'),
              );
            }

            // Initialize favorite status from song if not set
            _isFavorite ??= song.isFavorite;

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (chevron down)
                      Container(
                        decoration: BoxDecoration(
                          color: ThemeConstants.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          iconSize: 28,
                          color: ThemeConstants.textPrimary,
                        ),
                      ),
                      // NOW PLAYING text
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: ThemeConstants.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      // More options button
                      Container(
                        decoration: BoxDecoration(
                          color: ThemeConstants.cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => _showSongOptions(context, song),
                          icon: const Icon(Icons.more_horiz_rounded),
                          iconSize: 24,
                          color: ThemeConstants.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Large Album Art
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: ThemeConstants.tealGradient,
                          borderRadius: BorderRadius.circular(ThemeConstants.radiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: ThemeConstants.tealAccent.withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ThemeConstants.radiusLarge),
                          child: song.albumArtPath != null && song.albumArtPath!.isNotEmpty
                              ? (song.albumArtPath!.startsWith('http')
                                  ? Image.network(
                                      song.albumArtPath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderArt(),
                                    )
                                  : Image.file(
                                      File(song.albumArtPath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderArt(),
                                    ))
                              : _buildPlaceholderArt(),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Song info with heart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: ThemeConstants.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              style: TextStyle(
                                fontSize: 14,
                                color: ThemeConstants.textSecondary,
                              ),
                            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                          ],
                        ),
                      ),
                      // Heart icon
                      IconButton(
                        onPressed: () async {
                          // Toggle local state immediately for UI feedback
                          setState(() {
                            _isFavorite = !(_isFavorite ?? song.isFavorite);
                          });
                          await ref.read(playerStateProvider.notifier).toggleFavorite();
                          ref.read(libraryProvider.notifier).loadLibrary();
                        },
                        icon: Icon(
                          (_isFavorite ?? song.isFavorite) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: (_isFavorite ?? song.isFavorite) ? Colors.red : ThemeConstants.textSecondary,
                        ),
                        iconSize: 28,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Waveform Visualization
                positionData.when(
                  data: (data) {
                    final progress = data.duration.inMilliseconds > 0
                        ? data.position.inMilliseconds / data.duration.inMilliseconds
                        : 0.0;
                    final playing = isPlaying.valueOrNull ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: WaveformVisualization(
                        isPlaying: playing,
                        progress: progress,
                        activeColor: ThemeConstants.primaryColor,
                        inactiveColor: ThemeConstants.cardColorLight,
                        barCount: 40,
                        height: 50,
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 50),
                  error: (_, __) => const SizedBox(height: 50),
                ),

                const SizedBox(height: 16),

                // Progress bar
                positionData.when(
                  data: (data) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        // Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: ThemeConstants.textPrimary,
                            inactiveTrackColor: ThemeConstants.cardColorLight,
                            thumbColor: ThemeConstants.textPrimary,
                          ),
                          child: Slider(
                            value: data.position.inMilliseconds.toDouble(),
                            max: data.duration.inMilliseconds > 0
                                ? data.duration.inMilliseconds.toDouble()
                                : 1,
                            onChanged: (value) {
                              ref
                                  .read(playerStateProvider.notifier)
                                  .seek(Duration(milliseconds: value.toInt()));
                            },
                          ),
                        ),
                        // Time labels
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                Formatters.formatDuration(data.position),
                                style: TextStyle(
                                  color: ThemeConstants.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                Formatters.formatDuration(data.duration),
                                style: TextStyle(
                                  color: ThemeConstants.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // Playback Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle
                      IconButton(
                        onPressed: () {
                          ref.read(playerStateProvider.notifier).toggleShuffle();
                        },
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: playerState.shuffleEnabled
                              ? ThemeConstants.primaryColor
                              : ThemeConstants.textMuted,
                        ),
                        iconSize: 24,
                      ),
                      // Previous
                      IconButton(
                        onPressed: () {
                          ref.read(playerStateProvider.notifier).previous();
                        },
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          color: ThemeConstants.textPrimary,
                        ),
                        iconSize: 36,
                      ),
                      // Play/Pause - Large white circle
                      isPlaying.when(
                        data: (playing) => GestureDetector(
                          onTap: () {
                            ref.read(playerStateProvider.notifier).togglePlay();
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: ThemeConstants.textPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: ThemeConstants.backgroundColor,
                              size: 36,
                            ),
                          ).animate().scale(delay: 200.ms, duration: 300.ms),
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const Icon(Icons.error),
                      ),
                      // Next
                      IconButton(
                        onPressed: () {
                          ref.read(playerStateProvider.notifier).next();
                        },
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          color: ThemeConstants.textPrimary,
                        ),
                        iconSize: 36,
                      ),
                      // Repeat
                      IconButton(
                        onPressed: () {
                          ref.read(playerStateProvider.notifier).cycleRepeatMode();
                        },
                        icon: Icon(
                          playerState.repeatMode == RepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          color: playerState.repeatMode != RepeatMode.off
                              ? ThemeConstants.primaryColor
                              : ThemeConstants.textMuted,
                        ),
                        iconSize: 24,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Bottom bar with queue, lyrics, share
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Queue icon
                      IconButton(
                        onPressed: () {
                          // TODO: Show queue
                        },
                        icon: const Icon(
                          Icons.queue_music_rounded,
                          color: ThemeConstants.textMuted,
                        ),
                        iconSize: 24,
                      ),
                      // LYRICS button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: ThemeConstants.cardColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.subtitles_rounded,
                              color: ThemeConstants.primaryColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'LYRICS',
                              style: TextStyle(
                                color: ThemeConstants.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Share icon
                      IconButton(
                        onPressed: () => ShareService.shareSong(song),
                        icon: const Icon(
                          Icons.share_rounded,
                          color: ThemeConstants.textMuted,
                        ),
                        iconSize: 24,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading player')),
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context, dynamic song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share Song'),
              onTap: () {
                Navigator.pop(context);
                ShareService.shareSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Now Playing'),
              subtitle: const Text('Share what you\'re listening to'),
              onTap: () {
                Navigator.pop(context);
                ShareService.shareSongInfo(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to Playlist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show playlist picker
              },
            ),
          ],
        ),
      ),
    );
  }
}
