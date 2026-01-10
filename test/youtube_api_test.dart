// Test more YouTube download APIs
// Run with: dart run test/youtube_api_test.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

const videoId = 'aMWuGj0FCYg';
const youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';

Future<void> main() async {
  print('=== Testing YouTube Download APIs ===\n');
  print('Video URL: $youtubeUrl\n');

  // Test various services
  await testCobaltWuksh();
  await testSavetubeApi();
  await testY2mateApi();
  await testRapidApi();
  
  print('\n=== Done ===');
}

Future<void> testCobaltWuksh() async {
  print('--- Testing co.wuk.sh ---');
  try {
    final response = await http.post(
      Uri.parse('https://co.wuk.sh/api/json'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'url': youtubeUrl,
        'aFormat': 'mp3',
        'isAudioOnly': true,
      }),
    ).timeout(const Duration(seconds: 15));
    
    print('Status: ${response.statusCode}');
    print('Body: ${response.body.substring(0, 200.clamp(0, response.body.length))}');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testSavetubeApi() async {
  print('\n--- Testing savetube.su API ---');
  try {
    // First get the page to see if there's an API
    final response = await http.get(
      Uri.parse('https://api.savetube.su/info?url=$youtubeUrl'),
      headers: {
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));
    
    print('Status: ${response.statusCode}');
    print('Body: ${response.body.substring(0, 200.clamp(0, response.body.length))}');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testY2mateApi() async {
  print('\n--- Testing y2mate-type API ---');
  try {
    // Try a y2mate-style API
    final response = await http.post(
      Uri.parse('https://api-v2.y2mate.com/v1/convert'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'url': youtubeUrl,
        'format': 'mp3',
      }),
    ).timeout(const Duration(seconds: 15));
    
    print('Status: ${response.statusCode}');
    print('Body: ${response.body.substring(0, 200.clamp(0, response.body.length))}');
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testRapidApi() async {
  print('\n--- Testing RapidAPI YouTube MP3 ---');
  try {
    final response = await http.get(
      Uri.parse('https://youtube-mp36.p.rapidapi.com/dl?id=$videoId'),
      headers: {
        'X-RapidAPI-Key': 'demo', // Would need real key
        'X-RapidAPI-Host': 'youtube-mp36.p.rapidapi.com',
      },
    ).timeout(const Duration(seconds: 15));
    
    print('Status: ${response.statusCode}');
    print('Body: ${response.body.substring(0, 200.clamp(0, response.body.length))}');
  } catch (e) {
    print('Error: $e');
  }
}
