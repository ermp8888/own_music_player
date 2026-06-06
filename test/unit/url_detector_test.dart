import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/services/url_detector.dart';

void main() {
  group('UrlDetector.detect', () {
    // ═══════════════════════════════════════════
    // HAPPY PATH
    // ═══════════════════════════════════════════

    test('standard YouTube URL → YOUTUBE', () {
      expect(
        UrlDetector.detect('https://youtube.com/watch?v=abc123'),
        ContentPlatform.youtube,
      );
    });

    test('YouTube Shorts URL → YT_SHORTS', () {
      expect(
        UrlDetector.detect('https://youtube.com/shorts/abc123'),
        ContentPlatform.ytShorts,
      );
    });

    test('youtu.be short URL → YOUTUBE', () {
      expect(
        UrlDetector.detect('https://youtu.be/abc123'),
        ContentPlatform.youtube,
      );
    });

    test('Instagram Reel URL → INSTAGRAM', () {
      expect(
        UrlDetector.detect('https://instagram.com/reel/abc123'),
        ContentPlatform.instagram,
      );
    });

    test('Instagram Post URL → INSTAGRAM', () {
      expect(
        UrlDetector.detect('https://instagram.com/p/abc123'),
        ContentPlatform.instagram,
      );
    });

    test('Instagram with www prefix → INSTAGRAM', () {
      expect(
        UrlDetector.detect('https://www.instagram.com/reel/abc123/'),
        ContentPlatform.instagram,
      );
    });

    test('YouTube with www prefix → YOUTUBE', () {
      expect(
        UrlDetector.detect('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        ContentPlatform.youtube,
      );
    });

    // ═══════════════════════════════════════════
    // EDGE CASES
    // ═══════════════════════════════════════════

    test('empty string → UNKNOWN, no crash', () {
      expect(UrlDetector.detect(''), ContentPlatform.unknown);
    });

    test('null URL → UNKNOWN, no crash', () {
      expect(UrlDetector.detect(null), ContentPlatform.unknown);
    });

    test('invalid URL "notaurl" → UNKNOWN', () {
      expect(UrlDetector.detect('notaurl'), ContentPlatform.unknown);
    });

    test('partial URL "youtube.com/watch" (no video ID) → UNKNOWN', () {
      expect(UrlDetector.detect('youtube.com/watch'), ContentPlatform.unknown);
    });

    test('URL with extra params → YOUTUBE', () {
      expect(
        UrlDetector.detect('https://youtube.com/watch?v=x&list=y'),
        ContentPlatform.youtube,
      );
    });

    test('URL with uppercase → YT_SHORTS', () {
      expect(
        UrlDetector.detect('HTTPS://YOUTUBE.COM/SHORTS/X'),
        ContentPlatform.ytShorts,
      );
    });

    test('whitespace around URL → YOUTUBE (auto-trim)', () {
      expect(
        UrlDetector.detect('  https://youtube.com/watch?v=x  '),
        ContentPlatform.youtube,
      );
    });

    test('HTTP (not HTTPS) YouTube URL → YOUTUBE', () {
      expect(
        UrlDetector.detect('http://youtube.com/watch?v=abc'),
        ContentPlatform.youtube,
      );
    });

    test('Instagram with trailing slash → INSTAGRAM', () {
      expect(
        UrlDetector.detect('https://instagram.com/reel/CxYzAbCdEfG/'),
        ContentPlatform.instagram,
      );
    });

    test('random website URL → UNKNOWN', () {
      expect(
        UrlDetector.detect('https://google.com/search?q=music'),
        ContentPlatform.unknown,
      );
    });
  });

  group('UrlDetector.extractId', () {
    test('YouTube watch URL extracts video ID', () {
      expect(
        UrlDetector.extractId('https://youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('youtu.be URL extracts video ID', () {
      expect(
        UrlDetector.extractId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('YouTube Shorts extracts video ID', () {
      expect(
        UrlDetector.extractId('https://youtube.com/shorts/abc123'),
        'abc123',
      );
    });

    test('Instagram Reel extracts content ID', () {
      expect(
        UrlDetector.extractId('https://instagram.com/reel/CxYzAbCd'),
        'CxYzAbCd',
      );
    });

    test('Instagram Post extracts content ID', () {
      expect(
        UrlDetector.extractId('https://instagram.com/p/CxYzAbCd'),
        'CxYzAbCd',
      );
    });

    test('null URL returns null', () {
      expect(UrlDetector.extractId(null), isNull);
    });

    test('empty URL returns null', () {
      expect(UrlDetector.extractId(''), isNull);
    });

    test('unknown URL returns null', () {
      expect(UrlDetector.extractId('https://google.com'), isNull);
    });
  });

  group('ContentPlatform', () {
    test('badge labels are correct', () {
      expect(ContentPlatform.youtube.badge, 'YT');
      expect(ContentPlatform.ytShorts.badge, 'YT Shorts');
      expect(ContentPlatform.instagram.badge, 'Instagram');
      expect(ContentPlatform.unknown.badge, '');
    });

    test('dbValue serialization round-trip', () {
      for (final platform in ContentPlatform.values) {
        final serialized = platform.dbValue;
        final deserialized = ContentPlatform.fromDbValue(serialized);
        expect(deserialized, platform);
      }
    });

    test('fromDbValue with null → unknown', () {
      expect(ContentPlatform.fromDbValue(null), ContentPlatform.unknown);
    });

    test('fromDbValue with garbage → unknown', () {
      expect(ContentPlatform.fromDbValue('tiktok'), ContentPlatform.unknown);
    });
  });
}
