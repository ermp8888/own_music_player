import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/theme_constants.dart';
import '../providers/player_provider.dart';
import '../screens/player_screen.dart';
import '../../../../main.dart';

/// Mini player widget shown at bottom of screens - simplified design
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer> {
  int? _lastSongId;

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final positionData = ref.watch(positionDataProvider);
    final isDismissed = ref.watch(miniPlayerDismissedProvider);

    return currentSong.when(
      data: (song) {
        if (song == null) return const SizedBox.shrink();
        
        // Reset dismiss state when song changes
        if (_lastSongId != null && _lastSongId != song.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(miniPlayerDismissedProvider.notifier).state = false;
          });
        }
        _lastSongId = song.id;
        
        if (isDismissed) return const SizedBox.shrink();

        return Dismissible(
          key: ValueKey('mini_player_${song.id}'),
          direction: DismissDirection.horizontal,
          confirmDismiss: (direction) async {
            final playing = isPlaying.valueOrNull ?? false;
            if (!playing) {
              // Set global dismiss state
              ref.read(miniPlayerDismissedProvider.notifier).state = true;
              globalAudioHandler?.stop();
              return true;
            }
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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: ThemeConstants.cardColor,
                borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar at top
                  positionData.when(
                    data: (data) => ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(ThemeConstants.radiusMedium),
                      ),
                      child: LinearProgressIndicator(
                        value: data.duration.inMilliseconds > 0
                            ? data.position.inMilliseconds /
                                data.duration.inMilliseconds
                            : 0,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ThemeConstants.primaryColor,
                        ),
                        minHeight: 2,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: [
                        // Album art
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: ThemeConstants.tealGradient,
                            ),
                            child: song.albumArtPath != null && song.albumArtPath!.isNotEmpty
                                ? (song.albumArtPath!.startsWith('http')
                                    ? Image.network(
                                        song.albumArtPath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.music_note_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      )
                                    : Image.file(
                                        File(song.albumArtPath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.music_note_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ))
                                : const Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Song info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: ThemeConstants.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: TextStyle(
                                  color: ThemeConstants.primaryColor,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Queue icon
                        IconButton(
                          onPressed: () {
                            // TODO: Show queue
                          },
                          icon: const Icon(Icons.queue_music_rounded),
                          color: ThemeConstants.textMuted,
                          iconSize: 24,
                        ),
                        // Play/Pause button
                        isPlaying.when(
                          data: (playing) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ThemeConstants.primaryColor,
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
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          loading: () => const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          error: (_, __) => const Icon(Icons.error),
                        ),
                      ],
                    ),
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
