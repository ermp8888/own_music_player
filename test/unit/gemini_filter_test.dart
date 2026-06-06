import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/database/app_database.dart';
import 'package:my_music_app/core/services/filter_pipeline.dart';
import 'package:my_music_app/core/services/gemini_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../helpers/mock_gemini.dart';

class TestGeminiService extends GeminiService {
  String? mockResponse;
  bool shouldThrow = false;
  bool shouldTimeout = false;

  TestGeminiService() : super(model: GenerativeModel(model: 'gemini-1.5-flash', apiKey: 'dummy'));

  @override
  Future<String?> generateContent(String prompt) async {
    if (shouldTimeout) {
      await Future.delayed(const Duration(seconds: 5));
    }
    if (shouldThrow) {
      throw Exception('API error');
    }
    return mockResponse;
  }
}

Song createSong({
  required String title,
  required String artist,
}) {
  return Song(
    id: 1,
    filePath: '/music/test.mp3',
    title: title,
    artist: artist,
    album: 'Test Album',
    duration: 180000,
    fileSize: 5000000,
    playCount: 0,
    dateAdded: DateTime.now(),
    isFavorite: false,
    bitrate: 256,
    isReported: false,
  );
}

void main() {
  group('FilterPipeline.passGeminiFilter', () {
    late FakeGeminiService fakeGemini;
    late FilterPipeline pipeline;

    setUp(() {
      fakeGemini = FakeGeminiService();
      pipeline = FilterPipeline(geminiService: fakeGemini);
    });

    test('Gemini returns "NO" → PASS', () async {
      fakeGemini.setResponse('NO');
      final song = createSong(title: 'Shape of You', artist: 'Ed Sheeran');

      final result = await pipeline.passGeminiFilter(song);
      expect(result, isTrue);

      // Verify the prompt content
      expect(fakeGemini.lastPrompt, contains('Shape of You'));
      expect(fakeGemini.lastPrompt, contains('Ed Sheeran'));
    });

    test('Gemini returns "YES" → BLOCK', () async {
      fakeGemini.setResponse('YES');
      final song = createSong(title: 'Devotional Song', artist: 'Pundit');

      final result = await pipeline.passGeminiFilter(song);
      expect(result, isFalse);
    });

    test('Gemini times out → BLOCK (failsafe)', () async {
      fakeGemini.setTimeout(const Duration(milliseconds: 100));
      final song = createSong(title: 'Timeout Song', artist: 'Ed Sheeran');

      final result = await pipeline.passGeminiFilter(song);
      expect(result, isFalse); // Blocked for safety
    });

    test('Gemini throws exception → BLOCK (failsafe)', () async {
      fakeGemini.setError(Exception('API quota exceeded'));
      final song = createSong(title: 'Error Song', artist: 'Ed Sheeran');

      final result = await pipeline.passGeminiFilter(song);
      expect(result, isFalse); // Blocked for safety
    });

    test('Gemini returns unexpected text → BLOCK (failsafe)', () async {
      fakeGemini.setResponse('MAYBE');
      final song = createSong(title: 'Maybe Song', artist: 'Ed Sheeran');

      final result = await pipeline.passGeminiFilter(song);
      expect(result, isFalse); // Blocked for safety
    });
  });

  group('GeminiService.classifyMood', () {
    late TestGeminiService testGemini;

    setUp(() {
      testGemini = TestGeminiService();
    });

    test('Gemini returns happy → happy', () async {
      testGemini.mockResponse = 'happy';
      final mood = await testGemini.classifyMood('Happy Song', 'Artist');
      expect(mood, equals('happy'));
    });

    test('Gemini returns sad → sad', () async {
      testGemini.mockResponse = 'sad';
      final mood = await testGemini.classifyMood('Sad Song', 'Artist');
      expect(mood, equals('sad'));
    });

    test('Gemini returns chill → chill', () async {
      testGemini.mockResponse = 'chill';
      final mood = await testGemini.classifyMood('Chill Song', 'Artist');
      expect(mood, equals('chill'));
    });

    test('Gemini returns energetic → energetic', () async {
      testGemini.mockResponse = 'energetic';
      final mood = await testGemini.classifyMood('Energetic Song', 'Artist');
      expect(mood, equals('energetic'));
    });

    test('Gemini returns romantic → romantic', () async {
      testGemini.mockResponse = 'romantic';
      final mood = await testGemini.classifyMood('Romantic Song', 'Artist');
      expect(mood, equals('romantic'));
    });

    test('Gemini returns invalid mood → unknown', () async {
      testGemini.mockResponse = 'angry';
      final mood = await testGemini.classifyMood('Angry Song', 'Artist');
      expect(mood, equals('unknown'));
    });

    test('Gemini throws error → unknown', () async {
      testGemini.shouldThrow = true;
      final mood = await testGemini.classifyMood('Error Song', 'Artist');
      expect(mood, equals('unknown'));
    });

    test('Gemini times out → unknown', () async {
      testGemini.shouldTimeout = true;
      final mood = await testGemini.classifyMood('Timeout Song', 'Artist');
      expect(mood, equals('unknown'));
    });
  });
}
