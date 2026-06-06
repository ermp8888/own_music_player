import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/theme_constants.dart';

import '../../../../shared/widgets/gradient_background.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/library_provider.dart';
import '../widgets/song_tile.dart';
import '../../../../shared/widgets/song_actions_sheet.dart';

/// Library screen showing all local songs with search
class LibraryScreen extends ConsumerStatefulWidget {
  final bool isTab;
  const LibraryScreen({super.key, this.isTab = false});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    final currentSong = ref.watch(currentSongProvider);

    // Filter songs based on search query
    final filteredSongs = _searchQuery.isEmpty
        ? libraryState.sortedSongs
        : libraryState.sortedSongs.where((song) {
            final query = _searchQuery.toLowerCase();
            return song.title.toLowerCase().contains(query) ||
                song.artist.toLowerCase().contains(query) ||
                song.album.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App bar with search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    if (!widget.isTab || _isSearching)
                      IconButton(
                        onPressed: () {
                          if (_isSearching) {
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: Icon(_isSearching ? Icons.close : Icons.arrow_back_rounded),
                      ),
                    Expanded(
                      child: _isSearching
                          ? TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search songs...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: ThemeConstants.textMuted),
                                suffixIcon: IconButton(
                                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                                  color: _isListening ? ThemeConstants.primaryColor : ThemeConstants.textMuted,
                                  onPressed: _listen,
                                ),
                              ),
                              style: const TextStyle(fontSize: 18),
                              onChanged: (value) => setState(() => _searchQuery = value),
                            )
                          : const Text(
                              'Local Songs',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    // Search button
                    if (!_isSearching)
                      IconButton(
                        onPressed: () => setState(() => _isSearching = true),
                        icon: const Icon(Icons.search_rounded),
                      ),
                    // Sort button
                    if (!_isSearching)
                      PopupMenuButton<SortOrder>(
                        icon: const Icon(Icons.sort_rounded),
                        onSelected: (order) {
                          ref.read(libraryProvider.notifier).setSortOrder(order);
                        },
                        itemBuilder: (context) => [
                          _buildSortMenuItem(
                            SortOrder.title,
                            'Title',
                            Icons.sort_by_alpha,
                            libraryState.sortOrder,
                          ),
                          _buildSortMenuItem(
                            SortOrder.artist,
                            'Artist',
                            Icons.person,
                            libraryState.sortOrder,
                          ),
                          _buildSortMenuItem(
                            SortOrder.album,
                            'Album',
                            Icons.album,
                            libraryState.sortOrder,
                          ),
                          _buildSortMenuItem(
                            SortOrder.dateAdded,
                            'Date Added',
                            Icons.calendar_today,
                            libraryState.sortOrder,
                          ),
                          _buildSortMenuItem(
                            SortOrder.duration,
                            'Duration',
                            Icons.timer,
                            libraryState.sortOrder,
                          ),
                        ],
                      ),
                    // Scan button
                    if (!_isSearching)
                      IconButton(
                        onPressed: libraryState.isScanning
                            ? null
                            : () {
                                ref.read(libraryProvider.notifier).scanMusic();
                              },
                        icon: libraryState.isScanning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded),
                      ),
                  ],
                ),
              ),

              // Stats bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      _searchQuery.isEmpty
                          ? '${libraryState.songs.length} songs'
                          : '${filteredSongs.length} results',
                      style: TextStyle(
                        color: ThemeConstants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    // Play all button
                    if (filteredSongs.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          ref.read(playerStateProvider.notifier).playSong(
                                filteredSongs.first,
                                queue: filteredSongs,
                              );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: ThemeConstants.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        label: const Text('Play All'),
                      ),
                  ],
                ),
              ),

              // Song list
              Expanded(
                child: libraryState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : libraryState.songs.isEmpty
                        ? _buildEmptyState(context, ref)
                        : filteredSongs.isEmpty
                            ? _buildNoResultsState()
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: filteredSongs.length,
                                itemBuilder: (context, index) {
                                  final song = filteredSongs[index];
                                  final isCurrentSong = currentSong.whenOrNull(
                                        data: (current) => current?.id == song.id,
                                      ) ??
                                      false;

                                  return SongTile(
                                    song: song,
                                    isPlaying: isCurrentSong,
                                    onTap: () {
                                      ref.read(playerStateProvider.notifier).playSong(
                                            song,
                                            queue: filteredSongs,
                                          );
                                    },
                                    onMoreTap: () {
                                      showSongActions(context, ref, song);
                                    },
                                  )
                                      .animate(delay: Duration(milliseconds: 30 * index.clamp(0, 20)))
                                      .fadeIn()
                                      .slideX(begin: 0.1, end: 0);
                                },
                              ),
              ),

              // Mini player
              if (!widget.isTab) const MiniPlayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: ThemeConstants.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No songs found',
            style: TextStyle(
              color: ThemeConstants.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: ThemeConstants.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortOrder> _buildSortMenuItem(
    SortOrder order,
    String label,
    IconData icon,
    SortOrder current,
  ) {
    return PopupMenuItem(
      value: order,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: current == order
                ? ThemeConstants.primaryColor
                : ThemeConstants.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: current == order
                  ? ThemeConstants.primaryColor
                  : ThemeConstants.textPrimary,
              fontWeight: current == order ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (current == order) ...[
            const Spacer(),
            Icon(
              Icons.check_rounded,
              size: 18,
              color: ThemeConstants.primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ThemeConstants.cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.library_music_rounded,
              size: 64,
              color: ThemeConstants.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No songs found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your device to find music',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(libraryProvider.notifier).scanMusic();
            },
            icon: const Icon(Icons.search),
            label: const Text('Scan Music'),
          ),
        ],
      ),
    );
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
            _searchQuery = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              // Can use confidence rating if needed
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}
