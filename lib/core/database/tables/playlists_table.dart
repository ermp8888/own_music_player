import 'package:drift/drift.dart';

/// Playlists table schema
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get coverArtPath => text().nullable()();
  BoolColumn get isSmartPlaylist => boolean().withDefault(const Constant(false))();
  TextColumn get smartPlaylistType => text().nullable()(); // 'recently_played', 'most_played'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
