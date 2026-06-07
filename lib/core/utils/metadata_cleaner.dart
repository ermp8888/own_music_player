/// Metadata cleaner utility for song titles and artist names.
class MetadataCleaner {
  MetadataCleaner._();

  static String cleanTitle(String raw) {
    var cleaned = raw
        .replaceAll('+', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'\(Official Video\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Full Video\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Audio\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Lyric Video\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(HD\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned;
  }

  static String cleanArtist(String? artist) {
    if (artist == null || artist.trim().isEmpty || artist == 'Unknown Artist') {
      return 'Unknown Artist';
    }
    return cleanTitle(artist);
  }

  static Map<String, String> extractFromFilename(String filename) {
    if (filename.isEmpty) {
      return {
        'artist': 'Unknown Artist',
        'title': '',
      };
    }
    if (!filename.contains(' - ')) {
      return {
        'artist': 'Unknown Artist',
        'title': filename.trim(),
      };
    }
    final index = filename.indexOf(' - ');
    final artist = filename.substring(0, index).trim();
    final title = filename.substring(index + 3).trim();
    return {
      'artist': artist.isEmpty ? 'Unknown Artist' : artist,
      'title': title,
    };
  }

  /// Cleans both title and artist and tries to extract artist from title if necessary
  static Map<String, String> cleanSong(String title, String? artist) {
    var cleanTitleStr = cleanTitle(title);
    var cleanArtistStr = cleanArtist(artist);

    if (cleanArtistStr == 'Unknown Artist' && cleanTitleStr.contains(' - ')) {
      final extracted = extractFromFilename(cleanTitleStr);
      cleanArtistStr = cleanArtist(extracted['artist']);
      cleanTitleStr = cleanTitle(extracted['title'] ?? '');
    }

    return {
      'title': cleanTitleStr,
      'artist': cleanArtistStr,
    };
  }
}

/// Backward compatibility global aliases
String cleanSongTitle(String title) => MetadataCleaner.cleanTitle(title);
String cleanArtist(String? artist) => MetadataCleaner.cleanArtist(artist);

String? extractArtistFromTitle(String title) {
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
