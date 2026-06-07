import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/metadata_cleaner.dart';
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
            backgroundColor: AppTheme.secondaryAccent,
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(onlineMusicDownloadProvider.notifier).reset();
      } else if (next.status == OnlineDownloadStatus.error) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download: ${next.errorMessage}'),
            backgroundColor: AppTheme.warning,
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
                  const Text(
                    'Explore Online',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Search & stream the latest Bollywood hits online',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),


            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search songs, artists, or movies...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(onlineMusicSearchQueryProvider.notifier).state = '';
                            setState(() {});
                          },
                        ),
                      IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                        color: _isListening ? AppTheme.primaryAccent : AppTheme.textSecondary,
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

            // Quick Tags Scroll
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                              ? AppTheme.primaryAccent
                              : AppTheme.backgroundCard,
                          borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppTheme.divider,
                          ),
                          boxShadow: isSelected ? AppTheme.activeShadow : null,
                        ),
                        child: Center(
                          child: Text(
                            tag['label']!,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

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
        children: const [
          Icon(
            Icons.music_off_rounded,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No songs found',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: TextStyle(
              color: AppTheme.textSecondary,
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
              color: AppTheme.warning,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load music',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection or try again later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
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
                backgroundColor: AppTheme.primaryAccent,
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
          baseColor: AppTheme.backgroundCard,
          highlightColor: AppTheme.backgroundSurface,
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
                ? AppTheme.primaryAccent.withOpacity(0.12)
                : AppTheme.backgroundCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(AppTheme.thumbnailRadius),
            border: Border.all(
              color: isPlayingCurrent
                  ? AppTheme.primaryAccent.withOpacity(0.3)
                  : AppTheme.divider.withOpacity(0.5),
            ),
            boxShadow: isPlayingCurrent ? [
              BoxShadow(
                color: AppTheme.primaryAccent.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
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
                            color: AppTheme.backgroundCard,
                            child: const Icon(Icons.music_note_rounded, color: AppTheme.textDisabled),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.backgroundCard,
                            child: const Icon(Icons.music_note_rounded, color: AppTheme.textDisabled),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: AppTheme.backgroundCard,
                          child: const Icon(Icons.music_note_rounded, color: AppTheme.textDisabled),
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
              MetadataCleaner.cleanTitle(song.title),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isPlayingCurrent ? AppTheme.primaryAccent : AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${MetadataCleaner.cleanArtist(song.artist)} • ${song.album}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
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
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: AppTheme.textSecondary,
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
              leading: const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryAccent),
              title: const Text('Play Now', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                ref.read(playerStateProvider.notifier).playSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: AppTheme.textPrimary),
              title: const Text('Download Song', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showDownloadLocationDialog(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: AppTheme.textPrimary),
              title: const Text('Add to Playlist', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showPlaylistSelectionSheet(context, song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: AppTheme.textPrimary),
              title: const Text('Share Song', style: TextStyle(color: AppTheme.textPrimary)),
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
      backgroundColor: AppTheme.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose where to save "${song.title}"',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.folder_rounded, color: AppTheme.primaryAccent),
              title: const Text('Save to Default Folder', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text(
                defaultLocation.split('/').last.isEmpty ? 'MyMusicApp' : defaultLocation.split('/').last,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(onlineMusicDownloadProvider.notifier).downloadSong(song);
              },
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_rounded, color: AppTheme.primaryAccent),
              title: const Text('Choose Custom Folder...', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: const Text('Pick any directory on your device', style: TextStyle(color: AppTheme.textSecondary)),
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
                      backgroundColor: AppTheme.warning,
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
      backgroundColor: AppTheme.backgroundPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final playlistsState = ref.watch(playlistsProvider);
            return Container(
              padding: const EdgeInsets.all(24),
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
                                color: AppTheme.primaryAccent.withOpacity(0.1),
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
            backgroundColor: AppTheme.secondaryAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to playlist: $e'),
          backgroundColor: AppTheme.warning,
        ),
      );
    }
  }

  void _showCreatePlaylistAndAddDialog(BuildContext context, WidgetRef ref, Song song) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        title: const Text('Create Playlist', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
            ),
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
