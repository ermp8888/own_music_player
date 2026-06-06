import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/gemini_api_key_provider.dart';

/// Provider for GeminiService. Returns null if API key is not configured.
final geminiServiceProvider = Provider<GeminiService?>((ref) {
  final apiKey = ref.watch(geminiApiKeyProvider);
  if (apiKey.isEmpty) return null;
  final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  return GeminiService(model: model);
});

/// Service wrapper for Gemini API interactions.
class GeminiService {
  final GenerativeModel? _model;

  GeminiService({GenerativeModel? model}) : _model = model;

  /// Generate content from a list of prompt parts.
  Future<String?> generateContent(String prompt) async {
    if (_model == null) return null;
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text;
  }

  /// Classify the mood of a song based on title and artist.
  /// Returns one of: 'happy', 'sad', 'chill', 'energetic', 'romantic', or 'unknown' if not classifiable/error.
  Future<String> classifyMood(String title, String? artist) async {
    if (_model == null) return 'unknown';

    final prompt = 'Classify the mood of the following song based on its title and artist. '
        'Reply with exactly one of these lowercase words: happy, sad, chill, energetic, romantic. '
        'If it does not fit any of these, reply with unknown. Do not include any other text.\n\n'
        'Title: "$title"\n'
        'Artist: "${artist ?? ''}"';

    try {
      final responseText = await generateContent(prompt).timeout(const Duration(seconds: 4));
      final mood = responseText?.trim().toLowerCase() ?? 'unknown';
      final validMoods = {'happy', 'sad', 'chill', 'energetic', 'romantic'};
      if (validMoods.contains(mood)) {
        return mood;
      }
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }
}
