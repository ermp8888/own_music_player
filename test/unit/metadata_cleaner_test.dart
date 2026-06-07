import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/utils/metadata_cleaner.dart';

void main() {
  group('MetadataCleaner', () {
    group('cleanSongTitle', () {
      test('replaces + with space', () {
        expect(
          MetadataCleaner.cleanTitle('Tum+Hi+Ho'),
          'Tum Hi Ho',
        );
      });

      test('fixes &quot; HTML entity', () {
        expect(
          MetadataCleaner.cleanTitle('Song from &quot;Movie&quot;'),
          'Song from "Movie"',
        );
      });

      test('fixes &amp; HTML entity', () {
        expect(
          MetadataCleaner.cleanTitle('Rock &amp; Roll'),
          'Rock & Roll',
        );
      });

      test('removes (Official Video) suffix', () {
        expect(
          MetadataCleaner.cleanTitle('Tum Hi Ho (Official Video)'),
          'Tum Hi Ho',
        );
      });

      test('removes (Full Video) suffix', () {
        expect(
          MetadataCleaner.cleanTitle('Song Name (Full Video)'),
          'Song Name',
        );
      });

      test('removes (Audio) suffix', () {
        expect(
          MetadataCleaner.cleanTitle('Song Name (Audio)'),
          'Song Name',
        );
      });

      test('removes (HD) suffix', () {
        expect(
          MetadataCleaner.cleanTitle('Song Name (HD)'),
          'Song Name',
        );
      });

      test('is case insensitive for removals', () {
        expect(
          MetadataCleaner.cleanTitle('Song (OFFICIAL VIDEO)'),
          'Song',
        );
      });

      test('collapses multiple spaces into one', () {
        expect(
          MetadataCleaner.cleanTitle('Song   Name'),
          'Song Name',
        );
      });

      test('trims leading and trailing whitespace', () {
        expect(
          MetadataCleaner.cleanTitle('  Song Name  '),
          'Song Name',
        );
      });

      test('handles empty string without crash', () {
        expect(MetadataCleaner.cleanTitle(''), '');
      });

      test('handles multiple issues combined', () {
        expect(
          MetadataCleaner.cleanTitle(
            'Tum+Hi+Ho (Official Video) &amp; More (HD)'
          ),
          'Tum Hi Ho & More',
        );
      });
    });

    group('extractFromFilename', () {
      test('extracts artist and title from dash format', () {
        final result = MetadataCleaner.extractFromFilename('Arijit Singh - Tum Hi Ho');
        expect(result['artist'], 'Arijit Singh');
        expect(result['title'], 'Tum Hi Ho');
      });

      test('handles no dash — returns Unknown Artist', () {
        final result = MetadataCleaner.extractFromFilename('Tum Hi Ho');
        expect(result['artist'], 'Unknown Artist');
        expect(result['title'], 'Tum Hi Ho');
      });

      test('handles multiple dashes — uses first as separator', () {
        final result = MetadataCleaner.extractFromFilename('AR Rahman - Jai Ho - Movie');
        expect(result['artist'], 'AR Rahman');
        expect(result['title'], 'Jai Ho - Movie');
      });

      test('handles empty string without crash', () {
        final result = MetadataCleaner.extractFromFilename('');
        expect(result['artist'], 'Unknown Artist');
        expect(result['title'], '');
      });
    });

    group('cleanArtist', () {
      test('returns Unknown Artist for null', () {
        expect(MetadataCleaner.cleanArtist(null), 'Unknown Artist');
      });

      test('returns Unknown Artist for empty string', () {
        expect(MetadataCleaner.cleanArtist(''), 'Unknown Artist');
      });

      test('returns Unknown Artist for "Unknown Artist" input', () {
        expect(
          MetadataCleaner.cleanArtist('Unknown Artist'),
          'Unknown Artist',
        );
      });

      test('cleans valid artist name', () {
        expect(
          MetadataCleaner.cleanArtist('Arijit+Singh'),
          'Arijit Singh',
        );
      });
    });
  });
}
