// Standalone test for Online Music JioSaavn integration and downloading
// Run with: dart run test/online_music_test.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import '../lib/features/online_music/data/repositories/online_music_repository.dart';

Future<void> main() async {
  print('=== Testing JioSaavn API Integration & Downloader ===\n');

  final repository = OnlineMusicRepository();

  print('1. Searching for "latest bollywood" songs...');
  final songs = await repository.searchSongs('latest bollywood', limit: 1);

  if (songs.isEmpty) {
    print('❌ Failed: No songs returned.');
    exit(1);
  }

  final song = songs.first;
  print('Found song:');
  print('  Title: ${song.title}');
  print('  Artist: ${song.artist}');
  print('  Stream URL: ${song.filePath}');
  print('');

  print('2. Downloading song stream...');
  final tempDir = Directory('test/temp_downloads');
  if (!await tempDir.exists()) {
    await tempDir.create(recursive: true);
  }

  final uri = Uri.parse(song.filePath);
  final ext = uri.path.contains('.mp4') ? '.mp4' : (uri.path.contains('.m4a') ? '.m4a' : '.mp3');
  final outputPath = 'test/temp_downloads/test_song$ext';

  final file = File(outputPath);
  if (await file.exists()) {
    await file.delete();
  }

  try {
    final client = http.Client();
    final request = http.Request('GET', uri);
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Server returned status code ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;
    var downloadedBytes = 0;
    final sink = file.openWrite();

    await response.stream.forEach((chunk) {
      sink.add(chunk);
      downloadedBytes += chunk.length;
      if (totalBytes > 0) {
        final progress = (downloadedBytes / totalBytes * 100).toStringAsFixed(1);
        stdout.write('\rDownloading: $progress% ($downloadedBytes/$totalBytes bytes)');
      } else {
        stdout.write('\rDownloading: $downloadedBytes bytes');
      }
    });

    await sink.flush();
    await sink.close();
    client.close();
    print('\nDownload completed successfully!');

    // 3. Verify file exists and has size > 0
    final stat = await file.stat();
    print('File Info:');
    print('  Path: ${file.path}');
    print('  Size: ${(stat.size / 1024 / 1024).toStringAsFixed(2)} MB');

    if (stat.size > 1000) {
      print('✅ Download Feature Test Passed!');
    } else {
      print('❌ Download Feature Test Failed: File is empty or too small.');
    }
  } catch (e) {
    print('\n❌ Error downloading: $e');
  } finally {
    // Cleanup
    if (await file.exists()) {
      await file.delete();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}
