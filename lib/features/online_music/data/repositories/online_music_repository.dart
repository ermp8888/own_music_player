import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';

final onlineMusicRepositoryProvider = Provider<OnlineMusicRepository>((ref) {
  return OnlineMusicRepository();
});

class OnlineMusicRepository {
  static const String baseUrl = 'https://saavn.vercel.app';

  int generateOnlineSongId(String saavnId) {
    final hash = saavnId.hashCode.abs();
    return hash == 0 ? -1 : -hash;
  }

  Future<List<Song>> searchSongs(String query, {int limit = 25}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/search/songs').replace(
        queryParameters: {
          'query': query,
          'limit': limit.toString(),
        },
      );
      
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final results = data['data']['results'] as List<dynamic>? ?? [];
          return results.map((songJson) => _parseSong(songJson)).whereType<Song>().toList();
        }
      }
      return [];
    } catch (e) {
      // Avoid print in production, but okay for debug log
      return [];
    }
  }

  Song? _parseSong(Map<String, dynamic> json) {
    try {
      final saavnId = json['id'] as String? ?? '';
      if (saavnId.isEmpty) return null;

      final title = json['name'] as String? ?? 'Unknown Title';
      
      String albumName = 'Unknown Album';
      final albumMap = json['album'] as Map<String, dynamic>?;
      if (albumMap != null) {
        albumName = albumMap['name'] as String? ?? 'Unknown Album';
      }

      String artistName = 'Unknown Artist';
      final artistsMap = json['artists'] as Map<String, dynamic>?;
      if (artistsMap != null) {
        final primaryArtists = artistsMap['primary'] as List<dynamic>?;
        if (primaryArtists != null && primaryArtists.isNotEmpty) {
          artistName = primaryArtists
              .map((a) => a['name'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .join(', ');
        }
      }
      if (artistName.isEmpty) artistName = 'Unknown Artist';

      final durationSeconds = json['duration'] as int? ?? 0;
      final durationMs = durationSeconds * 1000;

      String? imageUrl;
      final imageList = json['image'] as List<dynamic>?;
      if (imageList != null && imageList.isNotEmpty) {
        imageUrl = imageList.last['url'] as String?;
      }

      String? streamUrl;
      final downloadList = json['downloadUrl'] as List<dynamic>?;
      if (downloadList != null && downloadList.isNotEmpty) {
        final url320 = downloadList.firstWhere(
          (d) => d['quality'] == '320kbps',
          orElse: () => null,
        );
        final url160 = downloadList.firstWhere(
          (d) => d['quality'] == '160kbps',
          orElse: () => null,
        );
        streamUrl = (url320 ?? url160 ?? downloadList.last)['url'] as String?;
      }

      if (streamUrl == null || streamUrl.isEmpty) return null;

      return Song(
        id: generateOnlineSongId(saavnId),
        filePath: streamUrl,
        title: title,
        artist: artistName,
        album: albumName,
        duration: durationMs,
        fileSize: 0,
        albumArtPath: imageUrl,
        playCount: 0,
        dateAdded: DateTime.now(),
        isFavorite: false,
        bitrate: 0,
        isReported: false,
      );
    } catch (e) {
      return null;
    }
  }
}
