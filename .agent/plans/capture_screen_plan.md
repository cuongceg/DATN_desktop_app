# Implementation Plan: Screen Share Preview Window

## Current State

### Files touching screen share

| File | What it does |
|------|-------------|
| `lib/features/session/screens/widgets/bottom_toolbar.dart` | Creates `LocalVideoTrack` via `createScreenShareTrack()`, publishes it, then **drops the reference**. Calls `provider.setScreenShareState(true/false)`. Generic `catch (e)` with only `debugPrint`. |
| `lib/features/session/providers/meeting_room_provider.dart` | Has `bool isScreenShareOn` flag and `void setScreenShareState(bool)` method. No `screenShareTrack` field. No renderer. |
| `lib/features/session/screens/meeting_room_screen.dart` | Renders the room UI. No overlay logic. No listener for screen share state changes. |

### What is MISSING

- [ ] `LocalVideoTrack` reference stored after `createScreenShareTrack()` — **NO** — `bottom_toolbar.dart` line 98–101: track is created, published, and immediately garbage-collected.
- [ ] `RTCVideoRenderer` initialized with `srcObject` assigned — **NO** — not present anywhere in the session feature.
- [ ] `RTCVideoView` widget rendering the local screen track — **NO** — not present.
- [ ] Screen share card in participant grid — **NO** — no grid slot for local screen share.
- [ ] Wayland/X11 detection logic for Linux — **NO** — `_handleScreenShare` jumps straight to `ScreenSelectDialog` regardless of compositor.
- [ ] Error handling for `PlatformException` on screen capture — **NO** — only `catch (e)` → `debugPrint`.

---

## Gap Analysis (detail)

### `bottom_toolbar.dart` — current screen share code (lines 88–120)

```dart
// What exists — track is NOT stored
final track = await LocalVideoTrack.createScreenShareTrack(
  ScreenShareCaptureOptions(sourceId: source.id, maxFrameRate: 15.0),
);
await provider.room!.localParticipant!.publishVideoTrack(track);
// track goes out of scope here — no way to render preview
provider.setScreenShareState(true);
```

**Gap**: `track` reference is needed for the grid card renderer. It must be saved to the provider.

### `meeting_room_provider.dart` — provider state

```dart
bool isScreenShareOn = false;
// setScreenShareState(bool value) exists
// NO screenShareTrack field
```

**Gap**: Need `LocalVideoTrack? screenShareTrack` to carry the reference between toolbar and grid.

### `participant_grid.dart` — current grid

```dart
class ParticipantGrid extends StatefulWidget {
  final List<Participant> participants;
  final String? localParticipantSid;
  final bool isLocalCamStarting;
  // NO screenShareTrack param — grid has no slot for local screen share
}
```

**Gap**: Grid needs a `screenShareTrack` parameter and pin support for the screen share card.

---

## Implementation Plan

### Step 1 — Store `LocalVideoTrack` in provider after `createScreenShareTrack()` ✅ DONE

Added `LocalVideoTrack? screenShareTrack` field to provider.  
`_handleScreenShare` stores the track; `_disableScreenShare` clears it.

---

### Step 2 — Replace `setScreenShareState` with atomic `startScreenShare` / `stopScreenShare` ✅ DONE

`startScreenShare(LocalVideoTrack)` sets both `screenShareTrack` + `isScreenShareOn` atomically.  
`stopScreenShare()` clears both atomically, then stops the track async.  
Call-sites in `bottom_toolbar.dart` updated.

---

### Step 3 — ~~Floating overlay~~ → Create `ScreenShareTile` grid card  ⚠️ REVISED

> **Previous approach** (Steps 3 & 4 as originally planned) used a floating draggable `OverlayEntry`.
> **New approach**: screen share appears as a card in the `ParticipantGrid`, consistent with
> the participant tile style, and can be pinned just like any participant.

#### Cleanup — remove old overlay artefacts

- **Delete** `lib/features/session/screens/widgets/screen_share_preview_overlay.dart`
- **Revert** `meeting_room_screen.dart` overlay additions:
  - Remove `_provider`, `_screenShareOverlay` fields
  - Remove `_onProviderChanged`, `_insertOverlay`, `_removeOverlay` methods
  - Remove `_provider!.addListener(...)` and `_provider?.removeListener(...)` calls
  - Remove `livekit_client` and `screen_share_preview_overlay` imports
  - Keep `_stopScreenShare()` — it will be passed as a callback to `ParticipantGrid`
  - Keep `_provider` field only if still needed for `onDisconnected`

#### New file to create: `lib/features/session/screens/widgets/screen_share_tile.dart`

A `StatefulWidget` that looks and behaves like `ParticipantTile` but renders the local
screen share track.

```dart
class ScreenShareTile extends StatefulWidget {
  final LocalVideoTrack track;
  final Future<void> Function() onStop;  // unpublish + stopScreenShare
  final VoidCallback? onPin;
  final bool isPinned;

  const ScreenShareTile({
    super.key,
    required this.track,
    required this.onStop,
    this.onPin,
    this.isPinned = false,
  });
}
```

**State behaviour:**
- `initState`: `await _renderer.initialize(); _renderer.srcObject = track.mediaStream;`
- `dispose`: `_renderer.dispose()`
- `_rendererReady` bool gates between `CircularProgressIndicator` and `RTCVideoView`

**Visual spec** (mirrors `ParticipantTile` style):
```
GestureDetector(onTap: onPin)
  └── Container (border: accent when pinned, else transparent)
        └── GlassCard
              └── Stack(fit: expand)
                    ├── RTCVideoView(_renderer)  or  loading spinner
                    ├── Positioned(bottom-left) — label pill
                    │     └── Row: [screen_share icon] "Màn hình của bạn"
                    ├── Positioned(top-right) — stop IconButton (Icons.stop_screen_share)
                    └── Positioned(top-left) — pin icon (when isPinned)
```

**Why**: The `RTCVideoRenderer` lifecycle (async `initialize` / `dispose`) must live in a
`StatefulWidget`. Using `RTCVideoView` (not `VideoTrackRenderer`) satisfies the original
requirement to render via the raw `MediaStream`.

**Dependencies**: Step 2 (track is always non-null when this tile is rendered).

---

### Step 4 — Wire `ScreenShareTile` into `ParticipantGrid` + update `MeetingRoomScreen` ⚠️ REVISED

#### 4a — Extend `ParticipantGrid`

**File**: `lib/features/session/screens/widgets/participant_grid.dart`

Add two new constructor parameters:
```dart
final LocalVideoTrack? screenShareTrack;         // null = no screen share active
final Future<void> Function()? onStopScreenShare; // callback to stop sharing
```

Extend grid state with one new field:
```dart
bool _isScreenSharePinned = false;
```

**Grid rendering logic (updated):**

| Condition | Layout |
|-----------|--------|
| `_isScreenSharePinned` | Big left: `ScreenShareTile` · Small right: participant list |
| `pinnedParticipant != null` | Big left: `ParticipantTile` · Small right: other participants + `ScreenShareTile` (if active) |
| Neither pinned | Auto `GridView` — participants first, then `ScreenShareTile` appended as last item |

Pin/unpin rules:
- Tapping `ScreenShareTile` when nothing is pinned → `_isScreenSharePinned = true`
- Tapping `ScreenShareTile` when it is pinned → `_isScreenSharePinned = false`
- Tapping a `ParticipantTile` always sets `pinnedParticipant` and clears `_isScreenSharePinned`

**When `screenShareTrack` becomes null** (screen share stopped), `_isScreenSharePinned`
must be reset to `false` — handle in `didUpdateWidget`.

#### 4b — Update `MeetingRoomScreen`

**File**: `lib/features/session/screens/meeting_room_screen.dart`

Pass the two new params to `ParticipantGrid`:
```dart
ParticipantGrid(
  participants: provider.participants,
  localParticipantSid: provider.room?.localParticipant?.sid,
  isLocalCamStarting: provider.isCamBusy && provider.isCamOn,
  screenShareTrack: provider.screenShareTrack,    // ← NEW
  onStopScreenShare: _stopScreenShare,             // ← NEW (keep this method)
)
```

Remove all overlay-specific code added in the original Step 4:
- `_provider` field (restore `context.read` usage for `onDisconnected`)
- `_screenShareOverlay` field
- `_onProviderChanged`, `_insertOverlay`, `_removeOverlay` methods
- `_provider!.addListener` / `removeListener` calls
- `livekit_client` and `screen_share_preview_overlay` imports

Keep `_stopScreenShare()` — it is now the `onStopScreenShare` callback for the grid.

**Dependencies**: Step 3 (`ScreenShareTile` must exist).

---

### Step 5 — Wayland/X11 guard + `PlatformException` error handling ✅ DONE

Wayland-only warning dialog added.  
`PlatformException` caught with user-visible error dialog.

---

### Step 6 — (Optional) Resize handle on `ScreenShareTile`

If desired, add a bottom-right `GestureDetector` to the `ScreenShareTile` that adjusts
a `_width` state variable (clamped to `160–600`), with height locked at `_width * 9/16`.

---

## Files to Create

| Path | Purpose |
|------|---------|
| `lib/features/session/screens/widgets/screen_share_tile.dart` | Grid card widget with `RTCVideoRenderer` + `RTCVideoView` that renders the local screen share track, pinnable like a participant tile |

## Files to Delete

| Path | Reason |
|------|--------|
| `lib/features/session/screens/widgets/screen_share_preview_overlay.dart` | Superseded — floating overlay approach replaced by grid card |

## Files to Modify

| Path | Change summary |
|------|---------------|
| `lib/features/session/providers/meeting_room_provider.dart` | ✅ Done — `screenShareTrack` field + `startScreenShare`/`stopScreenShare` |
| `lib/features/session/screens/widgets/bottom_toolbar.dart` | ✅ Done — track stored, Wayland guard, `PlatformException` dialog |
| `lib/features/session/screens/widgets/participant_grid.dart` | Add `screenShareTrack` + `onStopScreenShare` params; render `ScreenShareTile`; extend pin logic |
| `lib/features/session/screens/meeting_room_screen.dart` | Remove overlay code; pass `screenShareTrack` + `onStopScreenShare` to grid |

---

## Checklist

- [x] **Step 1** — Store `LocalVideoTrack` reference in provider
- [x] **Step 2** — Atomic `startScreenShare` / `stopScreenShare` in provider
- [x] **Step 3** — ~~Overlay~~ → Create `ScreenShareTile` grid card + delete old overlay file
- [x] **Step 4** — Wire `ScreenShareTile` into `ParticipantGrid`; update `MeetingRoomScreen`
- [x] **Step 5** — Wayland/X11 guard + `PlatformException` dialog
- [ ] **Step 6** — (Optional) Resize handle on `ScreenShareTile`
