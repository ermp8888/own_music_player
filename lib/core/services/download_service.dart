import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'url_detector.dart';
import 'instagram_extractor.dart';
import '../utils/metadata_cleaner.dart';

/// Provider for DownloadService.
final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService();
});

/// Result of a download/metadata extraction.
class YtDlpResult {
  final bool success;
  final String? filePath;
  final String? title;
  final String? artist;
  final int? durationSeconds;
  final int? fileSize;
  final String? error;

  YtDlpResult({
    required this.success,
    this.filePath,
    this.title,
    this.artist,
    this.durationSeconds,
    this.fileSize,
    this.error,
  });
}

/// Download service utilizing youtube_explode_dart and InstagramExtractor.
class DownloadService {
  final YoutubeExplode _yt;
  final InstagramExtractor _ig;

  DownloadService()
      : _yt = YoutubeExplode(),
        _ig = InstagramExtractor();

  void dispose() {
    _yt.close();
    _ig.dispose();
  }

  /// Retrieve video metadata
  Future<Map<String, dynamic>?> getMetadata(String url) async {
    final platform = UrlDetector.detect(url);
    try {
      if (platform == ContentPlatform.youtube || platform == ContentPlatform.ytShorts) {
        final videoId = UrlDetector.extractId(url);
        if (videoId == null) return null;
        final video = await _yt.videos.get(videoId);
        final title = extractTitleFromArtistTitle(video.title);
        final artist = extractArtistFromTitle(video.title) ?? cleanArtist(video.author);
        return {
          'title': title,
          'uploader': artist,
          'artist': artist,
          'duration': video.duration?.inSeconds ?? 0,
        };
      } else if (platform == ContentPlatform.instagram) {
        // TODO: (Future Work) Instagram extraction is currently facing aggressive
        // anti-scraping blocks from Instagram servers, causing 500/401 errors.
        // The current InstagramExtractor implementation is unreliable.
        // A robust backend proxy or authenticated API approach is required for future updates.
        final result = await _ig.extract(url);
        if (result.isSuccess) {
          return {
            'title': result.title ?? 'Instagram Video',
            'uploader': 'Instagram User',
            'duration': 0, // Duration unknown from simple extraction
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Download audio
  Future<YtDlpResult> downloadAudio({
    required String url,
    required String outputDir,
  }) async {
    final trimmedUrl = url.trim();
    final platform = UrlDetector.detect(trimmedUrl);
    
    if (platform == ContentPlatform.youtube || platform == ContentPlatform.ytShorts) {
      return _downloadYoutube(trimmedUrl, outputDir);
    } else if (platform == ContentPlatform.instagram) {
      return _downloadInstagram(trimmedUrl, outputDir);
    }

    return YtDlpResult(
      success: false,
      error: 'Unsupported platform/invalid URL',
    );
  }

  Future<YtDlpResult> _downloadYoutube(String url, String outputDir) async {
    try {
      final videoId = UrlDetector.extractId(url);
      if (videoId == null) throw Exception('Invalid YouTube URL');

      final video = await _yt.videos.get(videoId);
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      
      final title = extractTitleFromArtistTitle(video.title);
      final artist = extractArtistFromTitle(video.title) ?? cleanArtist(video.author);

      final safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
      final outputPath = '$outputDir/$safeTitle.m4a';
      final file = File(outputPath);

      final stream = _yt.videos.streamsClient.get(streamInfo);
      final fileStream = file.openWrite();
      await stream.pipe(fileStream);
      await fileStream.flush();
      await fileStream.close();

      return YtDlpResult(
        success: true,
        filePath: outputPath,
        title: title,
        artist: artist,
        durationSeconds: video.duration?.inSeconds ?? 0,
        fileSize: await file.length(),
      );
    } catch (e) {
      return YtDlpResult(
        success: false,
        error: 'YouTube download failed: $e',
      );
    }
  }

  Future<YtDlpResult> _downloadInstagram(String url, String outputDir) async {
    try {
      final result = await _ig.extract(url);
      if (!result.isSuccess || result.videoUrl == null) {
        throw Exception(result.error ?? 'Failed to extract Instagram video');
      }

      final safeTitle = (result.title ?? 'Instagram_Video_${DateTime.now().millisecondsSinceEpoch}').replaceAll(RegExp(r'[^\w\s]+'), '').trim();
      final outputPath = '$outputDir/$safeTitle.mp4';
      final file = File(outputPath);

      final response = await http.get(Uri.parse(result.videoUrl!));
      if (response.statusCode != 200) throw Exception('Failed to download file');

      await file.writeAsBytes(response.bodyBytes);

      return YtDlpResult(
        success: true,
        filePath: outputPath,
        title: result.title ?? 'Instagram Video',
        artist: 'Instagram User',
        durationSeconds: 0,
        fileSize: await file.length(),
      );
    } catch (e) {
      return YtDlpResult(
        success: false,
        error: 'Instagram download failed: $e',
      );
    }
  }
}
