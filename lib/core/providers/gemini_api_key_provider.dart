import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing the Gemini API key saved in SharedPreferences.
final geminiApiKeyProvider =
    StateNotifierProvider<GeminiApiKeyNotifier, String>((ref) {
  return GeminiApiKeyNotifier();
});

/// Notifier for storing and retrieving the Gemini API Key.
/// Priority: SharedPreferences (user-set) > .env file > empty.
class GeminiApiKeyNotifier extends StateNotifier<String> {
  late final Future<void> initialization;

  GeminiApiKeyNotifier() : super('') {
    initialization = _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');

    if (savedKey != null && savedKey.isNotEmpty) {
      if (mounted) state = savedKey;
    } else {
      // Fall back to .env file
      String envKey = '';
      try {
        envKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      } catch (_) {
        // dotenv is not initialized, ignore
      }
      if (envKey.isNotEmpty && mounted) {
        state = envKey;
      }
    }
  }

  /// Update the Gemini API Key and persist it.
  Future<void> setApiKey(String key) async {
    state = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
  }
}
