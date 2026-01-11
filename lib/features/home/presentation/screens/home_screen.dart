import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../local_music/presentation/providers/library_provider.dart';
import '../../../local_music/presentation/screens/library_screen.dart';
import '../../../local_music/presentation/screens/recently_played_screen.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../playlists/presentation/screens/playlists_screen.dart';
import '../../../playlists/presentation/screens/liked_songs_screen.dart';
import '../../../youtube_import/presentation/screens/youtube_import_screen.dart';
import '../../../youtube_import/presentation/screens/downloads_screen.dart';
import '../../../../main.dart' show sharedUrlProvider;

/// Provider for YouTube imported songs (songs without local file or with specific source)
final youtubeImportedSongsProvider = FutureProvider<List<dynamic>>((ref) async {
  final database = ref.watch(databaseProvider);
  final allSongs = await database.getAllSongs();
  // Filter songs that were downloaded from YouTube (have specific path pattern)
  return allSongs.where((song) => 
    song.filePath.contains('MyMusicApp') || 
    song.filePath.contains('YouTube') ||
    song.filePath.contains('Download')
  ).toList();
});

/// Home screen with premium dark UI and bottom navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkSharedUrl();
  }

  void _checkSharedUrl() {
    // Check if there's a shared URL and navigate to YouTube Import
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sharedUrl = ref.read(sharedUrlProvider);
      if (sharedUrl != null && sharedUrl.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const YouTubeImportScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for shared URL changes
    ref.listen<String?>(sharedUrlProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const YouTubeImportScreen()),
        );
      }
    });

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _buildCurrentPage(),
              ),
              // Mini Player
              const MiniPlayer(),
              // Bottom Navigation
              BottomNavBar(
                currentIndex: _currentNavIndex,
                onTap: (index) {
                  if (index == 2) {
                    // Library tab - navigate to LibraryScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LibraryScreen()),
                    );
                  } else {
                    setState(() => _currentNavIndex = index);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentNavIndex) {
      case 0:
        return _HomeContent();
      case 1:
        return _ExplorePage();
      case 3:
        return _SettingsPage();
      default:
        return _HomeContent();
    }
  }
}

/// Home content with greeting, YouTube Import card, and sections
class _HomeContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);

    return CustomScrollView(
      slivers: [
        // Header with greeting
        SliverToBoxAdapter(
          child: _buildHeader(context, ref),
        ),

        // YouTube Import Promo Card
        SliverToBoxAdapter(
          child: _buildYouTubeImportCard(context),
        ),

        // Recently Played Section
        SliverToBoxAdapter(
          child: _buildSectionHeader('Recently Played', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecentlyPlayedScreen()),
            );
          }),
        ),
        SliverToBoxAdapter(
          child: _buildRecentlyPlayed(context, ref, libraryState),
        ),

        // Jump Back In Section
        SliverToBoxAdapter(
          child: _buildJumpBackInSection(context, ref),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ThemeConstants.tealGradient,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Greeting
          const Expanded(
            child: Text(
              'Welcome to DownTune',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ThemeConstants.textPrimary,
              ),
            ),
          ),
          // Search icon
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibraryScreen()),
              );
            },
            icon: const Icon(Icons.search_rounded),
            color: ThemeConstants.textPrimary,
          ),
          // Notification icon
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            color: ThemeConstants.textPrimary,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildYouTubeImportCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const YouTubeImportScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: ThemeConstants.youtubeImportGradient,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusLarge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // YouTube icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  // NEW FEATURE badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ThemeConstants.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NEW FEATURE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'YouTube Import',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sync your playlists and videos directly to your library.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              // Import Now button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
                ),
                child: const Center(
                  child: Text(
                    'Import Now',
                    style: TextStyle(
                      color: Color(0xFF4D5BD4),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeConstants.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                fontSize: 14,
                color: ThemeConstants.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayed(BuildContext context, WidgetRef ref, LibraryState state) {
    // Show all songs if no recently played, otherwise show recently played
    final songsToShow = state.recentlyPlayed.isNotEmpty 
        ? state.recentlyPlayed 
        : state.songs;
    
    if (songsToShow.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: ThemeConstants.cardColor,
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note_rounded, color: ThemeConstants.textMuted, size: 32),
                const SizedBox(height: 8),
                Text(
                  'No songs yet. Scan your library!',
                  style: TextStyle(color: ThemeConstants.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songsToShow.take(10).length,
        itemBuilder: (context, index) {
          final song = songsToShow[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                // Reset mini player dismissed state when playing a new song
                ref.read(miniPlayerDismissedProvider.notifier).state = false;
                ref.read(playerStateProvider.notifier).playSong(
                      song,
                      queue: songsToShow,
                    );
              },
              child: SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album art
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        gradient: _getAlbumGradient(index),
                        borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 40,
                          ),
                          if (song.isFavorite)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.favorite_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: ThemeConstants.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: TextStyle(
                        color: ThemeConstants.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }

  LinearGradient _getAlbumGradient(int index) {
    final gradients = [
      ThemeConstants.tealGradient,
      const LinearGradient(colors: [Color(0xFFF5A962), Color(0xFFE8945A)]),
      ThemeConstants.cardGradient,
      ThemeConstants.primaryGradient,
    ];
    return gradients[index % gradients.length];
  }

  Widget _buildJumpBackInSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jump Back In',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Use Row with Expanded for equal sizing
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  context,
                  icon: Icons.favorite_rounded,
                  label: 'Liked Songs',
                  color: const Color(0xFF9B7FE6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LikedSongsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessButton(
                  context,
                  icon: Icons.playlist_play_rounded,
                  label: 'Playlists',
                  color: ThemeConstants.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessButton(
                  context,
                  icon: Icons.download_rounded,
                  label: 'Downloads',
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildQuickAccessButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: ThemeConstants.cardColor,
          borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Explore page placeholder
class _ExplorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_rounded,
            size: 64,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Explore',
            style: TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              color: ThemeConstants.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings page placeholder
class _SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.settings_rounded,
            size: 64,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              color: ThemeConstants.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
