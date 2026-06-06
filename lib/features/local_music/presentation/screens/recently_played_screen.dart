import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../widgets/song_tile.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../player/presentation/widgets/mini_player.dart';

/// Provider for recently played songs only
final recentlyPlayedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.getRecentlyPlayed(limit: 50);
});

/// Recently Played Screen showing only recently played songs
class RecentlyPlayedScreen extends ConsumerWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentSongs = ref.watch(recentlyPlayedSongsProvider);
    final currentSong = ref.watch(currentSongProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, ref, recentSongs),

              // Song list
              Expanded(
                child: recentSongs.when(
                  data: (songs) {
                    if (songs.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        final isCurrentSong = currentSong.whenOrNull(
                              data: (current) => current?.id == song.id,
                            ) ??
                            false;

                        return SongTile(
                          key: ValueKey('recent_song_${song.id}'),
                          song: song,
                          isPlaying: isCurrentSong,
                          onTap: () {
                            ref.read(miniPlayerDismissedProvider.notifier).state = false;
                            ref.read(playerStateProvider.notifier).playSong(
                                  song,
                                  queue: songs,
                                );
                          },
                        ).animate(delay: Duration(milliseconds: 30 * index.clamp(0, 20)))
                            .fadeIn()
                            .slideX(begin: 0.1, end: 0);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading songs')),
                ),
              ),

              // Mini player
              const MiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AsyncValue<List<Song>> recentSongs) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  ref.invalidate(recentlyPlayedSongsProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: ThemeConstants.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: ThemeConstants.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recently Played',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          recentSongs.when(
            data: (songs) => Text(
              '${songs.length} songs',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 14,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          recentSongs.when(
            data: (songs) {
              if (songs.isEmpty) return const SizedBox.shrink();
              return ElevatedButton.icon(
                onPressed: () {
                  ref.read(miniPlayerDismissedProvider.notifier).state = false;
                  ref.read(playerStateProvider.notifier).playSong(
                        songs.first,
                        queue: songs,
                      );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play All'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No recently played songs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start playing some music!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
