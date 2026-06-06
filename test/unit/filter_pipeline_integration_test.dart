import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/database/app_database.dart';
import 'package:my_music_app/core/services/filter_pipeline.dart';
import '../helpers/mock_songs.dart';
import '../helpers/mock_gemini.dart';

Song toSong(MockSong mock) {
  return Song(
    id: mock.id,
    filePath: mock.filePath,
    title: mock.title,
    artist: mock.artist,
    album: mock.album,
    duration: mock.duration,
    fileSize: mock.fileSize,
    playCount: mock.playCount,
    dateAdded: DateTime.now(),
    isFavorite: mock.isFavorite,
    sourcePlatform: mock.sourcePlatform,
    bitrate: mock.bitrate,
    mood: mock.mood,
    isReported: mock.isReported,
  );
}

void main() {
  group('FilterPipeline Integration Tests', () {
    late FakeGeminiService fakeGemini;
    late FilterPipeline pipeline;

    setUp(() {
      fakeGemini = FakeGeminiService();
      pipeline = FilterPipeline(geminiService: fakeGemini);
    });

    test('Pipeline correctly filters good vs bad quality / blacklisted songs', () async {
      // Configure Gemini to pass all songs that reach it
      fakeGemini.setResponse('NO');

      // 1. Prepare mixture of songs
      final good = goodSongs.map(toSong).toList();
      final lowQuality = lowQualitySongs.map(toSong).toList();
      final blacklisted = blacklistedSongs.map(toSong).toList();

      final allInput = [...good, ...lowQuality, ...blacklisted];

      // Run pipeline
      final results = await pipeline.filterSongs(allInput);

      // Verify: only good songs should survive quality & blacklist filters
      expect(results.length, good.length);
      for (final song in results) {
        expect(song.bitrate, greaterThanOrEqualTo(128));
        expect(song.duration, greaterThanOrEqualTo(60000));
        expect(song.duration, lessThanOrEqualTo(600000));
        expect(song.fileSize, greaterThanOrEqualTo(1024 * 1024));
        
        final isSongBlacklisted = pipeline.isBlacklisted(song);
        expect(isSongBlacklisted, isFalse);
      }
    });

    test('Pipeline filters duplicates keeping highest quality', () async {
      fakeGemini.setResponse('NO');

      // Original song: bitrate 320, duration 261s
      final original = toSong(duplicateSongs[0]); 
      // Duplicate song: bitrate 128, duration 263s (within 5s, same title)
      final duplicate = toSong(duplicateSongs[1]); 

      final results = await pipeline.filterSongs([original, duplicate]);

      // Only the higher quality (original with 320kbps) should remain
      expect(results.length, 1);
      expect(results.first.id, original.id);
      expect(results.first.bitrate, 320);
    });
  });
}
