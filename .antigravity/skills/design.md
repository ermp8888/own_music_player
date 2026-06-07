# Design Skill — DownTune UI Guidelines

## Color System

### Current Colors (defined in `app_theme.dart`)
```
Background Primary:   #0A0A0F
Background Surface:   #141420
Background Card:      #1C1C2E
Primary Accent:       #6C63FF
Primary Accent Light: #8B85FF
Secondary Accent:     #00D4AA
Text Primary:         #FFFFFF
Text Secondary:       #9B9BAA
Text Disabled:        #4A4A5A
Divider:              #2A2A3A
Error:                #FF6B6B
Success:              #4CAF50
Warning:              #FFB300
```

## Typography

### Font Family
- **Family:** Plus Jakarta Sans (via `google_fonts`)
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

### Radii
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

### Album Gradients (from `home_screen.dart`)
```dart
tealGradient     → [#6C63FF, #00D4AA] (Primary to Secondary accent)
orange           → [#F5A962, #E8945A] (Orange to Orange Light)
cardGradient     → [#1C1C2E, #141420] (Card to Surface)
primaryGradient  → [#6C63FF, #8B85FF] (Primary to Primary Light)
```

## Icon Style
```
Size standard:  24px
Color active:   AppTheme.primaryAccent (#6C63FF)
Color inactive: AppTheme.textSecondary (#9B9BAA)
Style:          Material Icons Rounded (e.g. Icons.play_arrow_rounded)
```

**Rule:** Always use `_rounded` variant of Material Icons (e.g., `Icons.music_note_rounded`, not `Icons.music_note`).

## Gradients in Use

| Name | Colors | Usage |
|------|--------|-------|
| `primaryGradient` | `#6C63FF → #8B85FF` | FAB, buttons, badges, app icon |
| `youtubeImportGradient` | `#FF3E3E → #9E0000` | YouTube Import promo card |
| `backgroundGradient` | `#0A0A0F → #141420` | Screen background wrapper |
| `cardGradient` | `#1C1C2E → #141420` | Card backgrounds |
| `tealGradient` | `#6C63FF → #00D4AA` | Album art placeholder, avatar |

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
    color: Colors.white.withValues(alpha: 0.03),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppTheme.divider,
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
  backgroundColor: AppTheme.backgroundPrimary,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) => Container(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [...]),
  ),
);
```

## Song Tile Pattern
- Leading: 48x48 album art (rounded 12px) with play overlay if currently playing
- Title: Bold 14sp, primary text color (highlighted with primaryAccent if playing)
- Subtitle: Regular 12sp, secondary text color — "Artist"
- Trailing: Duration text + more_vert icon button
- Container: Card color with custom border, highlighted border if currently playing

## Empty State Pattern
```
Center
  └── Column(mainAxisAlignment: center)
       ├── Icon (64px, textSecondary color)
       ├── SizedBox(16)
       ├── Title text (16sp, bold, textSecondary)
       ├── SizedBox(8)
       └── Subtitle text (14sp, textSecondary)
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
