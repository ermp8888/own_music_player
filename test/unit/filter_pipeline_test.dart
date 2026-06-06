import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/database/app_database.dart';
import 'package:my_music_app/core/services/filter_pipeline.dart';

class FakeDynamicSong {
  final int? id;
  final String? filePath;
  final String? title;
  final String? artist;
  final String? album;
  final int? duration;
  final int? fileSize;
  final int? bitrate;
  final bool? isReported;

  FakeDynamicSong({
    this.id,
    this.filePath,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.fileSize,
    this.bitrate,
    this.isReported,
  });
}

Song createSong({
  int id = 1,
  String filePath = '/music/test.mp3',
  String title = 'Test Song',
  String artist = 'Test Artist',
  String album = 'Test Album',
  int duration = 180000,
  int fileSize = 5000000,
  int bitrate = 256,
  bool isReported = false,
}) {
  return Song(
    id: id,
    filePath: filePath,
    title: title,
    artist: artist,
    album: album,
    duration: duration,
    fileSize: fileSize,
    playCount: 0,
    dateAdded: DateTime.now(),
    isFavorite: false,
    bitrate: bitrate,
    isReported: isReported,
  );
}

void main() {
  group('FilterPipeline.passQualityFilter', () {
    late FilterPipeline pipeline;

    setUp(() {
      pipeline = FilterPipeline();
    });

    test('Song with bitrate 320kbps, duration 180s, size 5MB → PASS', () {
      final song = createSong(bitrate: 320, duration: 180000, fileSize: 5 * 1024 * 1024);
      expect(pipeline.passQualityFilter(song), isTrue);
    });

    test('Song with bitrate 128kbps exactly → PASS (boundary)', () {
      final song = createSong(bitrate: 128, duration: 180000, fileSize: 5 * 1024 * 1024);
      expect(pipeline.passQualityFilter(song), isTrue);
    });

    test('Song with duration 60s exactly → PASS (boundary)', () {
      final song = createSong(bitrate: 256, duration: 60000, fileSize: 5 * 1024 * 1024);
      expect(pipeline.passQualityFilter(song), isTrue);
    });

    test('Song with duration 600s exactly → PASS (boundary)', () {
      final song = createSong(bitrate: 256, duration: 600000, fileSize: 5 * 1024 * 1024);
      expect(pipeline.passQualityFilter(song), isTrue);
    });

    test('Song with bitrate 127kbps → FAIL (below minimum)', () {
      final song = createSong(bitrate: 127, duration: 180000, fileSize: 5 * 1024 * 1024);
      expect(pipeline.passQualityFilter(song), isFalse);
    });

    test('Song with duration 59s → FAIL (too short)', () {
      final song = createSong(bitrate: 256, duration: 59000, fileSize: 5 * 1024 * 1024);
      expect(pipeline.passQualityFilter(song), isFalse);
    });

    test('Song with duration 601s → FAIL (too long)', () {
      final song = createSong(bitrate: 256, duration: 601000, fileSize: 5 * 1024 * 1024);
      expect(pipeline.passQualityFilter(song), isFalse);
    });

    test('Song with fileSize 0.9MB → FAIL (too small)', () {
      final song = createSong(
        bitrate: 256,
        duration: 180000,
        fileSize: (0.9 * 1024 * 1024).toInt(),
      );
      expect(pipeline.passQualityFilter(song), isFalse);
    });

    test('Song with bitrate null → FAIL gracefully (no crash)', () {
      final song = FakeDynamicSong(
        bitrate: null,
        duration: 180000,
        fileSize: 5 * 1024 * 1024,
      );
      expect(pipeline.passQualityFilter(song), isFalse);
    });

    test('Song with duration null → FAIL gracefully (no crash)', () {
      final song = FakeDynamicSong(
        bitrate: 256,
        duration: null,
        fileSize: 5 * 1024 * 1024,
      );
      expect(pipeline.passQualityFilter(song), isFalse);
    });

    test('Song with fileSize null → FAIL gracefully (no crash)', () {
      final song = FakeDynamicSong(
        bitrate: 256,
        duration: 180000,
        fileSize: null,
      );
      expect(pipeline.passQualityFilter(song), isFalse);
    });
  });
}
