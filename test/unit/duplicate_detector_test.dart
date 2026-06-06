import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/database/app_database.dart';
import 'package:my_music_app/core/services/filter_pipeline.dart';

Song createSong({
  required int id,
  required String title,
  required int duration,
  required int bitrate,
}) {
  return Song(
    id: id,
    filePath: '/music/song_$id.mp3',
    title: title,
    artist: 'Test Artist',
    album: 'Test Album',
    duration: duration,
    fileSize: 5000000,
    playCount: 0,
    dateAdded: DateTime.now(),
    isFavorite: false,
    bitrate: bitrate,
    isReported: false,
  );
}

void main() {
  group('FilterPipeline.filterDuplicates', () {
    late FilterPipeline pipeline;

    setUp(() {
      pipeline = FilterPipeline();
    });

    test('Normalize title logic check', () {
      expect(pipeline.normalizeString('Tum Hi Ho!'), 'tum hi ho');
      expect(pipeline.normalizeString('Shape of You (Official Video)'), 'shape of you official video');
      expect(pipeline.normalizeString('  Perfect  '), 'perfect');
      expect(pipeline.normalizeString('हनुमान चालीसा'), 'हनुमान चालीसा');
    });

    test('Two different songs are both kept', () {
      final song1 = createSong(id: 1, title: 'Tum Hi Ho', duration: 260000, bitrate: 320);
      final song2 = createSong(id: 2, title: 'Shape of You', duration: 230000, bitrate: 320);

      final result = pipeline.filterDuplicates([song1, song2]);
      expect(result.length, 2);
    });

    test('Identical title and duration within 5s → keep higher quality (bitrate)', () {
      final lowQuality = createSong(id: 1, title: 'Tum Hi Ho', duration: 260000, bitrate: 128);
      final highQuality = createSong(id: 2, title: 'Tum Hi Ho', duration: 262000, bitrate: 320); // +2s, higher quality

      final result = pipeline.filterDuplicates([lowQuality, highQuality]);
      expect(result.length, 1);
      expect(result.first.id, 2); // Keeps highQuality
    });

    test('Identical title but duration difference > 5s → both kept', () {
      final song1 = createSong(id: 1, title: 'Tum Hi Ho', duration: 260000, bitrate: 320);
      final song2 = createSong(id: 2, title: 'Tum Hi Ho', duration: 268000, bitrate: 320); // +8s

      final result = pipeline.filterDuplicates([song1, song2]);
      expect(result.length, 2);
    });

    test('Duplicates with normalization differences → keep higher quality', () {
      final song1 = createSong(id: 1, title: 'Perfect!', duration: 260000, bitrate: 128);
      final song2 = createSong(id: 2, title: 'perfect', duration: 261000, bitrate: 320); // Normalized title matches, +1s duration

      final result = pipeline.filterDuplicates([song1, song2]);
      expect(result.length, 1);
      expect(result.first.id, 2); // Keeps song2
    });
  });
}
