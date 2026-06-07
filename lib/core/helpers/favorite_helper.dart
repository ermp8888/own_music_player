import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';

class FavoriteHelper {
  static Future<void> toggleFavorite({
    required AppDatabase database,
    required Song song,
  }) async {
    try {
      final existing = await database.getSongById(song.id);
      if (existing == null) {
        // Song not in DB yet — insert it first with isFavorite = true
        await database.upsertSong(
          SongsCompanion.insert(
            id: Value(song.id),
            title: song.title,
            artist: Value(song.artist),
            album: Value(song.album),
            duration: Value(song.duration),
            filePath: song.filePath,
            albumArtPath: Value(song.albumArtPath),
            isFavorite: const Value(true),
          ),
        );
      } else {
        await database.toggleFavorite(song.id);
      }
    } catch (e) {
      debugPrint('[FavoriteHelper] toggle error: $e');
      rethrow;
    }
  }
}
