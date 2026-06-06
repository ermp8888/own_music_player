import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';
import 'tables/songs_table.dart';
import 'tables/playlists_table.dart';
import 'tables/playlist_songs_table.dart';

part 'app_database.g.dart';

/// Main database class using Drift
@DriftDatabase(tables: [Songs, Playlists, PlaylistSongs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Create default smart playlists
          await into(playlists).insert(PlaylistsCompanion.insert(
            name: 'Recently Played',
            description: const Value('Songs you listened to recently'),
            isSmartPlaylist: const Value(true),
            smartPlaylistType: const Value('recently_played'),
          ));
          await into(playlists).insert(PlaylistsCompanion.insert(
            name: 'Most Played',
            description: const Value('Your most played songs'),
            isSmartPlaylist: const Value(true),
            smartPlaylistType: const Value('most_played'),
          ));
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // v1 → v2: Add sourcePlatform, bitrate, mood, isReported columns
            await m.addColumn(songs, songs.sourcePlatform);
            await m.addColumn(songs, songs.bitrate);
            await m.addColumn(songs, songs.mood);
            await m.addColumn(songs, songs.isReported);
          }
        },
      );

  // ============ Songs ============

  /// Get all songs ordered by title
  Future<List<Song>> getAllSongs() {
    return (select(songs)..orderBy([(t) => OrderingTerm.asc(t.title)])).get();
  }

  /// Get song by ID
  Future<Song?> getSongById(int id) {
    return (select(songs)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get song by file path
  Future<Song?> getSongByPath(String path) {
    return (select(songs)..where((t) => t.filePath.equals(path)))
        .getSingleOrNull();
  }

  /// Insert or update song
  Future<int> upsertSong(SongsCompanion song) {
    return into(songs).insertOnConflictUpdate(song);
  }

  /// Delete song
  Future<int> deleteSong(int id) {
    return (delete(songs)..where((t) => t.id.equals(id))).go();
  }

  /// Update play count and last played
  Future<void> updatePlayCount(int songId) async {
    final song = await getSongById(songId);
    if (song != null) {
      await (update(songs)..where((t) => t.id.equals(songId))).write(
        SongsCompanion(
          playCount: Value(song.playCount + 1),
          lastPlayed: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Toggle favorite
  Future<void> toggleFavorite(int songId) async {
    final song = await getSongById(songId);
    if (song != null) {
      await (update(songs)..where((t) => t.id.equals(songId))).write(
        SongsCompanion(isFavorite: Value(!song.isFavorite)),
      );
    }
  }

  /// Rename song title and/or artist
  Future<void> renameSong(int songId, {String? title, String? artist}) async {
    await (update(songs)..where((t) => t.id.equals(songId))).write(
      SongsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        artist: artist != null ? Value(artist) : const Value.absent(),
      ),
    );
  }

  /// Get recently played songs
  Future<List<Song>> getRecentlyPlayed({int limit = 20}) {
    return (select(songs)
          ..where((t) => t.lastPlayed.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.lastPlayed)])
          ..limit(limit))
        .get();
  }

  /// Get most played songs
  Future<List<Song>> getMostPlayed({int limit = 20}) {
    return (select(songs)
          ..where((t) => t.playCount.isBiggerThanValue(0))
          ..orderBy([(t) => OrderingTerm.desc(t.playCount)])
          ..limit(limit))
        .get();
  }

  /// Get favorite songs
  Future<List<Song>> getFavorites() {
    return (select(songs)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .get();
  }

  /// Watch all songs stream
  Stream<List<Song>> watchAllSongs() {
    return (select(songs)..orderBy([(t) => OrderingTerm.asc(t.title)])).watch();
  }

  // ============ Playlists ============

  /// Get all playlists
  Future<List<Playlist>> getAllPlaylists() {
    return (select(playlists)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get user playlists (non-smart)
  Future<List<Playlist>> getUserPlaylists() {
    return (select(playlists)
          ..where((t) => t.isSmartPlaylist.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get smart playlists
  Future<List<Playlist>> getSmartPlaylists() {
    return (select(playlists)
          ..where((t) => t.isSmartPlaylist.equals(true)))
        .get();
  }

  /// Get playlist by ID
  Future<Playlist?> getPlaylistById(int id) {
    return (select(playlists)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Create playlist
  Future<int> createPlaylist(String name, {String? description}) {
    return into(playlists).insert(
      PlaylistsCompanion.insert(
        name: name,
        description: Value(description ?? ''),
      ),
    );
  }

  /// Update playlist
  Future<bool> updatePlaylist(int id, {String? name, String? description}) {
    return (update(playlists)..where((t) => t.id.equals(id)))
        .write(
          PlaylistsCompanion(
            name: name != null ? Value(name) : const Value.absent(),
            description:
                description != null ? Value(description) : const Value.absent(),
            updatedAt: Value(DateTime.now()),
          ),
        )
        .then((rows) => rows > 0);
  }

  /// Delete playlist
  Future<int> deletePlaylist(int id) {
    return (delete(playlists)..where((t) => t.id.equals(id))).go();
  }

  /// Watch all playlists stream
  Stream<List<Playlist>> watchAllPlaylists() {
    return (select(playlists)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  // ============ Playlist Songs ============

  /// Get songs in playlist
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final query = select(playlistSongs).join([
      innerJoin(songs, songs.id.equalsExp(playlistSongs.songId)),
    ])
      ..where(playlistSongs.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistSongs.sortOrder)]);

    final results = await query.get();
    return results.map((row) => row.readTable(songs)).toList();
  }

  /// Add song to playlist
  Future<void> addSongToPlaylist(int playlistId, int songId) async {
    final maxOrder = await (selectOnly(playlistSongs)
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..addColumns([playlistSongs.sortOrder.max()]))
        .getSingleOrNull();

    final nextOrder =
        (maxOrder?.read(playlistSongs.sortOrder.max()) ?? -1) + 1;

    await into(playlistSongs).insert(
      PlaylistSongsCompanion.insert(
        playlistId: playlistId,
        songId: songId,
        sortOrder: nextOrder,
      ),
      mode: InsertMode.insertOrIgnore,
    );

    await (update(playlists)..where((t) => t.id.equals(playlistId)))
        .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
  }

  /// Remove song from playlist
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await (delete(playlistSongs)
          ..where((t) =>
              t.playlistId.equals(playlistId) & t.songId.equals(songId)))
        .go();

    await (update(playlists)..where((t) => t.id.equals(playlistId)))
        .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
  }

  /// Reorder songs in playlist
  Future<void> reorderPlaylistSongs(
      int playlistId, List<int> songIds) async {
    await transaction(() async {
      for (var i = 0; i < songIds.length; i++) {
        await (update(playlistSongs)
              ..where((t) =>
                  t.playlistId.equals(playlistId) &
                  t.songId.equals(songIds[i])))
            .write(PlaylistSongsCompanion(sortOrder: Value(i)));
      }
    });
  }

  /// Get song count in playlist
  Future<int> getPlaylistSongCount(int playlistId) async {
    final count = await (selectOnly(playlistSongs)
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..addColumns([playlistSongs.id.count()]))
        .getSingleOrNull();
    return count?.read(playlistSongs.id.count()) ?? 0;
  }

  /// Watch playlist songs stream
  Stream<List<Song>> watchPlaylistSongs(int playlistId) {
    final query = select(playlistSongs).join([
      innerJoin(songs, songs.id.equalsExp(playlistSongs.songId)),
    ])
      ..where(playlistSongs.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm.asc(playlistSongs.sortOrder)]);

    return query.watch().map((rows) => rows.map((row) => row.readTable(songs)).toList());
  }

  // ============ Report Bad Song ============

  /// Report a song as bad quality
  Future<void> reportSong(int songId) async {
    await (update(songs)..where((t) => t.id.equals(songId)))
        .write(const SongsCompanion(isReported: Value(true)));
  }

  /// Un-report a song
  Future<void> unreportSong(int songId) async {
    await (update(songs)..where((t) => t.id.equals(songId)))
        .write(const SongsCompanion(isReported: Value(false)));
  }

  /// Get all reported songs
  Future<List<Song>> getReportedSongs() async {
    return (select(songs)..where((t) => t.isReported.equals(true))).get();
  }

  /// Delete a song from the database
  Future<void> deleteSongById(int songId) async {
    // First remove from all playlists
    await (delete(playlistSongs)..where((t) => t.songId.equals(songId))).go();
    // Then delete the song
    await (delete(songs)..where((t) => t.id.equals(songId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
