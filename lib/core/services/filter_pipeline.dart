import 'dart:async';
import '../database/app_database.dart';
import '../constants/blacklist_keywords.dart';
import 'gemini_service.dart';

/// Settings model for the filter pipeline.
class FilterSettings {
  final bool blockDevotional;
  final bool blockKaraoke;
  final bool blockRemixes;
  final bool blockInstrumentals;
  final bool blockShorts;

  const FilterSettings({
    this.blockDevotional = true,
    this.blockKaraoke = true,
    this.blockRemixes = false,
    this.blockInstrumentals = false,
    this.blockShorts = true,
  });
}

/// A pipeline that filters songs based on quality, duplicates, blacklist, and AI validation.
class FilterPipeline {
  final GeminiService? _geminiService;

  FilterPipeline({GeminiService? geminiService}) : _geminiService = geminiService;

  // ──────────────────────────────────────────────────────────
  // STEP 1: Quality Filter
  // ──────────────────────────────────────────────────────────

  /// Returns true if the song passes the quality filter.
  bool passQualityFilter(dynamic song, {FilterSettings settings = const FilterSettings()}) {
    if (song == null) return false;

    int? bitrate;
    int? duration;
    int? fileSize;

    if (song is Song) {
      bitrate = song.bitrate;
      duration = song.duration;
      fileSize = song.fileSize;
    } else if (song is Map) {
      bitrate = song['bitrate'] as int?;
      duration = song['duration'] as int?;
      fileSize = song['fileSize'] as int?;
    } else {
      try {
        bitrate = song.bitrate as int?;
        duration = song.duration as int?;
        fileSize = song.fileSize as int?;
      } catch (_) {
        return false;
      }
    }

    // Check bitrate (boundary: exactly 128 passes, null/0 fails gracefully)
    if (bitrate == null || bitrate < 128) {
      return false;
    }

    // Check duration in seconds (Drift uses milliseconds, so convert)
    // boundary: exactly 60s passes, 600s passes.
    if (duration == null) return false;
    
    final durationSeconds = duration / 1000.0;

    if (durationSeconds > 0.0) {
      // Shorts/clips filter: if blockShorts is enabled, block songs under 60 seconds
      if (settings.blockShorts && durationSeconds < 60.0) {
        return false;
      } else if (!settings.blockShorts && durationSeconds < 1.0) {
        // General safety fallback if blockShorts is OFF: reject empty/0 duration
        return false;
      }

      if (durationSeconds > 600.0) {
        return false;
      }
    }

    // Check file size (boundary: < 1 MB fails)
    // 1 MB = 1024 * 1024 bytes = 1048576 bytes
    if (fileSize == null || fileSize < 1024 * 1024) {
      return false;
    }

    return true;
  }

  // ──────────────────────────────────────────────────────────
  // STEP 2: Duplicate Detection
  // ──────────────────────────────────────────────────────────

  /// Normalizes a string by converting to lowercase and removing special characters/punctuation.
  String normalizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0900-\u097F]'), '') // Keeps alphanumeric + Devanagari script
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Identifies duplicates and filters the list, keeping the higher quality version.
  List<dynamic> filterDuplicates(List<dynamic> songs) {
    if (songs.isEmpty) return [];

    final Map<String, dynamic> uniqueSongs = {};

    for (final song in songs) {
      if (song == null) continue;
      final title = song.title;
      if (title == null) continue;
      
      final normTitle = normalizeString(title);
      final duration = song.duration;
      if (duration == null) continue;
      
      final durationSec = duration / 1000.0;

      // Find if we already have a song with the same normalized title and duration within 5s
      String? duplicateKey;
      for (final existingKey in uniqueSongs.keys) {
        final existingSong = uniqueSongs[existingKey]!;
        final existingTitle = existingSong.title;
        if (existingTitle == null) continue;
        
        final existingNormTitle = normalizeString(existingTitle);
        final existingDuration = existingSong.duration;
        if (existingDuration == null) continue;
        
        final existingDurationSec = existingDuration / 1000.0;

        if (existingNormTitle == normTitle && (existingDurationSec - durationSec).abs() <= 5.0) {
          duplicateKey = existingKey;
          break;
        }
      }

      if (duplicateKey != null) {
        final existingSong = uniqueSongs[duplicateKey]!;
        final bitrate = song.bitrate ?? 0;
        final existingBitrate = existingSong.bitrate ?? 0;
        
        // Keep the one with the higher bitrate (quality)
        if (bitrate > existingBitrate) {
          uniqueSongs.remove(duplicateKey);
          uniqueSongs['$normTitle-$durationSec'] = song;
        }
      } else {
        uniqueSongs['$normTitle-$durationSec'] = song;
      }
    }

    return uniqueSongs.values.toList();
  }

  // ──────────────────────────────────────────────────────────
  // STEP 3: Keyword Blacklist Filter
  // ──────────────────────────────────────────────────────────

  /// Returns true if the song title or artist matches any blacklist keyword.
  /// Accepts a Song object or any object with title/artist String properties.
  bool isBlacklisted(dynamic song, {FilterSettings settings = const FilterSettings()}) {
    if (song == null) return false;
    
    String title;
    String artist;
    
    if (song is Song) {
      title = song.title.toLowerCase();
      artist = song.artist.toLowerCase();
    } else if (song is Map) {
      title = ((song['title'] as String?) ?? '').toLowerCase();
      artist = ((song['artist'] as String?) ?? '').toLowerCase();
    } else {
      try {
        title = (song.title as String? ?? '').toLowerCase();
        artist = (song.artist as String? ?? '').toLowerCase();
      } catch (_) {
        return false;
      }
    }

    if (title.isEmpty) return false;

    // 1. Devotional content check
    if (settings.blockDevotional) {
      for (final word in devotionalKeywords) {
        if (title.contains(word) || artist.contains(word)) return true;
      }
      for (final word in devotionalDevanagariKeywords) {
        if (title.contains(word) || artist.contains(word)) return true;
      }
    }

    // 2. Karaoke check
    if (settings.blockKaraoke) {
      if (title.contains('karaoke') || artist.contains('karaoke') ||
          title.contains('कराओके') || artist.contains('कराओके')) {
        return true;
      }
    }

    // 3. Covers check
    if (settings.blockKaraoke) {
      if (title.contains('cover') || artist.contains('cover')) {
        return true;
      }
    }

    // 4. Remixes check
    if (settings.blockRemixes) {
      if (title.contains('remix') || artist.contains('remix')) {
        return true;
      }
    }

    // 5. Instrumentals check
    if (settings.blockInstrumentals) {
      if (title.contains('instrumental') || artist.contains('instrumental') ||
          title.contains('bgm') || title.contains('theme')) {
        return true;
      }
    }

    // 6. Generic unwanted keywords
    for (final word in unwantedKeywords) {
      if (title.contains(word) || artist.contains(word)) return true;
    }
    for (final word in unwantedDevanagariKeywords) {
      if (title.contains(word) || artist.contains(word)) return true;
    }

    return false;
  }

  // ──────────────────────────────────────────────────────────
  // STEP 4: AI Filter using Gemini API
  // ──────────────────────────────────────────────────────────

  /// Calls Gemini API to check if a song should be blocked.
  ///
  /// Safe fallback: If timeout, error, or unexpected text, it returns true (blocks the song).
  Future<bool> passGeminiFilter(dynamic song) async {
    if (song == null) return false;
    if (_geminiService == null) {
      // Safe fallback if API is not configured: block the song to be safe
      return false;
    }

    final title = song.title;
    final artist = song.artist;
    if (title == null) return false;

    final prompt = 'Is this a Hindu devotional song, bhajan, aarti, mantra, karaoke, '
        'ringtone, or any non-mainstream music content? Also check if the '
        'title is in Devanagari script and represents religious content. '
        'Reply only YES or NO.\n\n'
        'Title: "$title"\n'
        'Artist: "${artist ?? ''}"';

    try {
      final responseText = await _geminiService
          .generateContent(prompt)
          .timeout(const Duration(seconds: 5));

      final text = responseText?.trim().toUpperCase();
      if (text == 'NO') {
        return true; // Pass
      }
      return false; // Block
    } catch (_) {
      // Safe fallback on timeout or error
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────
  // PIPELINE INTEGRATION
  // ──────────────────────────────────────────────────────────

  /// Filters a list of songs using the full pipeline.
  Future<List<Song>> filterSongs(List<Song> songs, {FilterSettings settings = const FilterSettings()}) async {
    final List<Song> qualityFiltered = [];

    // Step 1: Quality Filter + Step 3: Blacklist Filter
    for (final song in songs) {
      if (passQualityFilter(song, settings: settings) && !isBlacklisted(song, settings: settings)) {
        qualityFiltered.add(song);
      }
    }

    // Step 2: Duplicate Detection
    final uniqueSongs = filterDuplicates(qualityFiltered);

    // Step 4: AI Filter (for remaining songs)
    final List<Song> finalSongs = [];
    for (final song in uniqueSongs) {
      final passedAI = await passGeminiFilter(song);
      if (passedAI) {
        finalSongs.add(song);
      }
    }

    return finalSongs;
  }
}
