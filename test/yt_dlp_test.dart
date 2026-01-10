// Test yt-dlp download approach
// This simulates what we could do on a server backend
// Run with: dart run test/yt_dlp_test.dart

import 'dart:io';

const testUrl = 'https://www.youtube.com/watch?v=aMWuGj0FCYg';
const outputDir = '/tmp/youtube_test';

Future<void> main() async {
  print('=== yt-dlp Download Test ===\n');
  
  // Check if yt-dlp is available
  final ytDlpPath = '/tmp/yt-dlp';
  
  if (!await File(ytDlpPath).exists()) {
    print('yt-dlp not found at $ytDlpPath');
    print('Please run: curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /tmp/yt-dlp && chmod +x /tmp/yt-dlp');
    return;
  }
  
  // Create output directory
  await Directory(outputDir).create(recursive: true);
  
  // Get video info as JSON
  print('Getting video info...');
  var result = await Process.run(
    ytDlpPath,
    ['-j', testUrl],
  );
  
  if (result.exitCode != 0) {
    print('Error getting info: ${result.stderr}');
    return;
  }
  
  // Parse JSON
  final infoJson = result.stdout as String;
  print('Got video info (${infoJson.length} bytes)\n');
  
  // Download audio only  
  print('Downloading audio...');
  result = await Process.run(
    ytDlpPath,
    [
      '-x', // Extract audio
      '--audio-format', 'mp3',
      '-o', '$outputDir/%(title)s.%(ext)s',
      '--no-playlist',
      testUrl,
    ],
    runInShell: false,
  );
  
  print('Exit code: ${result.exitCode}');
  print('stdout: ${result.stdout}');
  print('stderr: ${result.stderr}');
  
  if (result.exitCode == 0) {
    print('\n✓ Download successful!');
    
    // List files in output dir
    final dir = Directory(outputDir);
    await for (final file in dir.list()) {
      if (file is File) {
        final stat = await file.stat();
        print('  - ${file.path.split('/').last} (${(stat.size / 1024 / 1024).toStringAsFixed(2)} MB)');
      }
    }
  } else {
    print('\n✗ Download failed');
  }
}
