import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/metadata_cleaner.dart';
import '../../../local_music/presentation/providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/waveform_visualization.dart';
import '../../../../shared/widgets/song_actions_sheet.dart';
import '../../../../core/services/sleep_timer_service.dart';

/// Full screen player with clean modern design
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {

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
    final timerState = ref.watch(sleepTimerProvider);
    final isFavorite = ref.watch(currentSongFavoriteProvider);
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: currentSong.when(
          data: (song) {
            if (song == null) {
              return const Center(
                child: Text('No song playing', style: TextStyle(color: AppTheme.textSecondary)),
              );
            }

            return Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (chevron down)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundCard.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          iconSize: 28,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      // NOW PLAYING text
                      const Text(
                        'NOW PLAYING',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      // More options button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundCard.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                        ),
                        child: IconButton(
                          onPressed: () => showSongActions(context, ref, song),
                          icon: const Icon(Icons.more_horiz_rounded),
                          iconSize: 24,
                          color: AppTheme.textPrimary,
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
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryAccent, AppTheme.primaryAccentLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAccent.withOpacity(0.24),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
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
                              MetadataCleaner.cleanTitle(song.title),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 4),
                            Text(
                              MetadataCleaner.cleanArtist(song.artist),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                          ],
                        ),
                      ),
                       // Heart icon
                      IconButton(
                        onPressed: () async {
                          await ref.read(playerStateProvider.notifier).toggleFavorite();
                          ref.read(libraryProvider.notifier).loadLibrary();
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.redAccent : AppTheme.textSecondary,
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
                        activeColor: AppTheme.primaryAccent,
                        inactiveColor: AppTheme.backgroundCard,
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
                            activeTrackColor: AppTheme.primaryAccent,
                            inactiveTrackColor: AppTheme.backgroundCard,
                            thumbColor: AppTheme.primaryAccent,
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
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                Formatters.formatDuration(data.duration),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
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
                              ? AppTheme.primaryAccent
                              : AppTheme.textDisabled,
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
                          color: AppTheme.textPrimary,
                        ),
                        iconSize: 36,
                      ),
                      // Play/Pause - Large gradient circle
                      isPlaying.when(
                        data: (playing) => GestureDetector(
                          onTap: () {
                            ref.read(playerStateProvider.notifier).togglePlay();
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryAccent, AppTheme.primaryAccentLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.activeShadow,
                            ),
                            child: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
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
                          color: AppTheme.textPrimary,
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
                              ? AppTheme.primaryAccent
                              : AppTheme.textDisabled,
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
                          color: AppTheme.textSecondary,
                        ),
                        iconSize: 24,
                      ),
                      // LYRICS button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundCard.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.subtitles_rounded,
                              color: AppTheme.primaryAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'LYRICS',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sleep Timer icon
                      IconButton(
                        onPressed: () => showSleepTimerSheet(context, ref),
                        icon: Icon(
                          Icons.timer_rounded,
                          color: timerState.isActive
                              ? AppTheme.secondaryAccent
                              : AppTheme.textSecondary,
                        ),
                        iconSize: 24,
                      ),
                      // Share icon
                      IconButton(
                        onPressed: () => ShareService.shareSong(song),
                        icon: const Icon(
                          Icons.share_rounded,
                          color: AppTheme.textSecondary,
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
}
