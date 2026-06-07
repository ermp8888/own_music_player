import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Playlists',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCreatePlaylistDialog(context, ref),
                      icon: const Icon(Icons.add_rounded, color: AppTheme.primaryAccentLight),
                      iconSize: 28,
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
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                'Smart Playlists',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
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
                                const Text(
                                  'Your Playlists',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${playlistsState.userPlaylists.length}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
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
                  borderRadius: BorderRadius.circular(AppTheme.thumbnailRadius),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (playlist.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          playlist.description,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textSecondary,
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
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard.withOpacity(0.6),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.playlist_add_rounded,
                size: 48,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No playlists yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first playlist',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryAccent,
              ),
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
        backgroundColor: AppTheme.backgroundSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: const BorderSide(color: AppTheme.divider),
        ),
        title: const Text(
          'Create Playlist',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
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
      backgroundColor: AppTheme.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.textSecondary),
              title: const Text('Rename', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, ref, playlist);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.warning),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.warning),
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
        backgroundColor: AppTheme.backgroundSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: const BorderSide(color: AppTheme.divider),
        ),
        title: const Text(
          'Rename Playlist',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
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
        backgroundColor: AppTheme.backgroundSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: const BorderSide(color: AppTheme.divider),
        ),
        title: const Text(
          'Delete Playlist',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
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
              backgroundColor: AppTheme.warning,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
