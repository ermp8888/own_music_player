/// URL platform detector for DownTune.
///
/// Detects the source platform from a pasted URL:
/// - YouTube standard videos
/// - YouTube Shorts
/// - Instagram Reels and Posts
///
/// Usage:
///   final platform = UrlDetector.detect('https://youtube.com/shorts/abc123');
///   // Returns ContentPlatform.ytShorts
library;

/// Supported content platforms for downloading.
enum ContentPlatform {
  youtube,
  ytShorts,
  instagram,
  unknown;

  /// Human-readable badge label for the UI.
  String get badge {
    switch (this) {
      case ContentPlatform.youtube:
        return 'YT';
      case ContentPlatform.ytShorts:
        return 'YT Shorts';
      case ContentPlatform.instagram:
        return 'Instagram';
      case ContentPlatform.unknown:
        return '';
    }
  }

  /// Serialization value for database storage.
  String get dbValue {
    switch (this) {
      case ContentPlatform.youtube:
        return 'youtube';
      case ContentPlatform.ytShorts:
        return 'yt_shorts';
      case ContentPlatform.instagram:
        return 'instagram';
      case ContentPlatform.unknown:
        return 'unknown';
    }
  }

  /// Deserialize from database value.
  static ContentPlatform fromDbValue(String? value) {
    switch (value) {
      case 'youtube':
        return ContentPlatform.youtube;
      case 'yt_shorts':
        return ContentPlatform.ytShorts;
      case 'instagram':
        return ContentPlatform.instagram;
      default:
        return ContentPlatform.unknown;
    }
  }
}

/// Detects the content platform from a URL string.
class UrlDetector {
  // YouTube patterns
  static final _ytVideoRegex = RegExp(
    r'^https?://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[a-zA-Z0-9_-]+',
    caseSensitive: false,
  );

  static final _ytShortsRegex = RegExp(
    r'^https?://(www\.)?youtube\.com/shorts/[a-zA-Z0-9_-]+',
    caseSensitive: false,
  );

  // Instagram patterns
  static final _instagramRegex = RegExp(
    r'^https?://(www\.)?instagram\.com/(reel|p)/[a-zA-Z0-9_-]+',
    caseSensitive: false,
  );

  /// Detect the platform from a URL string.
  ///
  /// Returns [ContentPlatform.unknown] for null, empty, or unrecognized URLs.
  /// Automatically trims whitespace from the input.
  static ContentPlatform detect(String? url) {
    if (url == null || url.trim().isEmpty) {
      return ContentPlatform.unknown;
    }

    final trimmed = url.trim();

    // Check YouTube Shorts FIRST (before general YouTube — it's more specific)
    if (_ytShortsRegex.hasMatch(trimmed)) {
      return ContentPlatform.ytShorts;
    }

    // Check standard YouTube
    if (_ytVideoRegex.hasMatch(trimmed)) {
      return ContentPlatform.youtube;
    }

    // Check Instagram
    if (_instagramRegex.hasMatch(trimmed)) {
      return ContentPlatform.instagram;
    }

    return ContentPlatform.unknown;
  }

  /// Extract the video/content ID from a detected URL.
  ///
  /// Returns null if the URL is not recognized.
  static String? extractId(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();
    final platform = detect(trimmed);

    switch (platform) {
      case ContentPlatform.youtube:
        return _extractYoutubeId(trimmed);
      case ContentPlatform.ytShorts:
        return _extractYoutubeShortsId(trimmed);
      case ContentPlatform.instagram:
        return _extractInstagramId(trimmed);
      case ContentPlatform.unknown:
        return null;
    }
  }

  static String? _extractYoutubeId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtube.com/watch?v=ID
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }

    // youtu.be/ID
    if (uri.host.contains('youtu.be')) {
      final segments = uri.pathSegments;
      return segments.isNotEmpty ? segments.first : null;
    }

    return null;
  }

  static String? _extractYoutubeShortsId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // youtube.com/shorts/ID
    final segments = uri.pathSegments;
    final shortsIndex = segments.indexOf('shorts');
    if (shortsIndex != -1 && shortsIndex + 1 < segments.length) {
      return segments[shortsIndex + 1];
    }

    return null;
  }

  static String? _extractInstagramId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // instagram.com/reel/ID or instagram.com/p/ID
    final segments = uri.pathSegments;
    final reelIndex = segments.indexOf('reel');
    final postIndex = segments.indexOf('p');
    final contentIndex = reelIndex != -1 ? reelIndex : postIndex;

    if (contentIndex != -1 && contentIndex + 1 < segments.length) {
      return segments[contentIndex + 1];
    }

    return null;
  }
}
