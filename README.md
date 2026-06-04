# MyMusicApp

A full-featured, cross-platform music player application built with Flutter for learning and experimentation.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

## Features

### 🌐 Online Music Streaming
- Search and stream Bollywood/regional songs online
- Dynamic search queries and quick vibe tags (e.g., Party, Romantic, Devotional, Lo-Fi)
- High-quality 320kbps audio streams powered by the JioSaavn API client repository

### ⬇️ Online Music Downloads
- Download streaming online tracks locally to your device
- **Interactive Location Selection**: Save to the default folder or choose any custom directory via the system file/folder picker on the fly
- Chunk-based progressive download tracking with clear UI SnackBar updates (Percentage progress, completed success, or error alerts)
- Automatic local DB indexing for immediate offline play inside local downloads

### 📋 Playlist Management
- Create, rename, delete, and manage custom playlists
- Drag-and-drop song reordering
- Smart playlists (Recently Played, Most Played)
- **Hybrid Playlists**: Add both local songs and online streaming tracks to the same custom playlist (stores online track refs in database dynamically)

### 🎵 Local Music Library
- Scan and index music files from device storage
- Support for MP3, M4A, WAV, FLAC, AAC, OGG, WMA, OPUS formats
- Sort by title, artist, album, date added, or duration
- Favorite songs functionality

### 🎧 Music Player
- Background audio playback
- Lock screen and notification controls
- Shuffle and repeat modes
- Seek bar with progress tracking
- Visual animated rings during playback

### ⬇️ YouTube Import
- Download audio from YouTube URLs
- Educational use disclaimer
- Progress tracking
- Custom save location

### 🎨 Premium Dark UI & Music Vibe
- Material 3 design system
- Glassmorphism effects
- Smooth animations and transitions
- Gradient backgrounds

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter (latest stable) |
| State Management | Riverpod |
| Audio | just_audio, audio_service |
| Database | Drift (SQLite) |
| YouTube | youtube_explode_dart |
| Permissions | permission_handler |

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App and theme constants
│   ├── database/       # Drift database tables and queries
│   ├── services/       # Audio handler, file scanner, permissions
│   ├── theme/          # Material 3 dark theme
│   └── utils/          # Formatters, platform utilities
├── features/
│   ├── home/           # Home screen
│   ├── local_music/    # Library and song widgets
│   ├── player/         # Player screen and mini player
│   ├── playlists/      # Playlist management
│   └── youtube_import/ # YouTube downloader
└── shared/
    ├── animations/     # Fade, slide, scale animations
    └── widgets/        # Glass container, gradient background
```

## Getting Started

### Prerequisites

- Flutter SDK (3.10+)
- Android SDK (API 21+)
- For desktop: Windows/Linux/macOS development tools

### Installation

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd MyMusicApp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate database code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   # Android
   flutter run
   
   # Linux
   flutter run -d linux
   
   # Windows
   flutter run -d windows
   ```

### Build APK

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk

flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Permissions (Android)

The app requires the following permissions:

| Permission | Purpose |
|------------|---------|
| `READ_MEDIA_AUDIO` | Access audio files (Android 13+) |
| `READ_EXTERNAL_STORAGE` | Access music files (older Android) |
| `FOREGROUND_SERVICE` | Background playback |
| `INTERNET` | YouTube downloads |
| `POST_NOTIFICATIONS` | Playback controls (Android 13+) |

## Usage

1. **First Launch**: Grant storage permissions when prompted
2. **Scan Library**: Tap refresh icon on home screen to scan for music
3. **Play Music**: Tap any song to start playback
4. **Create Playlists**: Navigate to Playlists > Create new playlist
5. **YouTube Import**: Accept disclaimer, paste URL, download

## Desktop Notes

For YouTube import on desktop, you may optionally install:
- **yt-dlp**: For enhanced video extraction
- **ffmpeg**: For audio format conversion

```bash
# Ubuntu/Debian
sudo apt install yt-dlp ffmpeg

# macOS
brew install yt-dlp ffmpeg

# Windows
winget install yt-dlp ffmpeg
```

## Disclaimer

⚠️ **YouTube Import Feature**: This feature is for educational and personal use only. Downloading copyrighted content without permission may violate YouTube's Terms of Service and copyright laws. Users are responsible for ensuring they have the right to download any content.

## License

This project is for learning purposes only and is not intended for commercial distribution.

## Acknowledgments

- [just_audio](https://pub.dev/packages/just_audio) - Audio playback
- [audio_service](https://pub.dev/packages/audio_service) - Background audio
- [Drift](https://pub.dev/packages/drift) - SQLite wrapper
- [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart) - YouTube extraction
