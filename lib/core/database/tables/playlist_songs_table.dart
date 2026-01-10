import 'package:drift/drift.dart';

import 'songs_table.dart';
import 'playlists_table.dart';

/// Junction table for playlist-song relationships
@DataClassName('PlaylistSongEntry')
class PlaylistSongs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId => integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get songId => integer().references(Songs, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, songId},
      ];
}
