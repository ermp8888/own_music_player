import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../local_music/presentation/providers/library_provider.dart';
import '../../../local_music/presentation/widgets/song_tile.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../providers/playlist_provider.dart';

/// Playlist detail screen showing songs in a playlist
class PlaylistDetailScreen extends ConsumerWidget {
  final int playlistId;
  final bool isSmartPlaylist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.isSmartPlaylist = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistProvider(playlistId));
    final songs = ref.watch(playlistSongsStreamProvider(playlistId));
    final currentSong = ref.watch(currentSongProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              playlist.when(
                data: (pl) {
                  if (pl == null) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Playlist not found'),
                    );
                  }
                  return _buildHeader(context, ref, pl, songs);
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error loading playlist'),
              ),

              // Song list
              Expanded(
                child: songs.when(
                  data: (songList) {
                    if (songList.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: songList.length,
                      onReorder: isSmartPlaylist
                          ? (_, __) {}
                          : (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex--;
                              final songIds =
                                  songList.map((s) => s.id).toList();
                              final item = songIds.removeAt(oldIndex);
                              songIds.insert(newIndex, item);
                              ref
                                  .read(playlistsProvider.notifier)
                                  .reorderSongs(playlistId, songIds);
                            },
                      itemBuilder: (context, index) {
                        final song = songList[index];
                        final isCurrentSong = currentSong.whenOrNull(
                              data: (current) => current?.id == song.id,
                            ) ??
                            false;

                        return SongTile(
                          key: ValueKey('song_${song.id}'),
                          song: song,
                          isPlaying: isCurrentSong,
                          onTap: () {
                            ref.read(playerStateProvider.notifier).playSong(
                                  song,
                                  queue: songList,
                                );
                          },
                          trailing: isSmartPlaylist
                              ? null
                              : ReorderableDragStartListener(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: ThemeConstants.textMuted,
                                    ),
                                  ),
                                ),
                          onMoreTap: isSmartPlaylist
                              ? null
                              : () => _showSongOptions(
                                    context,
                                    ref,
                                    song,
                                  ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error')),
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

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic playlist,
    AsyncValue songs,
  ) {
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
              if (!isSmartPlaylist)
                IconButton(
                  onPressed: () => _showAddSongsDialog(context, ref),
                  icon: const Icon(Icons.add_rounded),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: isSmartPlaylist
                  ? ThemeConstants.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: ThemeConstants.glowShadow,
            ),
            child: Icon(
              isSmartPlaylist
                  ? (playlist.smartPlaylistType == 'recently_played'
                      ? Icons.history_rounded
                      : Icons.trending_up_rounded)
                  : Icons.playlist_play_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            playlist.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          songs.when(
            data: (songList) => Text(
              '${songList.length} songs',
              style: TextStyle(
                color: ThemeConstants.textSecondary,
                fontSize: 14,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          songs.when(
            data: (songList) {
              if (songList.isEmpty) return const SizedBox.shrink();
              return ElevatedButton.icon(
                onPressed: () {
                  ref.read(playerStateProvider.notifier).playSong(
                        songList.first,
                        queue: songList,
                      );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play All'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
            Icons.music_off_rounded,
            size: 64,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isSmartPlaylist ? 'No songs yet' : 'Playlist is empty',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isSmartPlaylist
                ? 'Start playing some music!'
                : 'Add songs to this playlist',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, WidgetRef ref, dynamic song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove from playlist'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(playlistsProvider.notifier)
                    .removeSongFromPlaylist(playlistId, song.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSongsDialog(BuildContext context, WidgetRef ref) {
    final libraryState = ref.read(libraryProvider);
    final selectedSongIds = <int>{};
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredSongs = searchQuery.isEmpty
              ? libraryState.songs
              : libraryState.songs.where((song) {
                  final query = searchQuery.toLowerCase();
                  return song.title.toLowerCase().contains(query) ||
                      song.artist.toLowerCase().contains(query);
                }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: ThemeConstants.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Songs (${selectedSongIds.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: selectedSongIds.isEmpty
                          ? null
                          : () async {
                              for (final songId in selectedSongIds) {
                                await ref
                                    .read(playlistsProvider.notifier)
                                    .addSongToPlaylist(playlistId, songId);
                              }
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Added ${selectedSongIds.length} songs',
                                  ),
                                ),
                              );
                            },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Search box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: ThemeConstants.cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setModalState(() => searchQuery = value),
                ),
              ),
              // Song list
              Expanded(
                child: filteredSongs.isEmpty
                    ? Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? 'No songs available'
                              : 'No songs found',
                          style: TextStyle(color: ThemeConstants.textMuted),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          final isSelected = selectedSongIds.contains(song.id);

                          return ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: ThemeConstants.cardGradient,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.music_note_rounded,
                                color: ThemeConstants.textMuted,
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ThemeConstants.textMuted,
                              ),
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setModalState(() {
                                  if (value == true) {
                                    selectedSongIds.add(song.id);
                                  } else {
                                    selectedSongIds.remove(song.id);
                                  }
                                });
                              },
                            ),
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedSongIds.remove(song.id);
                                } else {
                                  selectedSongIds.add(song.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }
}
