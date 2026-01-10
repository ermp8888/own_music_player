import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/database/app_database.dart';
import 'core/services/audio_handler.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/player/presentation/providers/player_provider.dart';

/// Global audio handler instance
MyAudioHandler? globalAudioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = AppDatabase();

  // Try to initialize audio handler
  MyAudioHandler? audioHandler;
  try {
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(database),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.learning.mymusic.audio',
        androidNotificationChannelName: 'MyMusicApp',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    globalAudioHandler = audioHandler;
  } catch (e) {
    debugPrint('Audio service init error: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        if (audioHandler != null)
          audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const MyMusicApp(),
    ),
  );
}

class MyMusicApp extends StatelessWidget {
  const MyMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMusicApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
