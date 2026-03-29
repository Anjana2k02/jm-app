# Haptics Integration Architecture

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interactions                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┬──────────────┐
        │                  │                  │              │
        ▼                  ▼                  ▼              ▼
    ┌────────┐         ┌────────┐        ┌────────┐    ┌─────────┐
    │  Song  │         │  Zoom  │        │ Drag & │    │ Sidebar │
    │ Select │         │ Sheet  │        │ Reorder│    │ Toggle  │
    └──┬─────┘         └───┬────┘        └────┬───┘    └────┬────┘
       │                   │                   │            │
       │                   └───────┬───────────┴────────────┘
       │                           │
       ▼                           ▼
    ┌───────────────────────────────────────┐
    │     HapticsManager (lib/utils/)       │
    │  ─────────────────────────────────   │
    │  All haptic feedback coordinated      │
    │  Safe error handling built-in         │
    └───────────┬───────────────────────────┘
                │
    ┌───────────┼───────────────────────────────────┐
    │           │                                   │
    ▼           ▼                                   ▼
┌─────────┐  ┌──────────┐                    ┌──────────────┐
│ Android │  │   iOS    │                    │ Web/Desktop  │
│ Device  │  │ Device   │                    │ (No haptics) │
│Vibrator │  │ Haptics  │                    │   Ignored    │
└─────────┘  └──────────┘                    └──────────────┘
```

## Feedback Intensity Pyramid

```
                    ▲
                    │
                    │     HEAVY
                    │     ┌─────┐
                    │     │▁▂▃▄▅│  dragStartFeedback()
                    │     │     │  heavyTap()
                    │     └─────┘
                    │
                    │     MEDIUM
                    │  ┌──────────┐
                    │  │▁▂▃▄▁▂▃▄▁▂│ dragEndFeedback()
                    │  │          │ dismissFeedback()
                    │  │          │ sidebarToggleFeedback()
                    │  └──────────┘
                    │
                    │ LIGHT
                    │ ┌────────────┐
                    │ │▁▂▃▁▂▃▁▂▃▁▂▃│ songSelectedFeedback()
                    │ │            │ zoomFeedback()
                    │ └────────────┘
                    │
     Frequent ◄────┴────► Important
     Actions       Actions
```

## Interaction Flow Examples

### Song Selection Flow
```
User Tap
   │
   ▼
┌────────────────────────────┐
│ DocumentListTile.onTap()   │
│ SongCard.onTap()           │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│ HapticsManager.            │
│ songSelectedFeedback()     │
└────────┬───────────────────┘
         │
         ▼
    [LIGHT TAP]
    (Quick, unobtrusive)
         │
         ▼
    Selection Updates
```

### Drag & Reorder Flow (Multi-Stage)
```
User Long-Press
    │
    ▼
─────────────────────────────
│                           │
│ _reorderSongs() START     │
│                           │
│ HapticsManager.           │
│ dragStartFeedback()       │
│                           │
│ [HEAVY TAP]               │
│                           │
─────────────────────────────
    │ User holds and drags
    ▼
─────────────────────────────
│                           │
│ _handleScaleUpdate()      │
│                           │
│ HapticsManager.           │
│ dragContinuousFeedback()  │
│                           │
│ [MEDIUM TAP] (repeated)   │
│                           │
─────────────────────────────
    │ User releases
    ▼
─────────────────────────────
│                           │
│ _reorderSongs() END       │
│                           │
│ HapticsManager.           │
│ dragEndFeedback()         │
│                           │
│ [MEDIUM TAP]              │
│ (Confirms completion)     │
│                           │
─────────────────────────────
```

### Zoom Feedback Flow (Multi-Method)
```
                    Zoom Initiation
                           │
           ┌───────────────┼───────────────┐
           │               │               │
        Pinch         Keyboard         Mouse Wheel
       (Touch)         (Ctrl+±)         (Ctrl+🔘)
           │               │               │
           ▼               ▼               ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │ Scale      │  │ Keyboard   │  │ Pointer    │
    │ Gesture    │  │ Event      │  │ Signal     │
    └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
          │               │               │
          └───────────────┼───────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │ _bumpSheetScale()               │
        │ _handleScaleStart/Update()      │
        └────────────┬────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   [HEAVY TAP]            [LIGHT TAP per step]
   (Only on start)        (Every increment)
```

### Sidebar Toggle Flow (Mobile)
```
User Action (3 Points)
  │
  ├─────────────────┬──────────────────┬─────────────────┐
  │                 │                  │                 │
  ▼                 ▼                  ▼                 ▼
Hide Button    Scrim Tap          Show Button      (Chevron Tab)
(Chevron←)    (Gray overlay)    (Chevron→ tab)
  │                 │                  │                 │
  └─────────────────┼──────────────────┴─────────────────┘
                    │
                    ▼
        ┌──────────────────────────┐
        │ setState() + Haptics     │
        │ sidebarToggleFeedback()  │
        │ [MEDIUM TAP]             │
        └──────────────────────────┘
                    │
                    ▼
            Sidebar visibility
            toggles smoothly
```

## File Organization

```
jammer_app/
├── lib/
│   ├── utils/
│   │   └── haptics.dart ..................... ✨ NEW - Haptics Manager
│   │
│   ├── widgets/
│   │   ├── document_list_tile.dart ......... ✏️ + songSelectedFeedback()
│   │   └── song_card.dart .................. ✏️ + songSelectedFeedback()
│   │
│   └── screens/
│       ├── sessions/
│       │   └── session_detail_screen.dart .. ✏️ + 6 haptic calls
│       │       ├── Zoom feedback
│       │       ├── Drag feedback
│       │       └── Dismiss feedback
│       │
│       └── mobile/
│           └── mobile_editor_screen.dart ... ✏️ + 3 toggle feedbacks
│
├── HAPTICS_IMPLEMENTATION.md ............... ✨ NEW - Full guide
├── HAPTICS_QUICK_REFERENCE.md ............. ✨ NEW - Quick guide
└── HAPTICS_SESSION_SUMMARY.md ............. ✨ NEW - This session

Legend: ✨ NEW | ✏️ MODIFIED
```

## Method Call Hierarchy

```
HapticsManager (singleton utility)
│
├── lightImpact() ──────────────────┬──► songSelectedFeedback()
│                                   └──► zoomFeedback()
│
├── mediumImpact() ────────────────────┬──► mediumTap()
│                                     ├──► sidebarToggleFeedback()
│                                     ├──► dragEndFeedback()
│                                     └──► dismissFeedback()
│
├── heavyImpact() ──────────────────┬──► heavyTap()
│                                   ├──► dragStartFeedback()
│                                   └──► longPressFeedback()
│
├── selectionClick() ──────────────────────► dragContinuousFeedback()
│
└── Compound Patterns
    ├── successFeedback()  = light + delay + medium
    └── errorFeedback()    = heavy + delay + heavy
```

## Data Flow for a Complete Interaction

### Example: User drags a song to reorder

```
┌─────────────────────────────────────────────────────────────────┐
│                      User Initiates Long-Press                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │ ReorderableDelayedDragStartListener │ starts drag
        └────────────────┬───────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │ _reorderSongs(oldIndex, newIndex) called   │
        │ STAGE 1: START                             │
        └────────────────┬───────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │ HapticsManager.dragStartFeedback() called  │
        │ • Calls HapticFeedback.heavyImpact()      │
        │ Result: [STRONG VIBRATION]                │
        │ User feels: "Drag started!"                │
        └────────────────┬───────────────────────────┘
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
      ┌──────────────────┐   ┌──────────────────┐
      │ User drags song  │   │ proxyDecorator   │
      │ through list     │   │ animates scale   │
      └──────────────────┘   └──────────────────┘
              │                     │
              └──────────┬──────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │ _handleScaleUpdate() called continuously   │
        │ STAGE 2: CONTINUOUS DRAG                   │
        └────────────────┬───────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │ HapticsManager.dragContinuousFeedback()    │
        │ • Calls HapticFeedback.selectionClick()   │
        │ Result: [MEDIUM CLICKS]                   │
        │ User feels: "Still dragging..."            │
        │ (Called once per scale change)             │
        └────────────────┬───────────────────────────┘
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
      ┌──────────────────┐   ┌──────────────────┐
      │ User continues   │   │ Song position    │
      │ dragging         │   │ updates in UI    │
      └──────────────────┘   └──────────────────┘
              │                     │
              └──────────┬──────────┘
                         │
                         ▼ User releases touch
        ┌────────────────────────────────────────────┐
        │ Drag gesture completes                     │
        │ STAGE 3: END                               │
        └────────────────┬───────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │ _reorderSongs() completes execution        │
        │ List has been reordered                     │
        └────────────────┬───────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │ HapticsManager.dragEndFeedback() called    │
        │ • Calls HapticFeedback.mediumImpact()     │
        │ Result: [MEDIUM VIBRATION]                │
        │ User feels: "Drag complete!"               │
        └────────────────┬───────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────────────┐
        │ upsertSessionSongOrder() saved to database │
        │ Reorder is persisted                       │
        └────────────────────────────────────────────┘
```

## Error Handling & Safety

```
Application Layer
│
├── User interaction triggers haptic
│
▼
┌──────────────────────────────────┐
│ HapticsManager.someMethod()      │
│ (Application calling code)       │
└─────────────┬────────────────────┘
              │
              ▼
        try {
              │
              ▼
        HapticFeedback.someImpact()
              │
        } catch (_) {
              │
              ▼
        // Device doesn't support haptics
        // Application continues normally
        // User just doesn't feel vibration
        }
              │
              ▼
        Application continues normally ✓
```

---
*This architecture ensures haptics enhance the experience while maintaining app stability across all devices.*
