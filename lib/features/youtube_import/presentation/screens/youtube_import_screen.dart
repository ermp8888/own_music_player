import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../shared/widgets/gradient_background.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../local_music/presentation/providers/library_provider.dart';
import '../../../player/presentation/widgets/mini_player.dart';

/// Download state
enum DownloadStatus { idle, fetching, downloading, complete, error }

/// Download state provider
final downloadStateProvider =
    StateNotifierProvider<DownloadStateNotifier, DownloadState>((ref) {
  return DownloadStateNotifier();
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
  DownloadStateNotifier() : super(const DownloadState());

  YoutubeExplode? _yt;
  Video? _currentVideo;
  StreamManifest? _manifest;
  AudioOnlyStreamInfo? _audioStream;

  /// Parse video ID from URL
  VideoId? _parseVideoId(String url) {
    try {
      final id = VideoId.parseVideoId(url);
      if (id != null) {
        return VideoId(id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch video info and stream manifest
  Future<void> fetchVideoInfo(String url) async {
    // Create fresh instance
    _yt?.close();
    _yt = YoutubeExplode();
    
    try {
      state = state.copyWith(
        status: DownloadStatus.fetching,
        errorMessage: null,
        debugInfo: 'Parsing URL...',
      );

      final videoId = _parseVideoId(url);
      if (videoId == null) {
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Invalid YouTube URL',
        );
        return;
      }

      debugPrint('[YT] Video ID: ${videoId.value}');
      state = state.copyWith(debugInfo: 'Fetching video info...');

      // Get video metadata
      _currentVideo = await _yt!.videos.get(videoId);
      debugPrint('[YT] Title: ${_currentVideo!.title}');

      state = state.copyWith(
        videoTitle: _currentVideo!.title,
        videoAuthor: _currentVideo!.author,
        videoDuration: _currentVideo!.duration,
        debugInfo: 'Getting stream manifest...',
      );

      // Get stream manifest with specific clients that work better
      // Using safari and androidVr clients as recommended in docs
      _manifest = await _yt!.videos.streamsClient.getManifest(
        videoId,
        ytClients: [
          YoutubeApiClient.safari,
          YoutubeApiClient.androidVr,
          YoutubeApiClient.android,
        ],
      );

      debugPrint('[YT] Audio streams: ${_manifest!.audioOnly.length}');
      debugPrint('[YT] Muxed streams: ${_manifest!.muxed.length}');

      // Get best audio stream
      if (_manifest!.audioOnly.isNotEmpty) {
        _audioStream = _manifest!.audioOnly.withHighestBitrate();
        debugPrint('[YT] Selected: ${_audioStream!.container.name} - ${_audioStream!.bitrate.kiloBitsPerSecond.toInt()} kbps');
      } else if (_manifest!.muxed.isNotEmpty) {
        // Fallback to muxed if no audio-only available
        debugPrint('[YT] No audio-only streams, using muxed');
      }

      if (_audioStream == null && _manifest!.muxed.isEmpty) {
        state = state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'No audio streams available for this video',
        );
        return;
      }

      final size = _audioStream?.size.totalBytes ?? 0;
      state = state.copyWith(
        status: DownloadStatus.idle,
        totalBytes: size,
        debugInfo: 'Ready (${(size / 1024 / 1024).toStringAsFixed(1)} MB)',
      );
    } catch (e, stack) {
      debugPrint('[YT] Error: $e');
      debugPrint('[YT] Stack: $stack');
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Failed to fetch: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Download the audio stream
  Future<void> downloadAudio(String outputDir) async {
    if (_yt == null || _audioStream == null) {
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'No stream available. Fetch video info first.',
      );
      return;
    }

    try {
      state = state.copyWith(
        status: DownloadStatus.downloading,
        progress: 0,
        downloadedBytes: 0,
        debugInfo: 'Preparing download...',
      );

      // Ensure output directory exists
      final dir = Directory(outputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Prepare file name
      final title = _currentVideo?.title ?? 'audio';
      final safeTitle = title
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final extension = _audioStream!.container.name;
      final outputPath = '$outputDir/$safeTitle.$extension';

      debugPrint('[YT] Output: $outputPath');
      state = state.copyWith(debugInfo: 'Starting download...');

      // Open file for writing
      final file = File(outputPath);
      final fileStream = file.openWrite();

      // Get the stream and pipe to file
      final totalBytes = _audioStream!.size.totalBytes;
      var downloadedBytes = 0;

      // Get the actual stream using the library's stream client
      final stream = _yt!.videos.streamsClient.get(_audioStream!);

      // Pipe with progress tracking
      await for (final chunk in stream) {
        fileStream.add(chunk);
        downloadedBytes += chunk.length;

        final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
        
        // Update progress (throttle to avoid too many rebuilds)
        if (downloadedBytes % (1024 * 100) == 0 || progress >= 1.0) {
          state = state.copyWith(
            progress: progress,
            downloadedBytes: downloadedBytes,
            debugInfo: '${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} / ${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
          );
        }
      }

      // Flush and close
      await fileStream.flush();
      await fileStream.close();

      debugPrint('[YT] Download complete: $outputPath');

      state = state.copyWith(
        status: DownloadStatus.complete,
        progress: 1.0,
        outputPath: outputPath,
        debugInfo: 'Download complete!',
      );
    } catch (e, stack) {
      debugPrint('[YT] Download error: $e');
      debugPrint('[YT] Stack: $stack');
      state = state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Download failed: ${e.toString().split('\n').first}',
      );
    }
  }

  void reset() {
    _currentVideo = null;
    _manifest = null;
    _audioStream = null;
    state = const DownloadState();
  }

  @override
  void dispose() {
    _yt?.close();
    super.dispose();
  }
}

/// Disclaimer accepted provider
final disclaimerAcceptedProvider = StateProvider<bool>((ref) => false);

/// YouTube import screen
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
  }

  Future<void> _initOutputDirectory() async {
    _outputDirectory = '/storage/emulated/0/Download/MyMusicApp';
    
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
    final disclaimerAccepted = ref.watch(disclaimerAcceptedProvider);
    final downloadState = ref.watch(downloadStateProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                    const Expanded(child: Text('YouTube Import', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              Expanded(
                child: _isInitializing
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: !disclaimerAccepted
                            ? _buildDisclaimerView(context, ref)
                            : _buildDownloadView(context, ref, downloadState),
                      ),
              ),
              const MiniPlayer(),
            ],
          ),
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
            decoration: BoxDecoration(color: ThemeConstants.warningColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.warning_amber_rounded, size: 48, color: ThemeConstants.warningColor),
          ),
          const SizedBox(height: 24),
          Text('Educational Use Only', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(AppConstants.youtubeDisclaimer, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: () => ref.read(disclaimerAcceptedProvider.notifier).state = true, child: const Text('I Understand'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadView(BuildContext context, WidgetRef ref, DownloadState downloadState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // URL input
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter YouTube URL', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(hintText: 'https://youtube.com/watch?v=...', prefixIcon: Icon(Icons.link)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: downloadState.status == DownloadStatus.fetching || downloadState.status == DownloadStatus.downloading
                      ? null
                      : _fetchVideoInfo,
                  icon: downloadState.status == DownloadStatus.fetching
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                  label: Text(downloadState.status == DownloadStatus.fetching ? 'Fetching...' : 'Fetch Info'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Video info
        if (downloadState.videoTitle != null)
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(gradient: ThemeConstants.primaryGradient, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.music_video_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(downloadState.videoTitle!, style: Theme.of(context).textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (downloadState.videoAuthor != null) ...[
                            Icon(Icons.person, size: 14, color: ThemeConstants.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(child: Text(downloadState.videoAuthor!, style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ],
                          if (downloadState.videoDuration != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.timer, size: 14, color: ThemeConstants.textSecondary),
                            const SizedBox(width: 4),
                            Text(_formatDuration(downloadState.videoDuration), style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Output directory
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Save Location', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(onPressed: _selectFolder, icon: const Icon(Icons.folder_open, size: 18), label: const Text('Change')),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: ThemeConstants.cardColor, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_outputDirectory ?? 'Not set', style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Debug info
        if (downloadState.debugInfo != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(downloadState.debugInfo!, style: TextStyle(color: ThemeConstants.textMuted, fontSize: 12), textAlign: TextAlign.center),
          ),

        // Download progress
        if (downloadState.status == DownloadStatus.downloading)
          GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Downloading...'),
                    Text('${(downloadState.progress * 100).toStringAsFixed(0)}%', style: TextStyle(color: ThemeConstants.primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: downloadState.progress, minHeight: 8)),
              ],
            ),
          ),

        // Success
        if (downloadState.status == DownloadStatus.complete)
          GlassContainer(
            padding: const EdgeInsets.all(20),
            backgroundColor: ThemeConstants.successColor.withValues(alpha: 0.1),
            child: Column(
              children: [
                Icon(Icons.check_circle_rounded, color: ThemeConstants.successColor, size: 48),
                const SizedBox(height: 12),
                Text('Download Complete!', style: TextStyle(color: ThemeConstants.successColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(downloadState.outputPath ?? '', style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 10), textAlign: TextAlign.center, maxLines: 2),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(downloadStateProvider.notifier).reset();
                    ref.read(libraryProvider.notifier).quickRescan();
                    _urlController.clear();
                  },
                  child: const Text('Download Another'),
                ),
              ],
            ),
          ),

        // Error
        if (downloadState.status == DownloadStatus.error)
          GlassContainer(
            padding: const EdgeInsets.all(20),
            backgroundColor: ThemeConstants.errorColor.withValues(alpha: 0.1),
            child: Column(
              children: [
                Icon(Icons.error_rounded, color: ThemeConstants.errorColor, size: 48),
                const SizedBox(height: 12),
                Text('Error', style: TextStyle(color: ThemeConstants.errorColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(downloadState.errorMessage ?? 'Unknown error', style: TextStyle(color: ThemeConstants.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(onPressed: () => ref.read(downloadStateProvider.notifier).reset(), child: const Text('Try Again')),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Download button
        if (downloadState.videoTitle != null && downloadState.status == DownloadStatus.idle)
          ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Audio'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
      ],
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
    ref.read(downloadStateProvider.notifier).downloadAudio(_outputDirectory!);
  }
}
