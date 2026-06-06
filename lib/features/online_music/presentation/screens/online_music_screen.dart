import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../providers/online_music_provider.dart';
import '../../../playlists/presentation/providers/playlist_provider.dart';
import '../../../../core/services/share_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import '../../../../core/providers/download_location_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class OnlineMusicScreen extends ConsumerStatefulWidget {
  const OnlineMusicScreen({super.key});

  @override
  ConsumerState<OnlineMusicScreen> createState() => _OnlineMusicScreenState();
}

class _OnlineMusicScreenState extends ConsumerState<OnlineMusicScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  final List<Map<String, String>> _quickTags = [
    {'label': '🔥 Latest Hits', 'query': 'latest bollywood'},
    {'label': '💖 Romantic', 'query': 'hindi romantic hits'},
    {'label': '🕺 Party / Dance', 'query': 'hindi dance hits'},
    {'label': '🎧 Lo-Fi / Sad', 'query': 'hindi lofi'},
    {'label': '✨ Classic Gold', 'query': 'hindi old hits'},
    {'label': '🎹 Devotional', 'query': 'hindi bhajan'},
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Initialize controller text with the current provider query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(onlineMusicSearchQueryProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTagTapped(String query) {
    _searchController.text = query;
    ref.read(onlineMusicSearchQueryProvider.notifier).state = query;
    _searchFocusNode.unfocus();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(onlineMusicSearchQueryProvider.notifier).state = query;
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _searchController.text = val.recognizedWords;
            if (val.recognizedWords.isNotEmpty) {
              ref.read(onlineMusicSearchQueryProvider.notifier).state = val.recognizedWords;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OnlineDownloadState>(onlineMusicDownloadProvider, (previous, next) {
      if (next.status == OnlineDownloadStatus.downloading && previous?.status != OnlineDownloadStatus.downloading) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Downloading "${next.songTitle}"...'),
                ),
              ],
            ),
            duration: const Duration(days: 1), // Keep it open until finished
          ),
        );
      } else if (next.status == OnlineDownloadStatus.complete) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${next.songTitle}" downloaded successfully!'),
            backgroundColor: ThemeConstants.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(onlineMusicDownloadProvider.notifier).reset();
      } else if (next.status == OnlineDownloadStatus.error) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${next.errorMessage}'),
            backgroundColor: ThemeConstants.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(onlineMusicDownloadProvider.notifier).reset();
      }
    });

    final songsAsync = ref.watch(onlineMusicSongsProvider);
    final activeQuery = ref.watch(onlineMusicSearchQueryProvider);
    final currentPlayingSongValue = ref.watch(currentSongProvider);
    final currentPlayingSong = currentPlayingSongValue.valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Online',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search & stream the latest Bollywood hits online',
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GlassContainer(
                borderRadius: ThemeConstants.radiusMedium,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: ThemeConstants.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists, or movies...',
                    hintStyle: TextStyle(color: ThemeConstants.textMuted),
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: ThemeConstants.primaryColor),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            color: ThemeConstants.textMuted,
                            onPressed: () {
                              _searchController.clear();
                              ref.read(onlineMusicSearchQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                          ),
                        IconButton(
                          icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                          color: _isListening ? ThemeConstants.primaryColor : ThemeConstants.textMuted,
                          onPressed: _listen,
                        ),
                      ],
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {});
                  },
                  onSubmitted: _onSearchSubmitted,
                ),
              ),
            ),

            // Quick Tags Scroll
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _quickTags.length,
                itemBuilder: (context, index) {
                  final tag = _quickTags[index];
                  final isSelected = activeQuery == tag['query'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _onTagTapped(tag['query']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ThemeConstants.primaryColor
                              : ThemeConstants.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? ThemeConstants.primaryColor
                                : ThemeConstants.glassBorderColor,
                          ),
                        ),
                        child: Text(
                          tag['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : ThemeConstants.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // Songs List
            Expanded(
              child: songsAsync.when(
                data: (songs) {
                  if (songs.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildSongsList(songs, currentPlayingSong);
                },
                loading: () => _buildShimmerLoading(),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No songs found',
            style: TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: TextStyle(
              color: ThemeConstants.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load music',
              style: TextStyle(
                color: ThemeConstants.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection or try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ThemeConstants.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(onlineMusicSongsProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: ThemeConstants.cardColor,
          highlightColor: ThemeConstants.cardColorLight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongsList(List<Song> songs, Song? currentPlayingSong) {
    return ListView.builder(
      itemCount: songs.length,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      itemBuilder: (context, index) {
        final song = songs[index];
        final isPlayingCurrent = currentPlayingSong?.filePath == song.filePath;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isPlayingCurrent
                ? ThemeConstants.primaryColor.withValues(alpha: 0.15)
                : ThemeConstants.cardColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPlayingCurrent
                  ? ThemeConstants.primaryColor.withValues(alpha: 0.4)
                  : ThemeConstants.glassBorderColor,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.albumArtPath != null && song.albumArtPath!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.albumArtPath!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: ThemeConstants.cardColor,
                            child: const Icon(Icons.music_note_rounded, color: Colors.white24),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: ThemeConstants.cardColor,
                            child: const Icon(Icons.music_note_rounded, color: Colors.white24),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: ThemeConstants.cardColor,
                          child: const Icon(Icons.music_note_rounded, color: Colors.white24),
                        ),
                ),
                if (isPlayingCurrent)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
              ],
            ),
            title: Text(
              song.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isPlayingCurrent ? ThemeConstants.primaryColor : ThemeConstants.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${song.artist} • ${song.album}',
              style: TextStyle(
                fontSize: 12,
                color: ThemeConstants.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display song duration
                Text(
                  _formatDuration(song.duration),
                  style: TextStyle(
                    fontSize: 11,
                    color: ThemeConstants.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: ThemeConstants.textMuted,
                  onPressed: () => _showOnlineSongOptions(context, song),
                ),
              ],
            ),
            onTap: () {
              ref.read(playerStateProvider.notifier).playSong(
                    song,
                    queue: songs,
                    startIndex: index,
                  );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showOnlineSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow_rounded, color: ThemeConstants.primaryColor),
              title: const Text('Play Now', style: TextStyle(color: ThemeConstants.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                ref.read(playerStateProvider.notifier).playSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: ThemeConstants.textPrimary),
              title: const Text('Download Song', style: TextStyle(color: ThemeConstants.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showDownloadLocationDialog(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: ThemeConstants.textPrimary),
              title: const Text('Add to Playlist', style: TextStyle(color: ThemeConstants.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showPlaylistSelectionSheet(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: ThemeConstants.textPrimary),
              title: const Text('Share Song', style: TextStyle(color: ThemeConstants.textPrimary)),
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

  void _showDownloadLocationDialog(BuildContext context, Song song) {
    final defaultLocation = ref.read(downloadLocationProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeConstants.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ThemeConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose where to save "${song.title}"',
              style: const TextStyle(
                fontSize: 14,
                color: ThemeConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.folder_rounded, color: ThemeConstants.primaryColor),
              title: const Text('Save to Default Folder', style: TextStyle(color: ThemeConstants.textPrimary)),
              subtitle: Text(
                defaultLocation.split('/').last.isEmpty ? 'MyMusicApp' : defaultLocation.split('/').last,
                style: const TextStyle(color: ThemeConstants.textMuted),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(onlineMusicDownloadProvider.notifier).downloadSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_rounded, color: ThemeConstants.primaryColor),
              title: const Text('Choose Custom Folder...', style: TextStyle(color: ThemeConstants.textPrimary)),
              subtitle: const Text('Pick any directory on your device', style: TextStyle(color: ThemeConstants.textMuted)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final result = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: 'Select Save Folder',
                  );
                  if (result != null && result.isNotEmpty) {
                    ref.read(onlineMusicDownloadProvider.notifier).downloadSong(song, customPath: result);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not access folder picker'),
                      backgroundColor: ThemeConstants.errorColor,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSelectionSheet(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThemeConstants.backgroundColor,
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
                      color: ThemeConstants.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: ThemeConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                    title: const Text('Create New Playlist', style: TextStyle(color: ThemeConstants.textPrimary)),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreatePlaylistAndAddDialog(context, ref, song);
                    },
                  ),
                  const Divider(color: ThemeConstants.glassBorderColor),
                  if (playlistsState.userPlaylists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No playlists yet.',
                          style: TextStyle(color: ThemeConstants.textMuted),
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
                                color: ThemeConstants.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.playlist_play_rounded, color: ThemeConstants.primaryColor, size: 24),
                            ),
                            title: Text(
                              playlist.name,
                              style: const TextStyle(color: ThemeConstants.textPrimary),
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
      final database = ref.read(databaseProvider);
      
      // 1. Ensure the song is registered in the database
      var dbSong = await database.getSongByPath(song.filePath);
      if (dbSong == null) {
        final id = await database.upsertSong(
          SongsCompanion.insert(
            filePath: song.filePath,
            title: song.title,
            artist: Value(song.artist),
            album: Value(song.album),
            duration: Value(song.duration),
            albumArtPath: Value(song.albumArtPath),
          ),
        );
        dbSong = await database.getSongById(id);
      }
      
      if (dbSong != null) {
        // 2. Add to playlist
        await ref.read(playlistsProvider.notifier).addSongToPlaylist(playlist.id, dbSong.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${song.title}" to ${playlist.name}'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to playlist: $e'),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    }
  }

  void _showCreatePlaylistAndAddDialog(BuildContext context, WidgetRef ref, Song song) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeConstants.cardColor,
        title: const Text('Create Playlist'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: ThemeConstants.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: ThemeConstants.textMuted),
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
}
