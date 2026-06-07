# DownTune — Project Planner

## ✅ Already Implemented (detected from codebase scan)

### Core Infrastructure
- [x] Flutter project scaffolding with Material 3 dark theme
- [x] Riverpod state management (ProviderScope, StateNotifier pattern)
- [x] Drift (SQLite) database with Songs, Playlists, and PlaylistSongs tables
- [x] Code generation setup (build_runner, drift_dev, riverpod_generator)

### Audio Playback
- [x] Background audio playback via `audio_service` + `just_audio`
- [x] MyAudioHandler with play, pause, stop, seek, skip next/previous
- [x] Queue management with playlist loading
- [x] Shuffle mode toggle
- [x] Repeat mode cycling (off → all → one)
- [x] Media notification controls (lock screen / notification shade)
- [x] Position/duration/buffered stream tracking (via rxdart)
- [x] Support for both local files and remote stream URLs

### Local Music Library
- [x] Full device storage scanning for audio files (recursive)
- [x] Support for mp3, m4a, wav, flac, aac, ogg, wma, opus, webm
- [x] Quick rescan for new files only
- [x] Cleanup missing/deleted songs
- [x] Sort by title, artist, album, date added, duration
- [x] Recently played songs tracking (by lastPlayed timestamp)
- [x] Most played songs tracking (by playCount)
- [x] Favorites / Liked songs system
- [x] Song rename (title + artist)
- [x] Play count auto-increment on song change
- [x] Runtime permission handling (audio, storage, manage external storage)

### Playlist Management
- [x] Create, update, delete custom playlists
- [x] Add/remove songs from playlists
- [x] Reorder songs in playlist (drag & drop)
- [x] Smart playlists (Recently Played, Most Played — auto-created)
- [x] Playlist detail screen with play all
- [x] Playlist song count tracking

### Online Music (Explore Tab)
- [x] JioSaavn API integration for song search/streaming
- [x] Quick tags for genre-based browsing (Latest Hits, Romantic, Party, Lo-Fi, Classic, Devotional)
- [x] Online song streaming (tap to play directly)
- [x] Online song download with progress tracking
- [x] Custom download location selection (default folder + folder picker)
- [x] Downloaded song auto-registration in database
- [x] Add online song to existing/new playlist
- [x] Album art display via CachedNetworkImage
- [x] Shimmer loading skeleton

### YouTube Import
- [x] YouTube URL parsing and video info fetching
- [x] Audio-only download mode (best quality audio stream)
- [x] Video download mode (muxed stream)
- [x] Download progress bar with byte-level tracking
- [x] Custom save location with folder picker
- [x] Educational use disclaimer dialog
- [x] Share target (receive YouTube URLs from other apps)
- [x] Auto-detect shared YouTube URL and navigate to import screen
- [x] Download format toggle (audio/video)
- [x] Recent downloads section

### Downloads Management
- [x] Downloads screen listing all downloaded songs
- [x] Play all downloads
- [x] Song options (rename, favorite, delete, share)
- [x] Refresh downloaded songs list

### Player UI
- [x] Full-screen Now Playing screen with album art
- [x] Mini player (floating, dismissible) across all screens
- [x] Waveform visualization animation
- [x] Seek slider with time labels
- [x] Favorite toggle from player screen
- [x] Playback controls (shuffle, prev, play/pause, next, repeat)
- [x] Queue button placeholder
- [x] Lyrics button placeholder
- [x] Share song / share now playing info
- [x] Album art from network (online) or file (local)

### Navigation & UI Shell
- [x] Bottom navigation bar (Home, Explore, Library, Settings)
- [x] Gradient background wrapper
- [x] Glassmorphism container widget
- [x] Fade/slide animations on list items
- [x] Scale-tap animation widget
- [x] Section header with "See all" action

### Settings
- [x] Download location picker (preset + custom folder browse)
- [x] Audio quality display (static: 320kbps)
- [x] Share app (APK sharing)
- [x] About dialog with feature list
- [x] Version display

### Sharing
- [x] Share song file to other apps
- [x] Share song info (text-only)
- [x] Share multiple songs
- [x] Share app link

---

## 🔄 In Progress
- None currently

---

## 📋 Pending Features

### Phase 5 — Additional Features & Refinement
- [ ] Queue display implementation
- [ ] Lyrics sync (karaoke style)
- [ ] Offline AI DJ crossfade
- [ ] User accounts / cloud sync
- [ ] Android widget for player
- [ ] Car mode UI

---

## 🐛 Known Bugs & Limitations
- [ ] Song titles showing HTML entities (`&quot;` `&amp;`)
- [ ] Song titles showing URL-encoded format (`word+word+word`)
- [ ] Artist showing "Unknown Artist" for most local songs (file scanner extracts title from filename only — no metadata parsing)
- [ ] File lengths: some screens (e.g. `home_screen.dart`, `youtube_import_screen.dart`, `online_music_screen.dart`) exceed the 300-line max rule due to embedded widgets that can be further componentized.
- [ ] Audio quality setting is static/non-functional.
