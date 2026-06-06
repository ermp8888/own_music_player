# DownTune — Feature Implementation Plan

> [!IMPORTANT]
> This plan covers Parts 1-7. Each part is implemented in order with tests immediately after.

## Key Architecture Decisions

### yt-dlp on Mobile
The app is a **pure Flutter mobile app** with no backend server. `yt-dlp` is a Python CLI tool that cannot run natively on Android. Solution:
- **YouTube / YouTube Shorts**: Continue using `youtube_explode_dart` (already handles both — Shorts are just regular videos with different URL format)
- **Instagram Reels**: Use HTTP-based extraction (scrape the page's meta tags for video URL)
- Create a unified `DownloadService` that dispatches to the correct extractor based on URL platform

### Database Migration (v1 → v2)
New columns needed across all parts:
| Column | Type | Default | Part |
|--------|------|---------|------|
| `sourcePlatform` | Text (nullable) | null | 1 |
| `bitrate` | Integer | 0 | 2, 4 |
| `mood` | Text (nullable) | null | 5 |
| `isReported` | Boolean | false | 6 |

All added in a single schema version bump (1 → 2) with migration.

### New Dependencies
| Package | Purpose | Part |
|---------|---------|------|
| `mockito` + `build_runner` | Test mocking | 7 |
| `google_generative_ai` | Gemini API | 2, 5 |
| `flutter_dotenv` | .env file for API keys | 2, 5 |
| `speech_to_text` | Voice search | 6 |

### Files Created/Modified

#### New Files (27 total)
```
lib/core/services/url_detector.dart              # Part 1
lib/core/services/instagram_extractor.dart        # Part 1  
lib/core/services/download_service.dart           # Part 1
lib/core/services/filter_pipeline.dart            # Part 2
lib/core/services/quality_filter.dart             # Part 2
lib/core/services/duplicate_detector.dart         # Part 2
lib/core/services/blacklist_filter.dart           # Part 2
lib/core/services/gemini_service.dart             # Part 2, 5
lib/core/services/mood_tagger.dart                # Part 5
lib/core/services/sleep_timer_service.dart        # Part 6
lib/core/constants/blacklist_keywords.dart        # Part 2
lib/core/constants/filter_defaults.dart           # Part 3
lib/core/providers/filter_settings_provider.dart  # Part 3
lib/features/settings/presentation/screens/filter_settings_screen.dart  # Part 3
lib/features/player/presentation/widgets/equalizer_widget.dart          # Part 4

test/helpers/mock_gemini.dart                     # Part 7
test/helpers/mock_songs.dart                      # Part 7
test/helpers/mock_shared_preferences.dart         # Part 7
test/unit/url_detector_test.dart                  # Part 1
test/unit/download_service_test.dart              # Part 1
test/unit/filter_pipeline_test.dart               # Part 2
test/unit/duplicate_detector_test.dart            # Part 2
test/unit/blacklist_filter_test.dart              # Part 2
test/unit/gemini_filter_test.dart                 # Part 2
test/unit/filter_pipeline_integration_test.dart   # Part 2
test/unit/filter_settings_test.dart               # Part 3
test/widget/filter_settings_screen_test.dart      # Part 3
test/unit/audio_quality_badge_test.dart           # Part 4
test/unit/equalizer_test.dart                     # Part 4
test/unit/smart_search_test.dart                  # Part 5
test/unit/mood_tagger_test.dart                   # Part 5
test/unit/playlist_generator_test.dart            # Part 5
test/unit/sleep_timer_test.dart                   # Part 6
test/unit/report_song_test.dart                   # Part 6
```

#### Modified Files
```
pubspec.yaml                                      # New dependencies
lib/core/database/tables/songs_table.dart          # New columns
lib/core/database/app_database.dart                # Migration v2 + new queries
lib/core/constants/app_constants.dart              # New constants
```

## Implementation Order

| Step | Part | Description | Status |
|------|------|-------------|--------|
| 1 | 7 | Test infrastructure + mock helpers | [x] |
| 2 | — | Database migration (all new columns) | [x] |
| 3 | 1 | URL detector + download service + tests | [x] |
| 4 | 2 | Filter pipeline (quality/dupe/blacklist/AI) + tests | [x] |
| 5 | 3 | Filter settings screen + provider + tests | [x] |
| 6 | 4 | Audio quality badge + equalizer + tests | [x] |
| 7 | 5 | Gemini AI features (search/mood/playlist) + tests | [x] |
| 8 | 6 | UX improvements (timer/report/voice/share) + tests | [x] |
| 9 | — | Run flutter test --coverage + flutter analyze | [x] |

## Skipped Features (Already Exist)
- Share song (ShareService already implements shareSong, shareSongs, shareSongInfo, shareApp)
- Basic waveform visualization (WaveformVisualization widget exists — will enhance, not replace)
