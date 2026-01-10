import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/services/audio_handler.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import '../../../../main.dart';

/// Mini player widget shown at bottom of screens
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  bool _isDismissed = false;

  void _dismissPlayer() {
    setState(() => _isDismissed = true);
    // Stop the audio
    globalAudioHandler?.stop();
  }

  void _resetDismissed() {
    if (_isDismissed) {
      setState(() => _isDismissed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final positionData = ref.watch(positionDataProvider);

    return currentSong.when(
      data: (song) {
        if (song == null || _isDismissed) return const SizedBox.shrink();
        
        // Reset dismissed state when a new song starts
        _resetDismissed();

        return Dismissible(
          key: ValueKey('mini_player_${song.id}'),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            // Only allow dismiss when paused
            final playing = isPlaying.valueOrNull ?? false;
            if (!playing) {
              _dismissPlayer();
              return true;
            }
            // Show feedback that can't dismiss while playing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pause the song first to dismiss'),
                duration: Duration(seconds: 1),
              ),
            );
            return false;
          },
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.close, color: Colors.red),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.close, color: Colors.red),
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const PlayerScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                ),
              );
            },
            child: GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Album art
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: ThemeConstants.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist,
                              style: TextStyle(
                                color: ThemeConstants.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Controls
                      IconButton(
                        onPressed: () {
                          ref.read(playerStateProvider.notifier).previous();
                        },
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 28,
                      ),
                      isPlaying.when(
                        data: (playing) => Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: ThemeConstants.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              ref.read(playerStateProvider.notifier).togglePlay();
                            },
                            icon: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        loading: () => const SizedBox(
                          width: 42,
                          height: 42,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Icon(Icons.error),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(playerStateProvider.notifier).next();
                        },
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  positionData.when(
                    data: (data) => Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: data.duration.inMilliseconds > 0
                                ? data.position.inMilliseconds /
                                    data.duration.inMilliseconds
                                : 0,
                            backgroundColor: ThemeConstants.cardColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              ThemeConstants.primaryColor,
                            ),
                            minHeight: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.formatDuration(data.position),
                              style: TextStyle(
                                fontSize: 10,
                                color: ThemeConstants.textMuted,
                              ),
                            ),
                            Text(
                              Formatters.formatDuration(data.duration),
                              style: TextStyle(
                                fontSize: 10,
                                color: ThemeConstants.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
