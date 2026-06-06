import 'package:drift/drift.dart';

/// Songs table schema for storing local music metadata
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text().unique()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant('Unknown Artist'))();
  TextColumn get album => text().withDefault(const Constant('Unknown Album'))();
  IntColumn get duration => integer().withDefault(const Constant(0))();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get albumArtPath => text().nullable()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayed => dateTime().nullable()();
  DateTimeColumn get dateAdded => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Source platform: 'youtube', 'yt_shorts', 'instagram', 'local', 'online'
  TextColumn get sourcePlatform => text().nullable()();

  /// Audio bitrate in kbps (0 = unknown)
  IntColumn get bitrate => integer().withDefault(const Constant(0))();

  /// AI-detected mood tag: 'happy', 'sad', 'chill', 'energetic', 'romantic'
  TextColumn get mood => text().nullable()();

  /// Whether the user has reported this song as bad/unwanted
  BoolColumn get isReported => boolean().withDefault(const Constant(false))();
}
