/// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'DownTune';
  static const String appVersion = '1.0.0';

  // Supported audio formats
  static const List<String> supportedFormats = [
    'mp3',
    'm4a',
    'wav',
    'flac',
    'aac',
    'ogg',
  ];

  // Database
  static const String databaseName = 'my_music_app.db';
  static const int databaseVersion = 2;

  // Disclaimer
  static const String youtubeDisclaimer = '''
This feature is for educational use only.
Only download content you own or have rights to.
By continuing, you confirm you have the legal right
to download and use this content.
''';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Player
  static const double miniPlayerHeight = 72.0;
  static const double seekBarHeight = 4.0;

  // Storage keys
  static const String disclaimerAcceptedKey = 'youtube_disclaimer_accepted';
  static const String lastPlayedSongKey = 'last_played_song_id';
  static const String shuffleModeKey = 'shuffle_mode';
  static const String repeatModeKey = 'repeat_mode';

  // Filter settings keys
  static const String filterDevotionalKey = 'filter_devotional';
  static const String filterKaraokeKey = 'filter_karaoke';
  static const String filterRemixesKey = 'filter_remixes';
  static const String filterInstrumentalsKey = 'filter_instrumentals';
  static const String filterShortsKey = 'filter_shorts';

  // Sleep timer
  static const List<int> sleepTimerOptions = [15, 30, 45, 60];
}
