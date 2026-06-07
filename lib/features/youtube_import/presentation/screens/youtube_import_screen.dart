import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/metadata_cleaner.dart';
import '../../../../core/providers/download_location_provider.dart';
import '../../../../core/services/download_service.dart';
import '../../../../core/services/filter_pipeline.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/providers/filter_settings_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/url_detector.dart';
import 'package:drift/drift.dart' show Value;

import '../../../../shared/widgets/glass_container.dart';
import '../../../local_music/presentation/providers/library_provider.dart';
import '../../../player/presentation/providers/player_provider.dart';
import '../../../player/presentation/widgets/mini_player.dart';
import '../../../../main.dart' show sharedUrlProvider;

/// Download format enum
enum DownloadFormat { audio, video }

/// Download format provider
final downloadFormatProvider = StateProvider<DownloadFormat>((ref) => DownloadFormat.audio);

/// Download state
enum DownloadStatus { idle, fetching, downloading, complete, error }

/// Download state provider
final downloadStateProvider =
    StateNotifierProvider<DownloadStateNotifier, DownloadState>((ref) {
  final downloadService = ref.watch(downloadServiceProvider);
  final database = ref.watch(databaseProvider);
  final geminiService = ref.watch(geminiServiceProvider);
  return DownloadStateNotifier(
    downloadService: downloadService,
    database: database,
    geminiService: geminiService,
    ref: ref,
  );
});

class DownloadState {
  final DownloadStatus status;
  final String? videoTitle;
  final String? videoAuthor;
  final Duration? videoDuration;
  final double progress;
  final String? errorMessage;
  final String? outputPath;
  final String? debugInfo;
  final int downloadedBytes;
  final int totalBytes;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.videoTitle,
    this.videoAuthor,
    this.videoDuration,
    this.progress = 0,
    this.errorMessage,
    this.outputPath,
    this.debugInfo,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    String? videoTitle,
    String? videoAuthor,
    Duration? videoDuration,
    double? progress,
    String? errorMessage,
    String? outputPath,
    String? debugInfo,
    int? downloadedBytes,
    int? totalBytes,
  }) {
    return DownloadState(
      status: status ?? this.status,
      videoTitle: videoTitle ?? this.videoTitle,
      videoAuthor: videoAuthor ?? this.videoAuthor,
      videoDuration: videoDuration ?? this.videoDuration,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
      outputPath: outputPath ?? this.outputPath,
      debugInfo: debugInfo ?? this.debugInfo,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }
}

class DownloadStateNotifier extends StateNotifier<DownloadState> {
  final DownloadService _downloadService;
  final AppDatabase _database;
  final GeminiService? _geminiService;
  final Ref _ref;

  String? _currentUrl;

  DownloadStateNotifier({
    required DownloadService downloadService,
    required AppDatabase database,
    GeminiService? geminiService,
    required Ref ref,
  })  : _downloadService = downloadService,
        _database = database,
        _geminiService = geminiService,
        _ref = ref,
        super(const DownloadState());

  /// Fetch video info and stream manifest
  Future<void> fetchVideoInfo(String url) async {
    _currentUrl = url.trim();
    try {
      state = state.copyWith(
        status: DownloadStatus.fetching,
        errorMessage: null,
        debugInfo: 'Fetching metadata...',
      );

      final metadata = await _downloadService.getMetadata(_currentUrl!);
      if (metadata == null) {
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Failed to fetch metadata. Make sure the URL is valid.',
        );
        return;
      }

      final title = metadata['title'] as String? ?? 'Downloaded Song';
      final artist = metadata['uploader'] as String? ?? metadata['artist'] as String? ?? 'Unknown Artist';
      final durationSeconds = metadata['duration'] as int? ?? 0;

      state = state.copyWith(
        status: DownloadStatus.idle,
        videoTitle: title,
        videoAuthor: artist,
        videoDuration: Duration(seconds: durationSeconds),
        totalBytes: metadata['filesize'] as int? ?? 0,
        debugInfo: 'Ready',
      );
    } catch (e) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Failed to fetch: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Download the stream
  Future<void> download(String outputDir, DownloadFormat format) async {
    if (_currentUrl == null) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'No URL loaded. Fetch video info first.',
      );
      return;
    }

    try {
      state = state.copyWith(
        status: DownloadStatus.downloading,
        progress: 0.5,
        debugInfo: 'Downloading and converting audio...',
      );

      final result = await _downloadService.downloadAudio(
        url: _currentUrl!,
        outputDir: outputDir,
      );

      if (!result.success || result.filePath == null) {
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: result.error ?? 'Download failed',
        );
        return;
      }

      // Check filters before inserting into the database!
      final filterSettings = _ref.read(filterSettingsProvider);
      final pipeline = FilterPipeline(geminiService: _geminiService);

      final tempSong = {
        'title': result.title ?? 'Unknown',
        'artist': result.artist ?? 'Unknown Artist',
        'bitrate': 256,
        'duration': (result.durationSeconds ?? 0) * 1000,
        'fileSize': result.fileSize ?? 0,
      };

      // Quality check
      if (!pipeline.passQualityFilter(tempSong, settings: filterSettings)) {
        _deleteFile(result.filePath!);
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Download blocked: File does not meet quality requirements.',
        );
        return;
      }

      // Blacklist check
      if (pipeline.isBlacklisted(tempSong, settings: filterSettings)) {
        _deleteFile(result.filePath!);
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Download blocked: Contains blacklisted content.',
        );
        return;
      }

      // Duplicate check
      final existingSongs = await _database.getAllSongs();
      final duplicateList = pipeline.filterDuplicates([tempSong]);
      final isDuplicate = duplicateList.isEmpty || 
          existingSongs.any((s) => pipeline.normalizeString(s.title) == pipeline.normalizeString(result.title ?? '') && (s.duration / 1000.0 - (result.durationSeconds ?? 0)).abs() <= 5.0);
      if (isDuplicate) {
        _deleteFile(result.filePath!);
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Download blocked: This song is already in your library.',
        );
        return;
      }

      // AI Gemini filter check (if enabled and key present)
      if (filterSettings.blockDevotional || filterSettings.blockKaraoke) {
        final passedAI = await pipeline.passGeminiFilter(tempSong);
        if (!passedAI) {
          _deleteFile(result.filePath!);
          state = state.copyWith(
            status: DownloadStatus.error,
            errorMessage: 'Download blocked: Flagged by AI content filter.',
          );
          return;
        }
      }

      // If all filters pass, classify mood/category using Gemini
      String mood = 'unknown';
      if (_geminiService != null) {
        mood = await _geminiService.classifyMood(result.title ?? 'Unknown', result.artist);
      }

      // Save to database
      final detectedPlatform = UrlDetector.detect(_currentUrl!);
      final platformString = detectedPlatform.name;

      await _database.upsertSong(
        SongsCompanion.insert(
          filePath: result.filePath!,
          title: result.title ?? 'Unknown',
          artist: Value(result.artist ?? 'Unknown Artist'),
          album: const Value('Downloaded Album'),
          duration: Value((result.durationSeconds ?? 0) * 1000),
          fileSize: Value(result.fileSize ?? 0),
          sourcePlatform: Value(platformString),
          bitrate: const Value(256),
          mood: Value(mood),
        ),
      );

      // Refresh local music library
      _ref.read(libraryProvider.notifier).loadLibrary();

      state = state.copyWith(
        status: DownloadStatus.complete,
        progress: 1.0,
        outputPath: result.filePath,
        debugInfo: 'Download complete and verified!',
      );
    } catch (e) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Download failed: ${e.toString().split('\n').first}',
      );
    }
  }

  void _deleteFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  void reset() {
    _currentUrl = null;
    state = const DownloadState();
  }
}

/// Disclaimer accepted provider
final disclaimerAcceptedProvider = StateProvider<bool>((ref) => false);

/// Provider for recently downloaded songs
final recentDownloadsProvider = FutureProvider<List<dynamic>>((ref) async {
  final database = ref.watch(databaseProvider);
  final allSongs = await database.getAllSongs();
  // Filter songs from download directories
  return allSongs.where((song) => 
    song.filePath.contains('MyMusicApp') || 
    song.filePath.contains('Download')
  ).take(10).toList();
});

/// YouTube import screen with modern UI
class YouTubeImportScreen extends ConsumerStatefulWidget {
  const YouTubeImportScreen({super.key});

  @override
  ConsumerState<YouTubeImportScreen> createState() => _YouTubeImportScreenState();
}

class _YouTubeImportScreenState extends ConsumerState<YouTubeImportScreen> {
  final _urlController = TextEditingController();
  String? _outputDirectory;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initOutputDirectory();
    _checkSharedUrl();
  }

  void _checkSharedUrl() {
    // Check if there's a shared URL from Share Target
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sharedUrl = ref.read(sharedUrlProvider);
      if (sharedUrl != null && sharedUrl.isNotEmpty) {
        _urlController.text = sharedUrl;
        // Clear the shared URL so it doesn't persist
        ref.read(sharedUrlProvider.notifier).state = null;
        // Auto-accept disclaimer and fetch info
        ref.read(disclaimerAcceptedProvider.notifier).state = true;
        _fetchVideoInfo();
      }
    });
  }

  Future<void> _initOutputDirectory() async {
    // Use the download location from settings
    final locationNotifier = ref.read(downloadLocationProvider.notifier);
    _outputDirectory = ref.read(downloadLocationProvider);
    
    // If empty, initialize with default
    if (_outputDirectory == null || _outputDirectory!.isEmpty) {
      _outputDirectory = await DownloadLocationNotifier.getDefaultDownloadPath();
      await locationNotifier.setLocation(_outputDirectory!);
    }
    
    try {
      final dir = Directory(_outputDirectory!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } catch (e) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        _outputDirectory = appDir.path;
      } catch (_) {}
    }
    
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _selectFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) setState(() => _outputDirectory = result);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '';
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(disclaimerAcceptedProvider);
    final downloadState = ref.watch(downloadStateProvider);
    final downloadFormat = ref.watch(downloadFormatProvider);
    final recentDownloads = ref.watch(recentDownloadsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppTheme.textPrimary,
                  ),
                  const Expanded(
                    child: Text(
                      'YouTube Import',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.history_rounded),
                    color: AppTheme.textPrimary,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_rounded),
                    color: AppTheme.textPrimary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isInitializing
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _buildDownloadView(context, ref, downloadState, downloadFormat, recentDownloads),
                    ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimerView(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.warning),
          ),
          const SizedBox(height: 24),
          const Text(
            'Educational Use Only',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppConstants.youtubeDisclaimer,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                  ),
                  onPressed: () => ref.read(disclaimerAcceptedProvider.notifier).state = true,
                  child: const Text('I Understand'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleDownload(DownloadFormat format) async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a YouTube URL first')),
      );
      return;
    }
    
    ref.read(downloadFormatProvider.notifier).state = format;
    
    if (ref.read(downloadStateProvider).videoTitle == null) {
      await ref.read(downloadStateProvider.notifier).fetchVideoInfo(url);
    }
    
    _startDownload();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAccent),
                  )
                else
                  Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadView(BuildContext context, WidgetRef ref, DownloadState downloadState, DownloadFormat downloadFormat, AsyncValue recentDownloads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ADD URL Section
        _buildSectionLabel('ADD URL'),
        const SizedBox(height: 8),
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: 'https://youtube.com/watch?v...',
            prefixIcon: Icon(Icons.link_rounded),
          ),
          style: const TextStyle(fontSize: 14),
        ),

        const SizedBox(height: 16),

        // Actions Grid
        _buildSectionLabel('ACTIONS'),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: [
            _buildActionButton(
              icon: Icons.analytics_rounded,
              label: 'Analyze Link',
              color: AppTheme.primaryAccent,
              isLoading: downloadState.status == DownloadStatus.fetching,
              onTap: _fetchVideoInfo,
            ),
            _buildActionButton(
              icon: Icons.music_note_rounded,
              label: 'Download MP3',
              color: AppTheme.secondaryAccent,
              isLoading: downloadState.status == DownloadStatus.downloading && downloadFormat == DownloadFormat.audio,
              onTap: () => _handleDownload(DownloadFormat.audio),
            ),
            _buildActionButton(
              icon: Icons.videocam_rounded,
              label: 'Download MP4',
              color: AppTheme.blueAccent,
              isLoading: downloadState.status == DownloadStatus.downloading && downloadFormat == DownloadFormat.video,
              onTap: () => _handleDownload(DownloadFormat.video),
            ),
            _buildActionButton(
              icon: Icons.clear_all_rounded,
              label: 'Clear Input',
              color: AppTheme.redAccent,
              onTap: () {
                _urlController.clear();
                ref.read(downloadStateProvider.notifier).reset();
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // SAVE LOCATION Section
        _buildSectionLabel('SAVE LOCATION'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_rounded, color: AppTheme.primaryAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _outputDirectory?.split('/').last ?? 'DownTune',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _selectFolder,
                child: const Text(
                  'CHANGE',
                  style: TextStyle(
                    color: AppTheme.primaryAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Detected Tracks Section
        if (downloadState.videoTitle != null) ...[
          Row(
            children: [
              const Text(
                'Detected Tracks',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '1 ITEM',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(downloadStateProvider.notifier).reset(),
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTrackCard(downloadState, ref, downloadFormat),
        ],

        // Error message
        if (downloadState.status == DownloadStatus.error)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_rounded, color: AppTheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      downloadState.errorMessage ?? 'Unknown error',
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Success message
        if (downloadState.status == DownloadStatus.complete)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryAccent),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Download Complete!',
                          style: TextStyle(color: AppTheme.secondaryAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(downloadStateProvider.notifier).reset();
                      ref.read(libraryProvider.notifier).quickRescan();
                      ref.invalidate(recentDownloadsProvider);
                      _urlController.clear();
                    },
                    child: const Text('Download Another'),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 24),
        
        // Recent Downloads Section
        _buildRecentDownloadsSection(context, ref, recentDownloads),

        const SizedBox(height: 32),

        // Audio quality indicator
        Center(
          child: Text(
            downloadFormat == DownloadFormat.audio 
                ? 'HIGH QUALITY AUDIO EXTRACTION (320KBPS)'
                : 'HIGH QUALITY VIDEO DOWNLOAD',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Warning Banner card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warningBackground,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppTheme.warningBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This feature is for educational use only. Only download content you own or have rights to. By continuing, you confirm you have the legal right to download and use this content.',
                  style: TextStyle(
                    color: AppTheme.warning.withOpacity(0.85),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDownloadsSection(BuildContext context, WidgetRef ref, AsyncValue recentDownloads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recently Downloaded',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(libraryProvider.notifier).quickRescan();
                ref.invalidate(recentDownloadsProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing...')),
                );
              },
              child: const Text(
                'Refresh',
                style: TextStyle(color: AppTheme.primaryAccent, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        recentDownloads.when(
          data: (songs) {
            if (songs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundCard,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Center(
                  child: Column(
                    children: const [
                      Icon(Icons.download_rounded, size: 32, color: AppTheme.textSecondary),
                      SizedBox(height: 8),
                      Text(
                        'No downloads yet',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: songs.take(5).toList().asMap().entries.map<Widget>((entry) {
                final index = entry.key;
                final song = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    border: Border.all(color: AppTheme.divider.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              MetadataCleaner.cleanTitle(song.title),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              MetadataCleaner.cleanArtist(song.artist),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref.read(miniPlayerDismissedProvider.notifier).state = false;
                          ref.read(playerStateProvider.notifier).playSong(song, queue: songs.cast());
                        },
                        icon: const Icon(Icons.play_circle_filled_rounded, color: AppTheme.primaryAccent),
                        iconSize: 32,
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: (50 * index).toInt()))
                    .fadeIn()
                    .slideX(begin: 0.1, end: 0);
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading downloads', style: TextStyle(color: AppTheme.warning)),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.primaryAccent,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTrackCard(DownloadState downloadState, WidgetRef ref, DownloadFormat format) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          // Album art placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              format == DownloadFormat.audio ? Icons.audiotrack_rounded : Icons.videocam_rounded,
              color: Colors.white70,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MetadataCleaner.cleanTitle(downloadState.videoTitle ?? 'Unknown'),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        MetadataCleaner.cleanArtist(downloadState.videoAuthor ?? 'Unknown'),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${_formatDuration(downloadState.videoDuration)}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Download button or progress
          if (downloadState.status == DownloadStatus.downloading)
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: downloadState.progress,
                      strokeWidth: 2,
                      color: AppTheme.primaryAccent,
                      backgroundColor: AppTheme.backgroundSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(downloadState.progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (downloadState.status == DownloadStatus.complete)
            const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryAccent, size: 32)
          else
            IconButton(
              onPressed: downloadState.status == DownloadStatus.idle ? _startDownload : null,
              icon: Icon(
                Icons.download_rounded,
                color: downloadState.status == DownloadStatus.idle
                    ? AppTheme.primaryAccent
                    : AppTheme.textSecondary,
              ),
              iconSize: 28,
            ),
        ],
      ),
    );
  }

  void _fetchVideoInfo() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      ref.read(downloadStateProvider.notifier).fetchVideoInfo(url);
    }
  }

  void _startDownload() {
    if (_outputDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a folder')));
      return;
    }
    final format = ref.read(downloadFormatProvider);
    ref.read(downloadStateProvider.notifier).download(_outputDirectory!, format);
  }
}
