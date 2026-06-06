import 'dart:async';
import 'package:my_music_app/core/services/gemini_service.dart';

/// Fake Gemini Service for unit testing without calling real API.
class FakeGeminiService implements GeminiService {
  String? _response;
  Exception? _error;
  Duration? _timeout;
  int _callCount = 0;
  final List<String> _prompts = [];

  void setResponse(String response) {
    _response = response;
    _error = null;
    _timeout = null;
  }

  void setError(Exception error) {
    _error = error;
    _response = null;
    _timeout = null;
  }

  void setTimeout(Duration duration) {
    _timeout = duration;
    _response = null;
    _error = null;
  }

  void reset() {
    _response = null;
    _error = null;
    _timeout = null;
    _callCount = 0;
    _prompts.clear();
  }

  int get callCount => _callCount;
  List<String> get prompts => List.unmodifiable(_prompts);
  String? get lastPrompt => _prompts.isNotEmpty ? _prompts.last : null;

  @override
  Future<String?> generateContent(String prompt) async {
    _callCount++;
    _prompts.add(prompt);

    if (_timeout != null) {
      throw TimeoutException(
        'Gemini API timed out',
        _timeout,
      );
    }

    if (_error != null) {
      throw _error!;
    }

    return _response;
  }

  @override
  Future<String> classifyMood(String title, String? artist) async {
    _callCount++;
    _prompts.add('Mood classification: $title - $artist');

    if (_timeout != null) {
      throw TimeoutException(
        'Gemini API timed out',
        _timeout,
      );
    }

    if (_error != null) {
      throw _error!;
    }

    return _response ?? 'unknown';
  }
}
