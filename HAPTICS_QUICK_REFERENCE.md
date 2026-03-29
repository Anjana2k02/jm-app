# Quick Haptics Reference

## Import
```dart
import '../../utils/haptics.dart';
```

## Quick Usage Examples

### Light Feedback (Songs, Selections)
```dart
HapticsManager.songSelectedFeedback();      // Song tap
HapticsManager.lightTap();                  // Generic light tap
HapticsManager.zoomFeedback();              // Zoom step
```

### Medium Feedback (States, Toggles)
```dart
HapticsManager.mediumTap();                 // General medium feedback
HapticsManager.sidebarToggleFeedback();     // Show/hide sidebar
HapticsManager.dismissFeedback();           // Swipe dismiss
HapticsManager.dragEndFeedback();           // Drag completed
```

### Heavy Feedback (Start, Important)
```dart
HapticsManager.heavyTap();                  // Heavy single tap
HapticsManager.dragStartFeedback();         // Drag began
HapticsManager.longPressFeedback();         // Long-press triggered
```

### Special Patterns
```dart
HapticsManager.successFeedback();           // Success (light→medium)
HapticsManager.errorFeedback();             // Error (double pulse)
```

## Haptic Intensity Mapping

| User Action | Feedback Type | Explanation |
|---|---|---|
| Tap list item | `songSelectedFeedback()` | Light - frequent action |
| Long-press drag | `dragStartFeedback()` | Heavy - drag begins |
| Dragging | `dragContinuousFeedback()` | Medium - during drag |
| Drop/finish drag | `dragEndFeedback()` | Medium - drag ends |
| Swipe to dismiss | `dismissFeedback()` | Medium - destructive action |
| Pinch zoom start | `dragStartFeedback()` | Heavy - pinch begins |
| Pinch zoom update | `dragContinuousFeedback()` | Medium - zooming |
| Ctrl+± zoom | `zoomFeedback()` | Light - per km step |
| Toggle sidebar | `sidebarToggleFeedback()` | Medium - state change |

## Implementation Pattern

```dart
// Simple action
onTap: () {
  HapticsManager.songSelectedFeedback();
  _doSomething();
}

// Multi-stage action
onDragStart: (details) {
  HapticsManager.dragStartFeedback();
  _startDrag(details);
}

onDragUpdate: (details) {
  HapticsManager.dragContinuousFeedback();
  _updateDrag(details);
}

onDragEnd: (details) {
  HapticsManager.dragEndFeedback();
  _completeDrag(details);
}
```

## Where Haptics Are Currently Used

✅ **lib/widgets/document_list_tile.dart** - Song selection
✅ **lib/widgets/song_card.dart** - Song selection  
✅ **lib/screens/sessions/session_detail_screen.dart** - Zoom, drag, dismiss
✅ **lib/screens/mobile/mobile_editor_screen.dart** - Sidebar toggle

## Safe Error Handling

All methods automatically handle devices without haptic support:
```dart
// This won't crash on unsupported devices
HapticsManager.heavyTap();  // ✓ Safe

// Internal error handling
try {
  await HapticFeedback.heavyImpact();
} catch (_) {
  // Device doesn't support haptics - ignore
}
```

## Testing

To test haptics:
1. Build APK: `flutter build apk --release` ✓
2. Install on physical Android device
3. Enable haptics in device settings
4. Try each action and feel the feedback

---
For detailed info, see [HAPTICS_IMPLEMENTATION.md](HAPTICS_IMPLEMENTATION.md)
