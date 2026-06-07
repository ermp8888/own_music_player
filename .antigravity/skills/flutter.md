# Flutter Skill — DownTune Guidelines

## State Management
- **Solution:** Riverpod (flutter_riverpod ^2.6.1)
- **Pattern:** `StateNotifier` + `StateNotifierProvider` for complex stateful logic
- **Simple state:** `StateProvider<T>` for primitive toggles and simple values
- **Async data:** `FutureProvider` for one-shot async loads, `StreamProvider` for reactive streams
- **Singletons:** `Provider<T>` for services (database, audio handler, file scanner, repositories)
- **Provider overrides:** Database and AudioHandler are initialized in `main()` and injected via `ProviderScope.overrides`
- **Key providers:**
  - `databaseProvider` — `Provider<AppDatabase>` (overridden in main)
  - `audioHandlerProvider` — `Provider<MyAudioHandler>` (overridden in main)
  - `playerStateProvider` — `StateNotifierProvider<PlayerStateNotifier, PlayerState>`
  - `libraryProvider` — `StateNotifierProvider<LibraryStateNotifier, LibraryState>`
  - `playlistsProvider` — `StateNotifierProvider<PlaylistsStateNotifier, PlaylistsState>`
  - `currentSongProvider` — `StreamProvider<Song?>`
  - `isPlayingProvider` — `StreamProvider<bool>`
  - `positionDataProvider` — `StreamProvider<PositionData>`

## Navigation Pattern
- **Type:** Imperative navigation via `Navigator.push()` with `MaterialPageRoute`
- **No named routes** — no route table, no GoRouter, no auto_route
- **Pattern:** Direct widget instantiation in MaterialPageRoute builder
- **Example:**
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const LibraryScreen()),
  );
  ```
- **Bottom Navigation:** Custom `BottomNavBar` widget with `IndexedStack`-like switching in `HomeScreen`
  - Tab 0: Home (inline `_HomeContent` widget)
  - Tab 1: Explore (OnlineMusicScreen)
  - Tab 2: Library (navigates via `Navigator.push` to `LibraryScreen`)
  - Tab 3: Settings (inline `SettingsScreen`)

## Theming
- **Single source of truth:** `lib/core/theme/app_theme.dart` → `AppTheme` class definitions
- **Color constants:** Migrated to `AppTheme`
- **Always use** `AppTheme` tokenized colors (e.g. `AppTheme.primaryAccent`, `AppTheme.backgroundCard`, `AppTheme.textSecondary`) — **never** hardcode hex values
- **Dark theme only**
- **Font:** `Plus Jakarta Sans` via `google_fonts`
- **Material 3:** `useMaterial3: true` is enabled
- **Color Palette:**
  - Background Primary: `#0A0A0F`
  - Background Surface: `#141420`
  - Background Card: `#1C1C2E`
  - Primary Accent: `#6C63FF`
  - Primary Accent Light: `#8B85FF`
  - Secondary Accent: `#00D4AA`
  - Text Primary: `#FFFFFF`
  - Text Secondary: `#9B9BAA`
  - Divider: `#2A2A3A`
  - Success: `#4CAF50`
  - Error: `#FF6B6B`
  - Warning: `#FFB300`

## Audio Architecture
- **Playback engine:** `just_audio` (`AudioPlayer` class)
- **Background service:** `audio_service` (`BaseAudioHandler` subclass → `MyAudioHandler`)
- **Session handling:** `audio_session` for OS audio focus
- **Stream combining:** `rxdart` (`Rx.combineLatest3`) for position data
- **Initialization flow:**
  1. `main()` calls `AudioService.init()` with `MyAudioHandler` builder
  2. Returns `MyAudioHandler` instance
  3. Stored as global (`globalAudioHandler`) and injected via `ProviderScope.overrides`
- **Handler owns:** `AudioPlayer`, `ConcatenatingAudioSource`, songs list, current index
- **Supports:** Local files (`AudioSource.file`) and remote URLs (`AudioSource.uri`)
- **Always dispose** AudioPlayer — currently handled in `MyAudioHandler.dispose()`
- **Media notification:** Configured with Android notification channel

## Database Architecture
- **ORM:** Drift (SQLite)
- **Tables:** Songs, Playlists, PlaylistSongs (many-to-many join)
- **Code gen:** `app_database.g.dart` generated via `build_runner`
- **Key operations:** CRUD for songs/playlists, play count tracking, favorites, smart playlists
- **Schema version:** 1 (no migrations yet)
- **To regenerate:** `dart run build_runner build --delete-conflicting-outputs`

## Performance Rules
- Use `ListView.builder` for all song lists (never `ListView` with children)
- Always use `cached_network_image` for remote images
- Avoid `setState` in large screens — use proper Riverpod providers
- All heavy operations must run async (file scanning, downloads, database queries)
- Use `shimmer` for loading placeholders instead of basic spinners
- Throttle progress updates during downloads (every 100KB) to avoid excessive rebuilds
- Use `flutter_animate` for declarative staggered animations on list items

## File Naming Convention
- **Screens:** `home_screen.dart`, `player_screen.dart`, `library_screen.dart`
- **Widgets:** `song_tile.dart`, `waveform_visualization.dart`, `mini_player.dart`
- **Providers:** `player_provider.dart`, `library_provider.dart`, `playlist_provider.dart`
- **Services:** `audio_handler.dart`, `file_scanner_service.dart`, `share_service.dart`
- **Models:** Drift generates models from table definitions (Song, Playlist, PlaylistSong)
- **Tables:** `songs_table.dart`, `playlists_table.dart`, `playlist_songs_table.dart`
- **Constants:** `app_constants.dart`, `app_theme.dart` (theme configuration)
- **Repositories:** `online_music_repository.dart`

## Responsive Design
- Design for 360-420dp width (Indian market phones)
- Test on small screen (360dp) before finalizing
- Avoid fixed pixel widths — use `MediaQuery`, `Flexible`, or `Expanded`
- Album art cards use `AspectRatio(1)` for square sizing
- Bottom nav bar uses `SafeArea` for notch/gesture bar handling
- Song tiles use `Expanded` for flexible text + fixed trailing icons
