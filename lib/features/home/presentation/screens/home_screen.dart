import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/animations/scale_tap_animation.dart';
import '../../../local_music/presentation/providers/library_provider.dart';
import '../../../local_music/presentation/screens/library_screen.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../playlists/presentation/screens/playlists_screen.dart';
import '../../../youtube_import/presentation/screens/youtube_import_screen.dart';

/// Home screen with premium dark UI
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final currentSong = ref.watch(currentSongProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      floating: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: ThemeConstants.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'MyMusicApp',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            ref.read(libraryProvider.notifier).scanMusic();
                          },
                          icon: libraryState.isScanning
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),

                    // Hero Player Card
                    SliverToBoxAdapter(
                      child: _buildHeroCard(context, ref, currentSong),
                    ),

                    // Navigation Grid
                    SliverToBoxAdapter(
                      child: _buildNavigationGrid(context),
                    ),

                    // Recently Played
                    if (libraryState.recentlyPlayed.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: SectionHeader(
                          title: 'Recently Played',
                          onSeeAllPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LibraryScreen()),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildRecentlyPlayed(context, ref, libraryState),
                      ),
                    ],

                    // Quick Stats
                    SliverToBoxAdapter(
                      child: _buildQuickStats(context, libraryState),
                    ),

                    // Bottom padding for mini player
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
              // Mini Player
              const MiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      BuildContext context, WidgetRef ref, AsyncValue currentSong) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: currentSong.when(
        data: (song) {
          if (song == null) {
            return GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: ThemeConstants.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.headphones_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to MyMusicApp',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan your music library to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(libraryProvider.notifier).scanMusic();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Scan Music'),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2, end: 0);
          }

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            ),
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: ThemeConstants.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: ThemeConstants.glowShadow,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Now Playing',
                          style: TextStyle(
                            color: ThemeConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: ThemeConstants.textMuted),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNavigationGrid(BuildContext context) {
    final items = [
      _NavItem(
        title: 'Local Songs',
        subtitle: 'Your music library',
        icon: Icons.library_music_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LibraryScreen()),
        ),
      ),
      _NavItem(
        title: 'Playlists',
        subtitle: 'Your collections',
        icon: Icons.playlist_play_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
        ),
      ),
      _NavItem(
        title: 'YouTube Import',
        subtitle: 'Download audio',
        icon: Icons.download_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const YouTubeImportScreen()),
        ),
      ),
      _NavItem(
        title: 'Favorites',
        subtitle: 'Liked songs',
        icon: Icons.favorite_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
        onTap: () {
          // TODO: Navigate to favorites
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildNavCard(items[index], index);
        },
      ),
    );
  }

  Widget _buildNavCard(_NavItem item, int index) {
    return ScaleTapAnimation(
      onTap: item.onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: item.gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: ThemeConstants.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(
          begin: 0.2,
          end: 0,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildRecentlyPlayed(
      BuildContext context, WidgetRef ref, LibraryState state) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.recentlyPlayed.take(10).length,
        itemBuilder: (context, index) {
          final song = state.recentlyPlayed[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ScaleTapAnimation(
              onTap: () {
                ref.read(playerStateProvider.notifier).playSong(
                      song,
                      queue: state.recentlyPlayed,
                    );
              },
              child: SizedBox(
                width: 120,
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: ThemeConstants.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: ThemeConstants.textMuted,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      song.artist,
                      style: TextStyle(
                        color: ThemeConstants.textMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: 50 * index))
              .fadeIn()
              .slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, LibraryState state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              Icons.library_music_rounded,
              '${state.songs.length}',
              'Songs',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: ThemeConstants.glassBorderColor,
            ),
            _buildStatItem(
              context,
              Icons.access_time_rounded,
              '${state.recentlyPlayed.length}',
              'Recently',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: ThemeConstants.glassBorderColor,
            ),
            _buildStatItem(
              context,
              Icons.trending_up_rounded,
              '${state.mostPlayed.length}',
              'Top Played',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String value, String label,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: ThemeConstants.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: ThemeConstants.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  _NavItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });
}
