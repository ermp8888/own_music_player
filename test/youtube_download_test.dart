// Test script for YouTube download with youtube_explode_dart v3.0.5
// Run with: dart run test/youtube_download_test.dart

import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  print('=== YouTube Download Test (v3.0.5) ===\n');
  
  const testUrl = 'https://www.youtube.com/watch?v=aMWuGj0FCYg';
  const outputDir = '/tmp/youtube_test';
  
  // Create output directory
  final dir = Directory(outputDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  
  final yt = YoutubeExplode();
  
  try {
    // Step 1: Parse video ID
    print('Step 1: Parsing video ID...');
    final videoId = VideoId.parseVideoId(testUrl);
    if (videoId == null) {
      print('ERROR: Failed to parse video ID');
      return;
    }
    print('  Video ID: $videoId ✓\n');
    
    // Step 2: Get video info
    print('Step 2: Fetching video info...');
    final video = await yt.videos.get(videoId);
    print('  Title: ${video.title} ✓\n');
    
    // Step 3: Get stream manifest
    print('Step 3: Getting stream manifest...');
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    print('  Audio streams: ${manifest.audioOnly.length}');
    
    for (var i = 0; i < manifest.audioOnly.length; i++) {
      final s = manifest.audioOnly.elementAt(i);
      print('    [$i] ${s.container.name} - ${s.bitrate.kiloBitsPerSecond.toInt()} kbps');
    }
    print('');
    
    if (manifest.audioOnly.isEmpty) {
      print('ERROR: No audio streams available');
      return;
    }
    
    // Step 4: Select best audio stream
    print('Step 4: Selecting audio stream...');
    final audioStreams = manifest.audioOnly.toList();
    audioStreams.sort((a, b) => b.bitrate.compareTo(a.bitrate));
    final audioStream = audioStreams.first;
    print('  Container: ${audioStream.container.name}');
    print('  Bitrate: ${audioStream.bitrate.kiloBitsPerSecond.toInt()} kbps');
    print('  Size: ${(audioStream.size.totalBytes / 1024 / 1024).toStringAsFixed(2)} MB ✓\n');
    
    // Step 5: Download
    print('Step 5: Downloading audio...');
    final safeTitle = video.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final outputPath = '$outputDir/$safeTitle.${audioStream.container.name}';
    
    final file = File(outputPath);
    final fileStream = file.openWrite();
    
    final totalBytes = audioStream.size.totalBytes;
    var downloadedBytes = 0;
    var lastPercent = 0;
    
    final stopwatch = Stopwatch()..start();
    
    final stream = yt.videos.streamsClient.get(audioStream);
    
    await for (final chunk in stream) {
      fileStream.add(chunk);
      downloadedBytes += chunk.length;
      
      final percent = (downloadedBytes / totalBytes * 100).toInt();
      if (percent > lastPercent) {
        lastPercent = percent;
        stdout.write('\r  Progress: $percent%');
      }
    }
    
    await fileStream.flush();
    await fileStream.close();
    
    stopwatch.stop();
    print('\n  Time: ${stopwatch.elapsed.inSeconds}s ✓\n');
    
    // Step 6: Verify
    print('Step 6: Verifying...');
    final savedFile = File(outputPath);
    if (await savedFile.exists()) {
      final size = await savedFile.length();
      print('  File size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
      print('  Path: $outputPath ✓\n');
      print('=== TEST PASSED ===');
    }
    
  } catch (e, stack) {
    print('\nERROR: $e');
    print('\nStack trace:\n$stack');
  } finally {
    yt.close();
  }
}
