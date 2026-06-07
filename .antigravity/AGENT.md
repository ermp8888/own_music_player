# DownTune — Agent Instructions

## Project Overview
- **App Name:** DownTune
- **Package Name:** `com.learning.mymusic.my_music_app`
- **Platform:** Flutter (Android first, iOS later)
- **Language:** Dart
- **Dart SDK:** ^3.10.4
- **Min SDK:** Android (uses `flutter.minSdkVersion` — Flutter default, API 21+)
- **Target SDK:** Android 34 (API 34)
- **Compile SDK:** 36
- **Current Version:** 1.0.0+1

## Architecture
- **Pattern:** Feature-First Layered Architecture
- **State Management:** Riverpod (flutter_riverpod ^2.6.1)
  - Uses `StateNotifier` + `StateNotifierProvider` for complex state (PlayerStateNotifier, LibraryStateNotifier, PlaylistsStateNotifier)
  - Uses `StateProvider` for simple state (search queries, boolean flags)
  - Uses `StreamProvider` for reactive streams (audio position, current song, playing state)
  - Uses `FutureProvider` for async data loading (online songs, downloaded songs)
  - Uses `Provider` for singletons (database, audio handler, file scanner, repositories)
- **Navigation:** Imperative `Navigator.push()` with `MaterialPageRoute` (no named routes, no GoRouter)
- **Database:** Drift (SQLite ORM) with code generation
- **Audio Backend:** `just_audio` + `audio_service` for background playback

## Folder Structure
```
lib/
├── main.dart                                          # Entry point, AudioService init, ProviderScope
  ├── core/                                              # Shared infrastructure
  │   ├── constants/
  │   │   └── app_constants.dart                         # App name, version, supported formats, animation durations, storage keys
  │   ├── database/
  │   │   ├── app_database.dart                          # Drift database class + all queries
  │   │   ├── app_database.g.dart                        # Generated Drift code
  │   │   └── tables/
  │   │       ├── songs_table.dart                       # Songs table schema
  │   │       ├── playlists_table.dart                   # Playlists table schema
  │   │       └── playlist_songs_table.dart              # M2M join table
  │   ├── providers/
  │   │   └── download_location_provider.dart            # Download location management (SharedPreferences)
  │   ├── services/
  │   │   ├── audio_handler.dart                         # MyAudioHandler (background audio service)
  │   │   ├── file_scanner_service.dart                  # Local music file scanner
  │   │   ├── permission_service.dart                    # Runtime permissions
  │   │   └── share_service.dart                         # Share songs/app via share_plus
  │   ├── theme/
  │   │   └── app_theme.dart                             # Modern dark theme design tokens & ThemeData
  │   └── utils/
  │       ├── formatters.dart                            # Duration formatting, etc.
  │       └── platform_utils.dart                        # Platform detection helpers
├── features/                                          # Feature modules
│   ├── home/
│   │   └── presentation/screens/
│   │       └── home_screen.dart                       # Main shell: BottomNav, HomeContent, MiniPlayer
│   ├── local_music/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── library_provider.dart              # LibraryStateNotifier + FileScannerProvider
│   │       ├── screens/
│   │       │   ├── library_screen.dart                # All songs list with search + sort
│   │       │   └── recently_played_screen.dart        # Recently played songs
│   │       └── widgets/
│   │           └── song_tile.dart                     # Reusable song list tile
│   ├── online_music/
│   │   ├── data/repositories/
│   │   │   └── online_music_repository.dart           # JioSaavn API (saavn.vercel.app) for search/stream
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── online_music_provider.dart          # Search query, songs, download notifier
│   │       └── screens/
│   │           └── online_music_screen.dart            # Explore tab: search, quick tags, streaming, download
│   ├── player/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── player_provider.dart                # PlayerStateNotifier, stream providers, database/audio providers
│   │       ├── screens/
│   │       │   └── player_screen.dart                  # Full-screen Now Playing view
│   │       └── widgets/
│   │           ├── mini_player.dart                    # Floating mini player bar
│   │           └── waveform_visualization.dart         # Animated waveform bars
│   ├── playlists/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── playlist_provider.dart              # PlaylistsStateNotifier, playlist CRUD
│   │       └── screens/
│   │           ├── playlists_screen.dart               # All playlists view
│   │           ├── playlist_detail_screen.dart         # Single playlist songs
│   │           └── liked_songs_screen.dart             # Favorites list
│   ├── settings/
│   │   └── presentation/screens/
│   │       └── settings_screen.dart                    # App settings: download location, about, share
│   └── youtube_import/
│       └── presentation/screens/
│           ├── youtube_import_screen.dart              # YouTube URL → download (audio/video) via youtube_explode_dart
│           └── downloads_screen.dart                   # All downloaded songs view
└── shared/                                            # Reusable widgets & animations
    ├── animations/
    │   ├── fade_slide_animation.dart
    │   └── scale_tap_animation.dart
    └── widgets/
        ├── bottom_nav_bar.dart                         # Custom 4-tab nav: Home, Explore, Library, Settings
        ├── glass_container.dart                         # Glassmorphism container
        ├── gradient_background.dart                     # Background gradient wrapper
        └── section_header.dart                          # Section title + "See all" button
```

## Core Packages (DO NOT replace these)

### Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Riverpod code generation annotations |
| just_audio | ^0.9.43 | Audio playback engine |
| audio_service | ^0.18.17 | Background audio service |
| audio_session | ^0.1.25 | Audio session management |
| rxdart | ^0.28.0 | Reactive stream operators (combineLatest3) |
| drift | ^2.24.0 | SQLite ORM |
| sqlite3_flutter_libs | ^0.5.31 | SQLite native bindings |
| path_provider | ^2.1.5 | App document directories |
| path | ^1.9.1 | Path manipulation |
| permission_handler | ^11.4.0 | Runtime permissions |
| youtube_explode_dart | ^3.0.5 | YouTube video/audio extraction |
| flutter_animate | ^4.5.2 | Declarative animations |
| google_fonts | ^6.2.1 | Google Fonts (currently Poppins) |
| cached_network_image | ^3.4.1 | Network image caching |
| shimmer | ^3.0.0 | Loading shimmer effects |
| file_picker | ^9.2.1 | File/folder picker dialogs |
| receive_sharing_intent | ^1.8.1 | Share target (receive YouTube URLs) |
| reorderable_grid_view | ^2.2.8 | Drag & drop reordering |
| share_plus | ^10.1.4 | Share songs/files to other apps |
| shared_preferences | ^2.3.5 | Key-value persistent storage |
| http | ^1.6.0 | HTTP requests (used by online music download) |
| cupertino_icons | ^1.0.8 | iOS-style icons |

### Dev Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| flutter_lints | ^6.0.0 | Lint rules |
| riverpod_generator | ^2.6.4 | Riverpod code gen |
| build_runner | ^2.4.15 | Dart code generation |
| drift_dev | ^2.24.0 | Drift code generation |
| flutter_launcher_icons | ^0.14.3 | App icon generation |
| flutter_native_splash | ^2.4.4 | Splash screen generation |

## Coding Rules
- Always use `const` constructors where possible
- All colors must come from AppTheme design tokens — never hardcode hex values
- All app-wide strings/constants must be in `lib/core/constants/app_constants.dart`
- Never use `print()` — use `debugPrint()` only
- Always handle null safety properly
- Maximum file length: 300 lines — split if longer
- Widget files go in `lib/features/<feature>/presentation/screens/` or `lib/features/<feature>/presentation/widgets/`
- Business logic goes in `lib/features/<feature>/presentation/providers/` or `lib/core/services/`
- Shared/reusable widgets go in `lib/shared/widgets/`

## Package Preferences
- **Audio playback:** `just_audio` (never `audioplayers`)
- **Local storage:** `shared_preferences` for settings, `drift` (SQLite) for song/playlist data
- **HTTP requests:** Currently uses `http` package for JioSaavn API; prefer `dio` for new features
- **Icons:** Material Icons only (no custom icon packages)
- **Navigation:** Imperative `Navigator.push()` with `MaterialPageRoute`
- **State management:** Riverpod (`StateNotifier` + `StateNotifierProvider` pattern)
- **Font:** Plus Jakarta Sans via Google Fonts

## What NOT to Do
- Never remove existing features without explicit instruction
- Never change business logic when doing UI tasks
- Never add a new package without mentioning it first
- Never hardcode any URL, key, or path — use constants
- Never rewrite a working function — only extend it
- Never use `setState` in large screens — use Riverpod providers
- Never use `ListView(children: [...])` for dynamic lists — always use `ListView.builder`

## API Keys & Secrets
- All API keys must go in `.env` file (never hardcode)
- `.env` is gitignored — never commit it
- Access via `flutter_dotenv` package (to be added when needed)
- Currently, JioSaavn API (`saavn.vercel.app`) is used without auth keys

## Git Rules
- Commit after each Part/feature is complete
- Commit message format: `[FEAT]` or `[FIX]` or `[UI]` + description
- Example: `[UI] Redesign home screen with new color system`

## External Services
- **JioSaavn API:** `https://saavn.vercel.app` — used for online music search and streaming (Explore tab)
- **YouTube:** `youtube_explode_dart` — used for YouTube video/audio download (YouTube Import screen)
- **Share Target:** App receives YouTube URLs shared from other apps via `receive_sharing_intent`
