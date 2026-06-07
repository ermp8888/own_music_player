import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/animations/scale_tap_animation.dart';

import '../../../player/presentation/widgets/mini_player.dart';
import '../providers/playlist_provider.dart';
import 'playlist_detail_screen.dart';

/// Playlists screen
class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsState = ref.watch(playlistsProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Playlists',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCreatePlaylistDialog(context, ref),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),

              // Playlists
              Expanded(
                child: playlistsState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Smart playlists section
                          if (playlistsState.smartPlaylists.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                'Smart Playlists',
                                style: TextStyle(
                                  color: ThemeConstants.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...playlistsState.smartPlaylists
                                .asMap()
                                .entries
                                .map((entry) => _buildPlaylistTile(
                                      context,
                                      ref,
                                      entry.value,
                                      entry.key,
                                      isSmartPlaylist: true,
                                    )),
                            const SizedBox(height: 24),
                          ],

                          // User playlists section
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your Playlists',
                                  style: TextStyle(
                                    color: ThemeConstants.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${playlistsState.userPlaylists.length}',
                                  style: TextStyle(
                                    color: ThemeConstants.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (playlistsState.userPlaylists.isEmpty)
                            _buildEmptyState(context, ref)
                          else
                            ...playlistsState.userPlaylists
                                .asMap()
                                .entries
                                .map((entry) => _buildPlaylistTile(
                                      context,
                                      ref,
                                      entry.value,
                                      entry.key + playlistsState.smartPlaylists.length,
                                    )),
                        ],
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

  Widget _buildPlaylistTile(
    BuildContext context,
    WidgetRef ref,
    dynamic playlist,
    int index, {
    bool isSmartPlaylist = false,
  }) {
    IconData icon;
    List<Color> gradientColors;

    if (isSmartPlaylist) {
      if (playlist.smartPlaylistType == 'recently_played') {
        icon = Icons.history_rounded;
        gradientColors = [AppTheme.blueAccent, AppTheme.blueAccentLight];
      } else {
        icon = Icons.trending_up_rounded;
        gradientColors = [AppTheme.pinkAccent, AppTheme.pinkAccentLight];
      }
    } else {
      icon = Icons.playlist_play_rounded;
      gradientColors = [AppTheme.greenAccent, AppTheme.greenAccentLight];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleTapAnimation(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaylistDetailScreen(
                playlistId: playlist.id,
                isSmartPlaylist: isSmartPlaylist,
              ),
            ),
          );
        },
        onLongPress: isSmartPlaylist
            ? null
            : () => _showPlaylistOptions(context, ref, playlist),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (playlist.description.isNotEmpty)
                      Text(
                        playlist.description,
                        style: TextStyle(
                          color: ThemeConstants.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ThemeConstants.textMuted,
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeConstants.cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.playlist_add_rounded,
                size: 48,
                color: ThemeConstants.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No playlists yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first playlist',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Playlist'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref
                    .read(playlistsProvider.notifier)
                    .createPlaylist(nameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(BuildContext context, WidgetRef ref, dynamic playlist) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: ThemeConstants.errorColor),
              title: const Text(
                'Delete',
                style: TextStyle(color: ThemeConstants.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref, playlist);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, dynamic playlist) {
    final nameController = TextEditingController(text: playlist.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Playlist name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(playlistsProvider.notifier).updatePlaylist(
                      playlist.id,
                      name: nameController.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, dynamic playlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(playlistsProvider.notifier).deletePlaylist(playlist.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConstants.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
