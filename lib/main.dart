import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'core/database/app_database.dart';
import 'core/services/audio_handler.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/player/presentation/providers/player_provider.dart';

/// Global audio handler instance
MyAudioHandler? globalAudioHandler;

/// Global shared URL provider for receiving YouTube links from share menu
final sharedUrlProvider = StateProvider<String?>((ref) => null);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = AppDatabase();

  // Initialize audio handler (required before app starts for player to work)
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

class MyMusicApp extends ConsumerStatefulWidget {
  const MyMusicApp({super.key});

  @override
  ConsumerState<MyMusicApp> createState() => _MyMusicAppState();
}

class _MyMusicAppState extends ConsumerState<MyMusicApp> {
  late StreamSubscription _intentSub;

  @override
  void initState() {
    super.initState();
    _initShareReceiver();
  }

  void _initShareReceiver() {
    // Listen for shared media when app is already open
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleSharedMedia(value.first);
        }
      },
      onError: (err) {
        debugPrint('Share intent stream error: $err');
      },
    );

    // Get shared media if app was launched from share
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value.first);
        // Clear the intent so it doesn't trigger again
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  void _handleSharedMedia(SharedMediaFile media) {
    // Check if it's a YouTube URL
    final path = media.path;
    if (path.contains('youtube.com') || path.contains('youtu.be')) {
      ref.read(sharedUrlProvider.notifier).state = path;
      debugPrint('[Share] Received YouTube URL: $path');
    }
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DownTune',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
