import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/services/share_service.dart';
import '../../core/helpers/favorite_helper.dart';
import '../../features/local_music/presentation/providers/library_provider.dart';
import '../../features/player/presentation/providers/player_provider.dart';
import '../../features/playlists/presentation/providers/playlist_provider.dart';

/// Shows a bottom sheet with actions for a given song.
void showSongActions(BuildContext context, WidgetRef ref, Song song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.backgroundCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _SongActionsSheet(song: song),
  );
}

class _SongActionsSheet extends ConsumerWidget {
  final Song song;

  const _SongActionsSheet({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Song header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.divider),

            // Actions
            _ActionTile(
              icon: song.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: song.isFavorite ? 'Remove from Liked' : 'Like Song',
              iconColor: song.isFavorite ? Colors.red : null,
              onTap: () async {
                final db = ref.read(databaseProvider);
                final existing = await db.getSongById(song.id);
                final newFavoriteState = existing == null ? true : !existing.isFavorite;
                await FavoriteHelper.toggleFavorite(database: db, song: song);
                ref.read(audioHandlerProvider).updateSongFavoriteState(song.id, newFavoriteState);
                if (context.mounted) Navigator.pop(context);
              },
            ),

            _ActionTile(
              icon: Icons.playlist_add_rounded,
              label: 'Add to Playlist',
              onTap: () {
                Navigator.pop(context);
                _showAddToPlaylistSheet(context, ref, song);
              },
            ),

            _ActionTile(
              icon: Icons.queue_music_rounded,
              label: 'Play Next',
              onTap: () async {
                Navigator.pop(context);
                await ref.read(playerStateProvider.notifier).playNext(song);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${song.title}" will play next'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),

            _ActionTile(
              icon: song.isReported
                  ? Icons.check_circle_outline_rounded
                  : Icons.flag_rounded,
              label: song.isReported
                  ? 'Un-report Song'
                  : 'Report Bad Quality',
              iconColor: song.isReported ? AppTheme.success : AppTheme.warning,
              onTap: () async {
                final db = ref.read(databaseProvider);
                if (song.isReported) {
                   await db.unreportSong(song.id);
                } else {
                   await db.reportSong(song.id);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        song.isReported
                            ? '"${song.title}" un-reported'
                            : '"${song.title}" reported as bad quality',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),

            _ActionTile(
              icon: Icons.edit_rounded,
              label: 'Rename Song',
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, song);
              },
            ),

            _ActionTile(
              icon: Icons.share_rounded,
              label: 'Share Song',
              onTap: () {
                Navigator.pop(context);
                ShareService.shareSong(song);
              },
            ),

            _ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete from Library',
              iconColor: AppTheme.error,
              onTap: () async {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, song);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.textSecondary),
      title: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}

void _showAddToPlaylistSheet(BuildContext context, WidgetRef ref, Song song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.backgroundPrimary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final playlistsState = ref.watch(playlistsProvider);
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to Playlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  title: const Text('Create New Playlist', style: TextStyle(color: AppTheme.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatePlaylistAndAddDialog(context, ref, song);
                  },
                ),
                const Divider(color: AppTheme.divider),
                if (playlistsState.userPlaylists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No playlists yet.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: playlistsState.userPlaylists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlistsState.userPlaylists[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.playlist_play_rounded, color: AppTheme.primaryAccent, size: 24),
                          ),
                          title: Text(
                            playlist.name,
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            await _addSongToSpecificPlaylist(context, ref, playlist, song);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _addSongToSpecificPlaylist(BuildContext context, WidgetRef ref, dynamic playlist, Song song) async {
  try {
    await ref.read(playlistsProvider.notifier).addSongToPlaylist(playlist.id, song.id);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${song.title}" to ${playlist.name}'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to playlist: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

void _showCreatePlaylistAndAddDialog(BuildContext context, WidgetRef ref, Song song) {
  final nameController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.backgroundCard,
      title: const Text('Create Playlist'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Playlist name',
          hintStyle: TextStyle(color: AppTheme.textSecondary),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context);
              final playlistId = await ref.read(playlistsProvider.notifier).createPlaylist(name);
              if (playlistId != -1) {
                final state = ref.read(playlistsProvider);
                final playlist = state.userPlaylists.firstWhere((p) => p.id == playlistId);
                await _addSongToSpecificPlaylist(context, ref, playlist, song);
              }
            }
          },
          child: const Text('Create & Add'),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmation(
    BuildContext context, WidgetRef ref, Song song) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.backgroundCard,
      title: const Text('Delete Song'),
      content: Text(
        'Delete "${song.title}" from your library?\n\n'
        'This removes the song from the database but keeps the file on disk.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final db = ref.read(databaseProvider);
            await db.deleteSongById(song.id);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${song.title}" removed from library'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: const Text('Delete',
              style: TextStyle(color: AppTheme.error)),
        ),
      ],
    ),
  );
}

void _showRenameDialog(BuildContext context, WidgetRef ref, Song song) {
  final titleController = TextEditingController(text: song.title);
  final artistController = TextEditingController(text: song.artist);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.backgroundCard,
      title: const Text('Rename Song'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              filled: true,
              fillColor: AppTheme.backgroundPrimary,
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
              fillColor: AppTheme.backgroundPrimary,
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
              ref.read(libraryProvider.notifier).loadLibrary();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Song renamed')),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
