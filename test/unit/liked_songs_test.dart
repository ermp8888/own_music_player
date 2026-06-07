import 'dart:ffi';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/database/app_database.dart';
import 'package:my_music_app/core/helpers/favorite_helper.dart';
import 'package:sqlite3/open.dart';

void main() {
  // Override sqlite3 library loading for Linux environment in tests
  open.overrideFor(OperatingSystem.linux, () {
    return DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0');
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Liked Songs - Local Songs', () {
    test('liking local song updates DB isFavorite to true', () async {
      // 1. Insert a local song
      await db.upsertSong(
        SongsCompanion.insert(
          id: const Value(1),
          title: 'Local Song 1',
          filePath: '/path/to/local_song1.mp3',
          isFavorite: const Value(false),
        ),
      );

      // Verify initial favorite status is false
      var song = await db.getSongById(1);
      expect(song!.isFavorite, isFalse);

      // 2. Toggle favorite
      await db.toggleFavorite(1);

      // Verify favorite status is true
      song = await db.getSongById(1);
      expect(song!.isFavorite, isTrue);
    });

    test('liked local song appears in watchFavorites stream', () async {
      await db.upsertSong(
        SongsCompanion.insert(
          id: const Value(1),
          title: 'Local Song 1',
          filePath: '/path/to/local_song1.mp3',
          isFavorite: const Value(true),
        ),
      );

      final favorites = await db.watchFavorites().first;
      expect(favorites.length, 1);
      expect(favorites.first.title, 'Local Song 1');
    });

    test('unliking local song sets isFavorite to false', () async {
      await db.upsertSong(
        SongsCompanion.insert(
          id: const Value(1),
          title: 'Local Song 1',
          filePath: '/path/to/local_song1.mp3',
          isFavorite: const Value(true),
        ),
      );

      await db.toggleFavorite(1);

      final song = await db.getSongById(1);
      expect(song!.isFavorite, isFalse);
    });

    test('unliked song removed from watchFavorites stream', () async {
      await db.upsertSong(
        SongsCompanion.insert(
          id: const Value(1),
          title: 'Local Song 1',
          filePath: '/path/to/local_song1.mp3',
          isFavorite: const Value(true),
        ),
      );

      var favorites = await db.watchFavorites().first;
      expect(favorites.length, 1);

      await db.toggleFavorite(1);

      favorites = await db.watchFavorites().first;
      expect(favorites.isEmpty, isTrue);
    });

    test('liked state persists after provider refresh', () async {
      await db.upsertSong(
        SongsCompanion.insert(
          id: const Value(1),
          title: 'Local Song 1',
          filePath: '/path/to/local_song1.mp3',
          isFavorite: const Value(true),
        ),
      );

      final favorites = await db.getFavorites();
      expect(favorites.length, 1);
      expect(favorites.first.isFavorite, isTrue);
    });
  });

  group('Liked Songs - Online Songs', () {
    final onlineSong = Song(
      id: -12345,
      title: 'Online Song 1',
      artist: 'Online Artist 1',
      album: 'Online Album 1',
      duration: 240000,
      filePath: 'https://example.com/online1.mp3',
      albumArtPath: 'https://example.com/art1.png',
      fileSize: 0,
      playCount: 0,
      lastPlayed: null,
      dateAdded: DateTime.now(),
      isFavorite: false,
      sourcePlatform: 'online',
      bitrate: 320,
      mood: null,
      isReported: false,
    );

    test('liking online song inserts row with isFavorite true', () async {
      // 1. Verify song does not exist initially
      final existing = await db.getSongById(onlineSong.id);
      expect(existing, isNull);

      // 2. Toggle using FavoriteHelper
      await FavoriteHelper.toggleFavorite(database: db, song: onlineSong);

      // 3. Verify song is inserted and favorite is true
      final inserted = await db.getSongById(onlineSong.id);
      expect(inserted, isNotNull);
      expect(inserted!.title, 'Online Song 1');
      expect(inserted.isFavorite, isTrue);
    });

    test('liking already inserted online song toggles isFavorite', () async {
      // 1. Insert first
      await FavoriteHelper.toggleFavorite(database: db, song: onlineSong);

      // 2. Toggle again (unlike)
      await FavoriteHelper.toggleFavorite(database: db, song: onlineSong);

      // 3. Verify favorite is toggled to false, but song still exists in DB
      final inserted = await db.getSongById(onlineSong.id);
      expect(inserted, isNotNull);
      expect(inserted!.isFavorite, isFalse);
    });

    test('liked online song appears in watchFavorites stream', () async {
      await FavoriteHelper.toggleFavorite(database: db, song: onlineSong);

      final favorites = await db.watchFavorites().first;
      expect(favorites.length, 1);
      expect(favorites.first.id, onlineSong.id);
      expect(favorites.first.isFavorite, isTrue);
    });

    test('unliking online song sets isFavorite false in DB', () async {
      await FavoriteHelper.toggleFavorite(database: db, song: onlineSong);
      await FavoriteHelper.toggleFavorite(database: db, song: onlineSong);

      final inserted = await db.getSongById(onlineSong.id);
      expect(inserted!.isFavorite, isFalse);
    });
  });

  group('Liked Songs - Edge Cases', () {
    test('DB failure handled gracefully without crash', () async {
      await db.close();
      try {
        final result = await db.getSongById(1);
        expect(result, isNull);
      } catch (e) {
        expect(e, isA<StateError>());
      }
    });

    test('rapid like/unlike calls do not cause race condition', () async {
      final localSong = Song(
        id: 10,
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        duration: 0,
        filePath: 'path',
        albumArtPath: null,
        fileSize: 0,
        playCount: 0,
        lastPlayed: null,
        dateAdded: DateTime.now(),
        isFavorite: false,
        sourcePlatform: null,
        bitrate: 0,
        mood: null,
        isReported: false,
      );

      // Perform multiple toggles in parallel/rapid succession
      await Future.wait([
        FavoriteHelper.toggleFavorite(database: db, song: localSong),
        FavoriteHelper.toggleFavorite(database: db, song: localSong),
        FavoriteHelper.toggleFavorite(database: db, song: localSong),
      ]);

      // Should be either true or false depending on execution ordering, but must not fail/crash
      final result = await db.getSongById(10);
      expect(result, isNotNull);
    });
  });
}
