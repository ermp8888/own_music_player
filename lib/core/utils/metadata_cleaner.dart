/// Metadata cleaner utility for song titles and artist names.
///
/// Cleans up common issues from YouTube/online sources:
/// - HTML entities (&amp;, &quot;, etc.)
/// - URL encoding (+, %20, etc.)
/// - Suffixes like (Official Video), [HD], (Lyrics)
/// - Extra whitespace
/// - "Artist - Title" format extraction
library;

/// Cleans a song title by removing common junk.
String cleanSongTitle(String title) {
  var clean = title;

  // 1. Decode HTML entities
  clean = _decodeHtmlEntities(clean);

  // 2. Replace URL encoding: + → space
  clean = clean.replaceAll('+', ' ');

  // 3. Remove common suffixes/tags in parentheses and brackets
  clean = clean.replaceAll(
    RegExp(
      r'\s*[\(\[]\s*(official\s*(video|audio|music\s*video|lyric\s*video|hd|4k)|'
      r'lyrics?|lyric\s*video|hd|4k|uhd|full\s*(song|video)|audio|'
      r'video\s*song|visualizer|animated|extended|remastered)\s*[\)\]]',
      caseSensitive: false,
    ),
    '',
  );

  // 4. Remove trailing " - YouTube" or similar platform suffixes
  clean = clean.replaceAll(RegExp(r'\s*-\s*YouTube\s*$', caseSensitive: false), '');

  // 5. Normalize whitespace
  clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

  return clean;
}

/// Extracts the artist from an "Artist - Title" formatted string.
/// Returns null if no separator found.
String? extractArtistFromTitle(String title) {
  // Common separators: " - ", " – ", " — ", " | "
  final separators = [' - ', ' – ', ' — ', ' | '];
  for (final sep in separators) {
    if (title.contains(sep)) {
      final parts = title.split(sep);
      if (parts.length >= 2) {
        return cleanSongTitle(parts[0].trim());
      }
    }
  }
  return null;
}

/// Extracts the song title from an "Artist - Title" formatted string.
/// Returns the cleaned full string if no separator found.
String extractTitleFromArtistTitle(String fullTitle) {
  final separators = [' - ', ' – ', ' — ', ' | '];
  for (final sep in separators) {
    if (fullTitle.contains(sep)) {
      final parts = fullTitle.split(sep);
      if (parts.length >= 2) {
        return cleanSongTitle(parts.sublist(1).join(sep).trim());
      }
    }
  }
  return cleanSongTitle(fullTitle);
}

/// Cleans an artist name.
String cleanArtist(String artist) {
  var clean = artist;

  // 1. Decode HTML entities
  clean = _decodeHtmlEntities(clean);

  // 2. Replace + with space
  clean = clean.replaceAll('+', ' ');

  // 3. Remove " - Topic" suffix (YouTube auto-generated channels)
  clean = clean.replaceAll(RegExp(r'\s*-\s*Topic\s*$', caseSensitive: false), '');

  // 4. Remove "VEVO" suffix
  clean = clean.replaceAll(RegExp(r'VEVO\s*$', caseSensitive: false), '');

  // 5. Normalize whitespace
  clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

  return clean;
}

/// Decode common HTML entities.
String _decodeHtmlEntities(String text) {
  return text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&#x2F;', '/')
      .replaceAll('&nbsp;', ' ');
}
