/// Instagram Reel/Post audio extractor for DownTune.
///
/// Uses HTTP-based extraction to get video/audio URLs from Instagram
/// public content pages by parsing OG meta tags.
///
/// Note: Instagram aggressively blocks scraping. This extractor works
/// for public content but may break if Instagram changes their page
/// structure. For production use, consider a backend proxy.
/// 
/// TODO: (Future Work) As of current testing, Instagram's aggressive IP blocks
/// and proxy blocks (like saveig) make this entirely unreliable on client devices.
/// Needs a dedicated backend service or an authenticated approach to fix.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of an Instagram extraction attempt.
class InstagramExtractResult {
  final String? videoUrl;
  final String? title;
  final String? thumbnailUrl;
  final String? error;

  const InstagramExtractResult({
    this.videoUrl,
    this.title,
    this.thumbnailUrl,
    this.error,
  });

  bool get isSuccess => videoUrl != null && error == null;
}

/// Extracts video/audio information from Instagram Reels and Posts.
class InstagramExtractor {
  final http.Client _client;

  InstagramExtractor({http.Client? client})
      : _client = client ?? http.Client();

  /// Extract video URL from an Instagram Reel or Post URL.
  ///
  /// Uses the Instagram oEmbed API first, falls back to page scraping.
  Future<InstagramExtractResult> extract(String url) async {
    try {
      // Clean URL: remove query parameters like ?igsh=...
      final uri = Uri.parse(url);
      final cleanUrl = '${uri.scheme}://${uri.host}${uri.path}';

      // Approach 1: Try oEmbed API (public, no auth required)
      final oEmbedResult = await _tryOEmbed(cleanUrl);
      if (oEmbedResult.isSuccess) return oEmbedResult;

      // Approach 2: Try direct page scraping for video URL
      final scrapeResult = await _tryPageScrape(cleanUrl);
      if (scrapeResult.isSuccess) return scrapeResult;

      // Approach 3: Try proxy scraper (saveig.app)
      final proxyResult = await _tryProxyScrape(url);
      if (proxyResult.isSuccess) return proxyResult;

      return const InstagramExtractResult(
        error: 'Could not extract video URL from Instagram. '
            'The content may be private or Instagram blocked the request.',
      );
    } catch (e) {
      return InstagramExtractResult(
        error: 'Instagram extraction failed: $e',
      );
    }
  }

  /// Try Instagram oEmbed API to get basic info.
  Future<InstagramExtractResult> _tryOEmbed(String url) async {
    try {
      final oEmbedUrl = Uri.parse(
        'https://api.instagram.com/oembed/?url=$url',
      );
      final response = await _client
          .get(oEmbedUrl)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return InstagramExtractResult(
          title: data['title'] as String?,
          thumbnailUrl: data['thumbnail_url'] as String?,
          // oEmbed doesn't provide direct video URL, only metadata
        );
      }
    } catch (_) {
      // Fallback to scraping
    }
    return const InstagramExtractResult(error: 'oEmbed failed');
  }

  /// Try to scrape the Instagram page for og:video meta tag.
  Future<InstagramExtractResult> _tryPageScrape(String url) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'text/html',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = response.body;

        // Extract og:video content
        final videoUrl = _extractMetaContent(body, 'og:video');
        final title = _extractMetaContent(body, 'og:title');
        final thumbnail = _extractMetaContent(body, 'og:image');

        if (videoUrl != null) {
          return InstagramExtractResult(
            videoUrl: videoUrl,
            title: title,
            thumbnailUrl: thumbnail,
          );
        }
      }
    } catch (_) {
      // Scraping failed
    }
    return const InstagramExtractResult(error: 'Page scrape failed');
  }

  /// Try to extract using saveig.app proxy API
  Future<InstagramExtractResult> _tryProxyScrape(String url) async {
    try {
      final response = await _client.post(
        Uri.parse('https://saveig.app/api/ajaxSearch'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0',
          'Accept': '*/*',
        },
        body: {
          'q': url,
          't': 'media',
          'lang': 'en'
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final html = data['data'] as String?;
        if (html != null) {
          // Find the download link in the returned HTML
          // Look for: href="https://...mp4..."
          final regex = RegExp(r'href="([^"]+\.mp4[^"]*)"', caseSensitive: false);
          final match = regex.firstMatch(html);
          if (match != null) {
            return InstagramExtractResult(
              videoUrl: match.group(1)?.replaceAll('&amp;', '&'),
              title: 'Instagram Reel',
            );
          }
        }
      }
    } catch (_) {
      // Proxy scrape failed
    }
    return const InstagramExtractResult(error: 'Proxy scrape failed');
  }

  /// Extract content from <meta property="..." content="..."> tags.
  String? _extractMetaContent(String html, String property) {
    final regex = RegExp(
      '<meta\\s+(?:property|name)="$property"\\s+content="([^"]*)"',
      caseSensitive: false,
    );
    final match = regex.firstMatch(html);
    return match?.group(1);
  }

  void dispose() {
    _client.close();
  }
}
