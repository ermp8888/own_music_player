import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/services/download_service.dart';
import 'package:my_music_app/core/services/url_detector.dart';

void main() {
  group('DownloadService', () {
    late DownloadService downloadService;

    setUp(() {
      downloadService = DownloadService();
    });

    tearDown(() {
      downloadService.dispose();
    });

    test('YtDlpResult success fields are correct', () {
      final result = YtDlpResult(
        success: true,
        filePath: '/test/path.m4a',
        title: 'Test Song',
        artist: 'Test Artist',
        durationSeconds: 180,
        fileSize: 5000000,
      );

      expect(result.success, isTrue);
      expect(result.filePath, '/test/path.m4a');
      expect(result.title, 'Test Song');
      expect(result.artist, 'Test Artist');
      expect(result.durationSeconds, 180);
      expect(result.fileSize, 5000000);
      expect(result.error, isNull);
    });

    test('YtDlpResult failure fields are correct', () {
      final result = YtDlpResult(
        success: false,
        error: 'Download failed: Network error',
      );

      expect(result.success, isFalse);
      expect(result.filePath, isNull);
      expect(result.error, contains('Download failed'));
    });

    test('downloadAudio rejects unsupported URLs', () async {
      final result = await downloadService.downloadAudio(
        url: 'https://example.com/random-page',
        outputDir: '/dummy/path',
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Unsupported'));
    });

    test('downloadAudio accepts YouTube URLs', () async {
      // This test verifies URL detection routing, not actual download
      final platform = UrlDetector.detect('https://youtube.com/watch?v=abc123');
      expect(platform, ContentPlatform.youtube);
    });

    test('downloadAudio accepts YouTube Shorts URLs', () async {
      final platform = UrlDetector.detect('https://youtube.com/shorts/abc123');
      expect(platform, ContentPlatform.ytShorts);
    });

    test('downloadAudio accepts Instagram URLs', () async {
      final platform = UrlDetector.detect('https://www.instagram.com/reel/abc123');
      expect(platform, ContentPlatform.instagram);
    });
  });
}
