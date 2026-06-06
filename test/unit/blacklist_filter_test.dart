import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/database/app_database.dart';
import 'package:my_music_app/core/services/filter_pipeline.dart';

Song createSong({
  required String title,
  required String artist,
}) {
  return Song(
    id: 1,
    filePath: '/music/test.mp3',
    title: title,
    artist: artist,
    album: 'Test Album',
    duration: 180000,
    fileSize: 5000000,
    playCount: 0,
    dateAdded: DateTime.now(),
    isFavorite: false,
    bitrate: 256,
    isReported: false,
  );
}

void main() {
  group('FilterPipeline.isBlacklisted', () {
    late FilterPipeline pipeline;

    setUp(() {
      pipeline = FilterPipeline();
    });

    test('Clean mainstream song → NOT blacklisted', () {
      final song = createSong(title: 'Shape of You', artist: 'Ed Sheeran');
      expect(pipeline.isBlacklisted(song), isFalse);
    });

    test('Devotional song (English) in title → BLACKLISTED', () {
      final song = createSong(title: 'Hanuman Chalisa', artist: 'Gulshan Kumar');
      expect(pipeline.isBlacklisted(song), isTrue);
    });

    test('Devotional song (English) in artist → BLACKLISTED', () {
      final song = createSong(title: 'Aarti Kunj Bihari Ki', artist: 'Krishna Bhajan Mandli');
      expect(pipeline.isBlacklisted(song), isTrue);
    });

    test('Devotional keyword (Devanagari) in title → BLACKLISTED', () {
      final song = createSong(title: 'श्री कृष्ण गोविंद हरे मुरारी', artist: 'Unknown');
      expect(pipeline.isBlacklisted(song), isTrue);
    });

    test('Karaoke song in title → BLACKLISTED', () {
      final song = createSong(title: 'Shape of You (Karaoke Version)', artist: 'Ed Sheeran');
      expect(pipeline.isBlacklisted(song), isTrue);
    });

    test('Karaoke word (Devanagari) in title → BLACKLISTED', () {
      final song = createSong(title: 'तुम ही हो कराओके', artist: 'Arijit Singh');
      expect(pipeline.isBlacklisted(song), isTrue);
    });

    test('Case insensitivity check → BLACKLISTED', () {
      final song = createSong(title: 'HANUMAN CHALISA', artist: 'GULSHAN KUMAR');
      expect(pipeline.isBlacklisted(song), isTrue);
    });

    test('Toggle disabled settings check (remix/instrumental default is OFF)', () {
      final remixSong = createSong(title: 'Shape of You Remix', artist: 'Ed Sheeran');
      final instrumentalSong = createSong(title: 'Shape of You Instrumental', artist: 'Ed Sheeran');

      // Defaults: blockRemixes = false, blockInstrumentals = false
      expect(pipeline.isBlacklisted(remixSong), isFalse);
      expect(pipeline.isBlacklisted(instrumentalSong), isFalse);

      // Toggle ON
      const customSettings = FilterSettings(
        blockRemixes: true,
        blockInstrumentals: true,
      );

      expect(pipeline.isBlacklisted(remixSong, settings: customSettings), isTrue);
      expect(pipeline.isBlacklisted(instrumentalSong, settings: customSettings), isTrue);
    });
  });
}
