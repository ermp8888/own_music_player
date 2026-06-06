# Design Skill — DownTune UI Guidelines

## Color System

### Current Colors (detected from `theme_constants.dart`)
```
Background:     #0D0F14
Surface:        #131620
Card:           #1A1D28
Card Light:     #242836
Primary:        #4D7CFE  (Blue accent)
Primary Light:  #6B93FF
Primary Dark:   #3A5FCC
Accent:         #5B6EF7  (Purple-blue)
Accent Light:   #7B8CFF
Teal Accent:    #2D8B7A
Coral Accent:   #F5A962
Text Primary:   #FFFFFF
Text Secondary: #9CA3AF
Text Muted:     #6B7280
Glass:          #1AFFFFFF (10% white)
Glass Border:   #20FFFFFF (12.5% white)
Success:        #10B981
Error:          #EF4444
Warning:        #F59E0B
```

### Target Colors (Phase 4 — Design Overhaul)
```
Background:     #0A0A0F
Surface:        #141420
Card:           #1C1C2E
Primary:        #6C63FF
Primary Light:  #8B85FF
Secondary:      #00D4AA
Text Primary:   #FFFFFF
Text Secondary: #9B9BAA
Text Disabled:  #4A4A5A
Divider:        #2A2A3A
Error:          #FF6B6B
```

## Typography

### Current Font
- **Family:** Poppins (via `google_fonts`)
- **Applied globally** through `AppTheme._textTheme`

### Target Font (Phase 4)
- **Family:** Plus Jakarta Sans (Google Fonts)
- **Scale:**
  ```
  Display:  28sp Bold
  Heading:  22sp SemiBold
  Title:    18sp SemiBold
  Body:     15sp Regular
  Caption:  13sp Regular
  Label:    12sp Medium
  ```

## Component Standards

### Current Radii (from `ThemeConstants`)
```
Small:   8px   (radiusSmall)
Medium:  16px  (radiusMedium)
Large:   24px  (radiusLarge)
XLarge:  32px  (radiusXLarge)
```

### Target Radii (Phase 4)
```
Card radius:      16px
Button radius:    12px
Input radius:     12px
Chip radius:      50px
Thumbnail radius: 12px
Bottom sheet:     24px top radius
```

## Song Thumbnail Avatar Colors
Cycle through these based on title first letter:
```
#6C63FF, #FF6B6B, #00D4AA, #FF9800, #3D5AFE, #E91E8C
```

### Current Album Gradients (from `home_screen.dart`)
```dart
tealGradient     → [#2D8B7A, #3DAA96]
coral            → [#F5A962, #E8945A]
cardGradient     → [#242836, #1A1D28]
primaryGradient  → [#4D7CFE, #5B6EF7]
```

## Icon Style
```
Size standard:  24px
Color active:   ThemeConstants.primaryColor (#4D7CFE currently, #6C63FF target)
Color inactive: ThemeConstants.textMuted (#6B7280 currently, #4A4A5A target)
Style:          Material Icons Rounded (e.g. Icons.play_arrow_rounded)
```

**Rule:** Always use `_rounded` variant of Material Icons (e.g., `Icons.music_note_rounded`, not `Icons.music_note`).

## Gradients in Use

| Name | Colors | Usage |
|------|--------|-------|
| `primaryGradient` | `#4D7CFE → #5B6EF7` | FAB, buttons, badges, app icon |
| `youtubeImportGradient` | `#4D5BD4 → #6B7BF7 → #8B9BFF` | YouTube Import promo card |
| `backgroundGradient` | `#131620 → #0D0F14` | Screen background wrapper |
| `cardGradient` | `#242836 → #1A1D28` | Card backgrounds |
| `playerGradient` | `#1A1D28 → #0D0F14` | Player screen background |
| `tealGradient` | `#2D8B7A → #3DAA96` | Album art placeholder, avatar |

## Shadows

### Card Shadow
```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.3),
  blurRadius: 20,
  offset: Offset(0, 10),
)
```

### Glow Shadow (Primary accent)
```dart
BoxShadow(
  color: primaryColor.withValues(alpha: 0.3),
  blurRadius: 20,
  spreadRadius: 2,
)
```

## Animation Standards

### Current Animations (from `flutter_animate` usage)
```
Page entry:       fadeIn() + slideY(begin: 0.2)
List item stagger: fadeIn(delay: 50ms * index) + slideX(begin: 0.2)
Album art:        scale(duration: 400ms, curve: easeOutBack)
Play button:      scale(delay: 200ms, duration: 300ms)
Nav item:         AnimatedContainer(200ms)
```

### Target Standards (Phase 4)
```
Page transitions:  300ms ease-in-out
Button press:      150ms scale to 0.95
Color transitions: 200ms
List item appear:  FadeTransition 250ms
```

## Glassmorphism Pattern
```dart
Container(
  decoration: BoxDecoration(
    color: ThemeConstants.glassColor,      // 10% white
    borderRadius: BorderRadius.circular(ThemeConstants.radiusMedium),
    border: Border.all(
      color: ThemeConstants.glassBorderColor,  // 12.5% white
    ),
  ),
)
```
Used via `GlassContainer` widget in `lib/shared/widgets/glass_container.dart`.

## Screen Layout Pattern
Every screen follows this structure:
```
Scaffold(backgroundColor: transparent)
  └── GradientBackground
       └── SafeArea
            └── Column
                 ├── Header (back button + title + actions)
                 ├── Expanded(content — usually ListView.builder or CustomScrollView)
                 └── MiniPlayer (floating at bottom)
```

## Bottom Sheet Pattern
```dart
showModalBottomSheet(
  backgroundColor: ThemeConstants.backgroundColor,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => Container(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [...]),
  ),
);
```

## Song Tile Pattern
- Leading: 48x48 album art (rounded 8px) with play overlay if currently playing
- Title: Bold 14sp, primary text color (highlighted with primaryColor if playing)
- Subtitle: Regular 12sp, secondary text color — "Artist • Album"
- Trailing: Duration text + more_vert icon button
- Container: Card color with glass border, highlighted border if currently playing

## Empty State Pattern
```
Center
  └── Column(mainAxisAlignment: center)
       ├── Icon (64px, textMuted color)
       ├── SizedBox(16)
       ├── Title text (16sp, bold, textSecondary)
       ├── SizedBox(8)
       └── Subtitle text (14sp, textMuted)
```

## Spacing Standards
```
Screen padding:     20px horizontal
Section gap:        24px vertical
Card padding:       20px all sides
Card margin:        8px bottom
List item spacing:  6-8px vertical
Header top:         16px
Between icon+text:  12px
```
