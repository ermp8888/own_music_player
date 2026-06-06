import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/services/download_service.dart';

class MockProcessRunner implements ProcessRunner {
  List<String>? lastArguments;
  String? lastExecutable;
  ProcessResult resultToReturn = ProcessResult(0, 0, '', '');
  bool throwException = false;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    bool runInShell = false,
  }) async {
    lastExecutable = executable;
    lastArguments = arguments;

    if (throwException) {
      throw const ProcessException('yt-dlp', []);
    }

    return resultToReturn;
  }
}

void main() {
  group('DownloadService yt-dlp Tests', () {
    late MockProcessRunner mockRunner;
    late DownloadService downloadService;

    setUp(() {
      mockRunner = MockProcessRunner();
      downloadService = DownloadService(runner: mockRunner);
    });

    test('Verify correct flags are passed to yt-dlp', () async {
      mockRunner.resultToReturn = ProcessResult(
        1,
        0,
        '{"title": "Test Song", "uploader": "Test Artist", "duration": 180}',
        '',
      );

      final result = await downloadService.downloadAudio(
        url: 'https://youtube.com/watch?v=abc123',
        outputDir: '/dummy/path',
      );

      // Check executable
      expect(mockRunner.lastExecutable, 'yt-dlp');

      // Verify the arguments passed
      final args = mockRunner.lastArguments;
      expect(args, isNotNull);

      // Verify audio format is always mp3
      expect(args!.contains('--audio-format'), isTrue);
      expect(args[args.indexOf('--audio-format') + 1], 'mp3');

      // Verify --audio-quality 0 flag is always present
      expect(args.contains('--audio-quality'), isTrue);
      expect(args[args.indexOf('--audio-quality') + 1], '0');

      // Verify extraction flag -x is present
      expect(args.contains('-x'), isTrue);

      // Verify best audio format flag -f bestaudio is present
      expect(args.contains('-f'), isTrue);
      expect(args[args.indexOf('-f') + 1], 'bestaudio');
    });

    test('Verify graceful error handling when yt-dlp fails with non-zero exit code', () async {
      // Setup mock runner to fail on download (metadata fetch succeeds or fails, let's test download fail)
      mockRunner.resultToReturn = ProcessResult(1, 1, '', 'Some yt-dlp error');

      final result = await downloadService.downloadAudio(
        url: 'https://youtube.com/watch?v=abc123',
        outputDir: '/dummy/path',
      );

      expect(result.success, isFalse);
      expect(result.error, contains('yt-dlp execution failed'));
    });

    test('Verify graceful error handling when ProcessRunner throws an exception', () async {
      mockRunner.throwException = true;

      final result = await downloadService.downloadAudio(
        url: 'https://youtube.com/watch?v=abc123',
        outputDir: '/dummy/path',
      );

      expect(result.success, isFalse);
      expect(result.error, contains('Download error'));
    });
  });
}
