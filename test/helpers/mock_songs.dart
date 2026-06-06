/// Pre-defined mock Song objects for testing.
///
/// Contains 30 songs covering: good quality, below threshold, duplicates,
/// devotional/blacklisted, dirty titles, null fields, and Devanagari script.
library;

/// Lightweight song model for testing without Drift dependency.
/// Mirrors the fields in the Songs table.
class MockSong {
  final int id;
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final int duration; // milliseconds
  final int fileSize; // bytes
  final String? albumArtPath;
  final int playCount;
  final DateTime? lastPlayed;
  final DateTime dateAdded;
  final bool isFavorite;
  final String? sourcePlatform;
  final int bitrate; // kbps
  final String? mood;
  final bool isReported;

  const MockSong({
    required this.id,
    required this.filePath,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.duration = 0,
    this.fileSize = 0,
    this.albumArtPath,
    this.playCount = 0,
    this.lastPlayed,
    DateTime? dateAdded,
    this.isFavorite = false,
    this.sourcePlatform,
    this.bitrate = 0,
    this.mood,
    this.isReported = false,
  }) : dateAdded = dateAdded ?? const _DefaultDate();
}

/// Sentinel for default date in const constructors.
class _DefaultDate implements DateTime {
  const _DefaultDate();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ============================================================
// GOOD QUALITY SONGS (should pass all filters)
// ============================================================

const goodSongs = [
  MockSong(
    id: 1,
    filePath: '/music/tum_hi_ho.mp3',
    title: 'Tum Hi Ho',
    artist: 'Arijit Singh',
    album: 'Aashiqui 2',
    duration: 261000, // 4:21
    fileSize: 8400000, // ~8MB
    bitrate: 320,
  ),
  MockSong(
    id: 2,
    filePath: '/music/shape_of_you.mp3',
    title: 'Shape of You',
    artist: 'Ed Sheeran',
    album: 'Divide',
    duration: 234000, // 3:54
    fileSize: 7500000,
    bitrate: 256,
  ),
  MockSong(
    id: 3,
    filePath: '/music/perfect.mp3',
    title: 'Perfect',
    artist: 'Ed Sheeran',
    album: 'Divide',
    duration: 263000,
    fileSize: 8400000,
    bitrate: 320,
  ),
  MockSong(
    id: 4,
    filePath: '/music/blinding_lights.mp3',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    album: 'After Hours',
    duration: 200000,
    fileSize: 6400000,
    bitrate: 256,
  ),
  MockSong(
    id: 5,
    filePath: '/music/kesariya.mp3',
    title: 'Kesariya',
    artist: 'Arijit Singh',
    album: 'Brahmastra',
    duration: 268000,
    fileSize: 8600000,
    bitrate: 320,
  ),
];

// ============================================================
// BELOW QUALITY THRESHOLD (should fail quality filter)
// ============================================================

const lowQualitySongs = [
  // Low bitrate
  MockSong(
    id: 101,
    filePath: '/music/low_bitrate.mp3',
    title: 'Low Bitrate Song',
    artist: 'Artist A',
    duration: 180000,
    fileSize: 2000000,
    bitrate: 64,
  ),
  // Too short (< 60 seconds)
  MockSong(
    id: 102,
    filePath: '/music/too_short.mp3',
    title: 'Too Short',
    artist: 'Artist B',
    duration: 45000, // 45s
    fileSize: 5000000,
    bitrate: 320,
  ),
  // Too long (> 600 seconds)
  MockSong(
    id: 103,
    filePath: '/music/too_long.mp3',
    title: 'Too Long Podcast',
    artist: 'Artist C',
    duration: 720000, // 12 minutes
    fileSize: 23000000,
    bitrate: 320,
  ),
  // Too small file (< 1MB)
  MockSong(
    id: 104,
    filePath: '/music/tiny.mp3',
    title: 'Tiny File',
    artist: 'Artist D',
    duration: 120000,
    fileSize: 500000, // 0.5MB
    bitrate: 128,
  ),
  // Boundary: exactly 127kbps (below 128 minimum)
  MockSong(
    id: 105,
    filePath: '/music/boundary_bitrate.mp3',
    title: 'Boundary Bitrate',
    artist: 'Artist E',
    duration: 180000,
    fileSize: 3000000,
    bitrate: 127,
  ),
  // Boundary: 59s (below 60s minimum)
  MockSong(
    id: 106,
    filePath: '/music/boundary_short.mp3',
    title: 'Almost Long Enough',
    artist: 'Artist F',
    duration: 59000,
    fileSize: 5000000,
    bitrate: 320,
  ),
  // Boundary: 601s (above 600s maximum)
  MockSong(
    id: 107,
    filePath: '/music/boundary_long.mp3',
    title: 'Slightly Too Long',
    artist: 'Artist G',
    duration: 601000,
    fileSize: 20000000,
    bitrate: 320,
  ),
];

// ============================================================
// DUPLICATE PAIRS (should trigger duplicate detection)
// ============================================================

const duplicateSongs = [
  // Original
  MockSong(
    id: 201,
    filePath: '/music/original.mp3',
    title: 'Tum Hi Ho',
    artist: 'Arijit Singh',
    duration: 261000,
    fileSize: 8400000,
    bitrate: 320,
  ),
  // Duplicate: same title, duration within 5s, lower quality
  MockSong(
    id: 202,
    filePath: '/music/duplicate_lower.mp3',
    title: 'Tum Hi Ho',
    artist: 'Arijit Singh',
    duration: 263000, // +2s
    fileSize: 4200000,
    bitrate: 128,
  ),
  // NOT duplicate: same title but duration 7s different
  MockSong(
    id: 203,
    filePath: '/music/not_duplicate.mp3',
    title: 'Tum Hi Ho',
    artist: 'Arijit Singh',
    duration: 268000, // +7s
    fileSize: 8600000,
    bitrate: 320,
  ),
  // Duplicate with punctuation: "Song!" vs "Song"
  MockSong(
    id: 204,
    filePath: '/music/song_excl.mp3',
    title: 'Perfect!',
    artist: 'Ed Sheeran',
    duration: 263000,
    fileSize: 8000000,
    bitrate: 256,
  ),
  MockSong(
    id: 205,
    filePath: '/music/song_no_excl.mp3',
    title: 'Perfect',
    artist: 'Ed Sheeran',
    duration: 263000,
    fileSize: 8400000,
    bitrate: 320,
  ),
  // Duplicate with case: "SONG" vs "song"
  MockSong(
    id: 206,
    filePath: '/music/song_upper.mp3',
    title: 'BLINDING LIGHTS',
    artist: 'The Weeknd',
    duration: 200000,
    fileSize: 6400000,
    bitrate: 256,
  ),
  MockSong(
    id: 207,
    filePath: '/music/song_lower.mp3',
    title: 'blinding lights',
    artist: 'The Weeknd',
    duration: 201000, // +1s
    fileSize: 6400000,
    bitrate: 320,
  ),
];

// ============================================================
// DEVOTIONAL / BLACKLISTED SONGS (should fail blacklist filter)
// ============================================================

const blacklistedSongs = [
  MockSong(
    id: 301,
    filePath: '/music/hanuman_chalisa.mp3',
    title: 'Hanuman Chalisa',
    artist: 'Gulshan Kumar',
    duration: 540000,
    fileSize: 17000000,
    bitrate: 256,
  ),
  MockSong(
    id: 302,
    filePath: '/music/shiv_bhajan.mp3',
    title: 'Shiv Bhajan Collection',
    artist: 'Anup Jalota',
    duration: 420000,
    fileSize: 13000000,
    bitrate: 256,
  ),
  MockSong(
    id: 303,
    filePath: '/music/karaoke.mp3',
    title: 'Best Karaoke Songs',
    artist: 'Various',
    duration: 300000,
    fileSize: 9600000,
    bitrate: 256,
  ),
  MockSong(
    id: 304,
    filePath: '/music/aarti.mp3',
    title: 'Om Jai Jagdish Hare',
    artist: 'Aarti Devi', // Artist triggers blacklist
    duration: 240000,
    fileSize: 7700000,
    bitrate: 256,
  ),
  // Devanagari script
  MockSong(
    id: 305,
    filePath: '/music/hanuman_hindi.mp3',
    title: 'हनुमान चालीसा',
    artist: 'गुलशन कुमार',
    duration: 540000,
    fileSize: 17000000,
    bitrate: 256,
  ),
  // Lowercase blacklist
  MockSong(
    id: 306,
    filePath: '/music/mantra.mp3',
    title: 'gayatri mantra meditation',
    artist: 'Deva Premal',
    duration: 300000,
    fileSize: 9600000,
    bitrate: 256,
  ),
];

// ============================================================
// DIRTY TITLES (need cleaning)
// ============================================================

const dirtySongs = [
  MockSong(
    id: 401,
    filePath: '/music/html_entities.mp3',
    title: 'Shape of You &amp; Perfect &quot;Live&quot;',
    artist: 'Ed Sheeran',
    duration: 234000,
    fileSize: 7500000,
    bitrate: 256,
  ),
  MockSong(
    id: 402,
    filePath: '/music/url_encoded.mp3',
    title: 'tum+hi+ho+arijit+singh',
    artist: 'Unknown Artist',
    duration: 261000,
    fileSize: 8400000,
    bitrate: 320,
  ),
  MockSong(
    id: 403,
    filePath: '/music/extra_spaces.mp3',
    title: '  Shape   of   You  ',
    artist: '  Ed Sheeran  ',
    duration: 234000,
    fileSize: 7500000,
    bitrate: 256,
  ),
];

// ============================================================
// SONGS WITH NULL/ZERO FIELDS (edge cases)
// ============================================================

const nullFieldSongs = [
  MockSong(
    id: 501,
    filePath: '/music/no_duration.mp3',
    title: 'No Duration Song',
    artist: 'Artist X',
    duration: 0,
    fileSize: 5000000,
    bitrate: 256,
  ),
  MockSong(
    id: 502,
    filePath: '/music/no_bitrate.mp3',
    title: 'No Bitrate Song',
    artist: 'Artist Y',
    duration: 180000,
    fileSize: 5000000,
    bitrate: 0,
  ),
  MockSong(
    id: 503,
    filePath: '/music/empty_title.mp3',
    title: '',
    artist: 'Artist Z',
    duration: 180000,
    fileSize: 5000000,
    bitrate: 256,
  ),
];

// ============================================================
// ALL MOCK SONGS (combined for integration tests)
// ============================================================

const allMockSongs = [
  ...goodSongs,
  ...lowQualitySongs,
  ...duplicateSongs,
  ...blacklistedSongs,
  ...dirtySongs,
  ...nullFieldSongs,
];
