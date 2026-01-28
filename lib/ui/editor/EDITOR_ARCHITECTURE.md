# ReelSpark Editor Architecture

> **Last Updated:** January 23, 2026  
> **Version:** 2.0 (Refactored)

## 📁 Folder Structure Overview

```
lib/
├── editor/                      # Main editor module
│   ├── editor.dart              # Barrel file - exports all components
│   ├── editor_screen.dart       # Main screen (Scaffold + layout)
│   │
│   ├── state/                   # Lightweight state classes
│   │   ├── editor_state.dart    # Playback: currentPlayTime, isPlaying
│   │   ├── text_state.dart      # Text clips list + selection
│   │   ├── audio_state.dart     #     │   └── filter_state.dart    # Transitions (fade/slide/zoom)
│   │
│   ├── preview/                 # Preview area widgets
│   │   ├── preview_area.dart    # Main preview container (9:16)
│   │   ├── image_layer.dart     # Background image + transitions
│   │   └── text_layer.dart      # Text overlays with gestures
│   │
│   ├── timeline/                # Timeline components
│   │   ├── timeline_container.dart  # Main timeline + playhead
│   │   ├── video_timeline.dart      # Video/image clips track
│   │   ├── text_timeline.dart       # Text clips track
│   │   └── audio_timeline.dart      # Audio track with trim
│   │
│   ├── panels/                  # Bottom expandable panels
│   │   ├── text_panel.dart      # Text input + style/font
│   │   ├── audio_panel.dart     # Music info + volume
│   │   ├── effects_panel.dart   # Transitions selector
│   │   └── filter_panel.dart    # Visual filter presets
│   │
│   └── widgets/                 # Reusable UI components
│       ├── editor_top_bar.dart      # Back, resolution, export
│       ├── editor_bottom_bar.dart   # Tool buttons (Audio/Text/Effects)
│       ├── rotate_scale_handle.dart # Rotation handle for text
│       └── control_button.dart      # Generic control button
│
├── models/                      # Data models
│   ├── text_clip.dart           # Text overlay model
│   ├── audio_clip.dart          # Audio with trim support
│   └── filter_clip.dart         # Filter/effect model
│
├── utils/                       # Utility helpers
│   └── time_utils.dart          # Time formatting & calculations
│
└── services/
    └── New Project/
        └── video_service.dart   # FFmpeg export service
```

---

## 🏗️ Architecture Principles


### 1. **Separation of Concerns**
- **State** → Data and business logic
- **Preview** → Visual rendering
- **Timeline** → Time-based editing
- **Panels** → User input UI
- **Widgets** → Reusable components

### 2. **State Management (Lightweight)**
Currently using simple state classes passed via constructors.
- No Provider/Riverpod/Bloc yet
- State lives in `_EditorScreenState`
- Child widgets receive callbacks for mutations

### 3. **Timeline-Based Visibility**
Text clips use `isVisibleAt(time)` to determine visibility:
```dart
bool isVisibleAt(double time) {
  return time >= startTime && time <= endTime;
}
```

---

## 🔧 Component Details

### EditorScreen (Main)
**Location:** `editor/editor_screen.dart`

The main screen holds all state and orchestrates child widgets:
```dart
class _EditorScreenState extends State<EditorScreen> {
  // Playback
  double _currentPlayTime = 0.0;
  bool isPlaying = false;
  
  // Content
  List<File> images;
  List<double> durations;
  List<TextClip> _textClips = [];
  AudioClip? _audioClip;
  
  // UI State
  EditorTool? _activeTool;
  bool _showTextInput = false;
  bool _showEffectsPanel = false;
}
```

### PreviewArea
**Location:** `editor/preview/preview_area.dart`

Displays 9:16 preview with layers:
1. **ImageLayer** - Background with transitions
2. **TextLayer** - Text overlays with manipulation

### TimelineContainer
**Location:** `editor/timeline/timeline_container.dart`

Contains tracks stacked vertically:
1. **Time Ruler** - Second markers
2. **VideoTimeline** - Image clips
3. **TextTimeline** - Text clips (if any)
4. **AudioTimeline** - Audio track (if any)

Key constants:
```dart
static const double pixelsPerSecond = 60.0;
static const double clipHeight = 56.0;
static const double textTrackHeight = 36.0;
static const double audioTrackHeight = 40.0;
```

---

## 🚀 How to Add New Features

### Adding a New Tool (e.g., Stickers)

#### Step 1: Create the Model
```dart
// lib/models/sticker_clip.dart
class StickerClip {
  final String id;
  final String assetPath;
  double startTime;
  double endTime;
  Offset position;
  double scale;
  double rotation;
  
  bool isVisibleAt(double time) {
    return time >= startTime && time <= endTime;
  }
}
```

#### Step 2: Create State Class
```dart
// lib/editor/state/sticker_state.dart
class StickerState {
  List<StickerClip> stickers = [];
  StickerClip? selectedSticker;
  
  void addSticker(StickerClip sticker) { ... }
  void removeSticker(StickerClip sticker) { ... }
}
```

#### Step 3: Create Preview Layer
```dart
// lib/editor/preview/sticker_layer.dart
class StickerLayer extends StatelessWidget {
  final List<StickerClip> stickers;
      final double currentPlayTime;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final sticker in stickers)
          if (sticker.isVisibleAt(currentPlayTime))
            _buildStickerWidget(sticker),
      ],
    );
  }
}
```

#### Step 4: Create Timeline Track
```dart
// lib/editor/timeline/sticker_timeline.dart
class StickerTimeline extends StatefulWidget {
  final List<StickerClip> stickers;
  final Function(StickerClip, double, double) onTrim;
  // ...
}
```

#### Step 5: Create Panel
```dart
// lib/editor/panels/sticker_panel.dart
class StickerPanel extends StatelessWidget {
  final Function(String assetPath) onStickerSelected;
  // Grid of available stickers
}
```

#### Step 6: Add Tool to Bottom Bar
```dart
// lib/editor/widgets/editor_bottom_bar.dart
enum EditorTool {
  audio,
  text,
  sticker,  // NEW
  effects,
}
```

#### Step 7: Wire in EditorScreen
```dart
// In editor_screen.dart

// Add state
List<StickerClip> _stickers = [];
StickerClip? _selectedSticker;

// Add to preview
PreviewArea(
  // ...existing...
  children: [
    ImageLayer(...),
    TextLayer(...),
    StickerLayer(  // NEW
      stickers: _stickers,
      currentPlayTime: _currentPlayTime,
    ),
  ],
)

// Add to timeline
if (_stickers.isNotEmpty)
  StickerTimeline(
    stickers: _stickers,
    onTrim: _onStickerTrim,
  ),

// Add panel
if (_showStickerPanel) StickerPanel(...),
```

#### Step 8: Update Exports
```dart
// lib/editor/editor.dart
export 'preview/sticker_layer.dart';
export 'timeline/sticker_timeline.dart';
export 'panels/sticker_panel.dart';
```

---

### Adding a New Transition Effect

#### Step 1: Add to Enum
```dart
// lib/editor/state/filter_state.dart
enum TransitionType { 
  fade, 
  slide, 
  zoom,
  blur,      // NEW
  dissolve,  // NEW
}
```

#### Step 2: Implement in EditorScreen
```dart
Widget _buildTransition(Widget child) {
  switch (transitionType) {
    case TransitionType.fade:
      return FadeTransition(opacity: _fadeAnimation, child: child);
    case TransitionType.blur:  // NEW
      return AnimatedBuilder(
        animation: _blurAnimation,
        builder: (_, __) => ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: _blurAnimation.value,
            sigmaY: _blurAnimation.value,
          ),
          child: child,
        ),
      );
    // ...
  }
}
```

#### Step 3: Add to Effects Panel
```dart
// lib/editor/panels/effects_panel.dart
_buildTransitionOption(
  icon: Icons.blur_circular,
  label: 'Blur',
  type: TransitionType.blur,
),
```

---

### Adding Export with Text Overlay

```dart
// In video_service.dart
Future<String> exportWithText({
  required List<File> images,
  required List<double> durations,
  required List<TextClip> textClips,
  String? musicPath,
}) async {
  // Build FFmpeg filter complex for text overlay
  final textFilters = textClips.map((clip) {
    return "drawtext=text='${clip.text}'"
           ":fontsize=${clip.fontSize}"
           ":fontcolor=${_colorToHex(clip.color)}"
           ":x=${clip.position.dx}"
           ":y=${clip.position.dy}"
           ":enable='between(t,${clip.startTime},${clip.endTime})'";
  }).join(',');
  
  // Add to FFmpeg command
  // ...
}
```

---

## 📋 Checklist for New Features

- [ ] Create model in `lib/models/`
- [ ] Create state class in `lib/editor/state/`
- [ ] Create preview layer in `lib/editor/preview/`
- [ ] Create timeline track in `lib/editor/timeline/`
- [ ] Create panel in `lib/editor/panels/`
- [ ] Add tool enum to `editor_bottom_bar.dart`
- [ ] Wire state in `editor_screen.dart`
- [ ] Add exports to `editor.dart`
- [ ] Update video export service (if needed)
- [ ] Test trim/drag/sync functionality

---

## 🎯 Key Callbacks Pattern

All child widgets communicate via callbacks:
```dart
// Selection
onSelect: (item) => setState(() => _selected = item),

// Modification
onTrim: (item, newStart, newEnd) {
  setState(() {
    item.startTime = newStart;
    item.endTime = newEnd;
  });
},

// Position change
onPositionChanged: (item, newPos) {
  setState(() => item.position = newPos);
},
```

---

## 🔮 Future Improvements

### Planned Features
- [ ] Multiple audio tracks
- [ ] Video clips (not just images)
- [ ] Sticker overlays
- [ ] Animated text effects
- [ ] Speed ramping
- [ ] Keyframe animations
- [ ] Undo/Redo stack

### Architecture Upgrades
- [ ] Migrate to Riverpod for state management
- [ ] Add BLoC for complex features
- [ ] Implement command pattern for undo/redo
- [ ] Add unit tests for state classes
- [ ] Add widget tests for timeline

---

## 📚 Import Examples

### Full Editor Import
```dart
import 'package:reelspark/editor/editor.dart';

// Now you have access to:
// - EditorScreen
// - All state classes
// - All preview components
// - All timeline components
// - All panels
// - All widgets
```

### Selective Import
```dart
import 'package:reelspark/editor/preview/preview_area.dart';
import 'package:reelspark/editor/timeline/timeline_container.dart';
import 'package:reelspark/models/text_clip.dart';
```

---

## 🐛 Debugging Tips

### Timeline Sync Issues
```dart
// Check playhead position
debugPrint('Time: $_currentPlayTime');
debugPrint('Scroll offset: ${TimelineContainer.scrollController.offset}');
```

### Text Visibility Issues
```dart
// Check clip time range
for (final clip in _textClips) {
  debugPrint('${clip.text}: ${clip.startTime} - ${clip.endTime}');
  debugPrint('Visible at $_currentPlayTime: ${clip.isVisibleAt(_currentPlayTime)}');
}
```

### Audio Sync Issues
```dart
// Check audio seek position
final seekPos = _audioClip?.getAudioSeekPosition(_currentPlayTime);
debugPrint('Audio seek: $seekPos');
```

---

**Happy Coding! 🎬**

