import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/share_service.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../local_music/presentation/widgets/song_tile.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../local_music/presentation/providers/library_provider.dart';

/// Provider for favorite songs
final favoriteSongsProvider = FutureProvider<List<Song>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.getFavorites();
});

/// Liked Songs Screen showing all favorite songs
class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteSongs = ref.watch(favoriteSongsProvider);
    final currentSong = ref.watch(currentSongProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, ref, favoriteSongs),

              // Song list
              Expanded(
                child: favoriteSongs.when(
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
                          key: ValueKey('liked_song_${song.id}'),
                          song: song,
                          isPlaying: isCurrentSong,
                          onTap: () {
                            ref.read(playerStateProvider.notifier).playSong(
                                  song,
                                  queue: songs,
                                );
                          },
                          onMoreTap: () => _showSongOptions(context, ref, song),
                        ).animate(delay: Duration(milliseconds: 30 * index.clamp(0, 20)))
                            .fadeIn()
                            .slideX(begin: 0.1, end: 0);
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading favorites')),
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

  Widget _buildHeader(BuildContext context, WidgetRef ref, AsyncValue<List<Song>> favoriteSongs) {
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
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9B7FE6), Color(0xFFB49AFF)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B7FE6).withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Liked Songs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ThemeConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          favoriteSongs.when(
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
          favoriteSongs.when(
            data: (songs) {
              if (songs.isEmpty) return const SizedBox.shrink();
              return ElevatedButton.icon(
                onPressed: () {
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
            Icons.favorite_border_rounded,
            size: 64,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No liked songs yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon to add songs',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, WidgetRef ref, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border_rounded, color: Colors.red),
              title: const Text('Remove from Liked Songs'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(databaseProvider).toggleFavorite(song.id);
                ref.invalidate(favoriteSongsProvider);
                ref.read(libraryProvider.notifier).loadLibrary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ShareService.shareSong(song);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Song song) {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.cardColor,
        title: const Text('Rename Song'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: ThemeConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: artistController,
              decoration: InputDecoration(
                labelText: 'Artist',
                filled: true,
                fillColor: ThemeConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              final newArtist = artistController.text.trim();
              if (newTitle.isNotEmpty) {
                await ref.read(databaseProvider).renameSong(
                  song.id,
                  title: newTitle.isNotEmpty ? newTitle : null,
                  artist: newArtist.isNotEmpty ? newArtist : null,
                );
                ref.invalidate(favoriteSongsProvider);
                ref.read(libraryProvider.notifier).loadLibrary();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Song renamed')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
