# STT Subtitle Implementation Plan

## Files to CREATE

### 1. `lib/features/session/screens/widgets/subtitle_overlay.dart`
New widget. Displays subtitle text at bottom-center of the screen as a
semi-transparent pill/bar. Accepts `String? subtitleText` and `bool isTeacher`.
Uses `AnimatedOpacity` for fade-out (opacity driven by parent state, not internal
timer — parent clears `subtitleText` after 5 s). Uses `GlassTheme` colors.

---

## Files to MODIFY

### 2. `lib/features/session/screens/meeting_room_screen.dart`
Add subtitle state management and LiveKit DataChannel integration:

- Add imports: `dart:async`, `dart:convert`, `dart:typed_data`,
  `package:livekit_client/livekit_client.dart`,
  `../../../features/stt/services/stt_service.dart`,
  `widgets/subtitle_overlay.dart`.
- Add state fields to `_MeetingRoomScreenState`:
  - `String? _subtitleText`
  - `Timer? _subtitleTimer`
  - `StreamSubscription<String>? _sttSub`
  - `bool _isSttOn = false`
- Add `_onSubtitleText(String text)` helper:
  sets `_subtitleText = text`, resets `_subtitleTimer` (cancel + restart 5 s
  auto-clear that sets `_subtitleText = null`).
- **Teacher side** — in `initState` (after `addPostFrameCallback`), do NOT start
  STT here; only wire up on toggle.
- Add `_toggleStt()` async method:
  - If turning ON: subscribe to `sttService.transcriptStream` → `_onSubtitleText`,
    publish text to DataChannel (`room.localParticipant?.publishData(..., topic: 'subtitles')`),
    call `sttService.start()`, `setState(() => _isSttOn = true)`.
  - If turning OFF: cancel `_sttSub`, call `sttService.stop()`,
    `setState(() { _isSttOn = false; _subtitleText = null; })`.
- **Student side** — in `initState` postFrameCallback, register
  `provider.room?.on<DataReceivedEvent>((event) { if (event.topic == 'subtitles') ... })`
  to call `_onSubtitleText`.
  Because `room` may not exist yet at `initState` time, hook into
  `MeetingRoomProvider` via a listener and register the DataChannel handler
  once `provider.room != null`.
- Wrap the `ParticipantGrid` `Expanded` widget in a `Stack`, adding
  `SubtitleOverlay` at `Alignment.bottomCenter` inside the stack.
- Pass `isSttOn: _isSttOn` and `onToggleStt: widget.isTeacher ? _toggleStt : null`
  to `BottomToolbar`.
- In `dispose()`: cancel `_sttSub`, cancel `_subtitleTimer`,
  stop STT if running (`sttService.stop()`).

### 3. `lib/features/session/screens/widgets/bottom_toolbar.dart`
Add subtitle toggle button (teacher-only):

- Add constructor params: `bool isSttOn = false`,
  `VoidCallback? onToggleStt`.
- Inside the `if (isTeacher)` block, after the mic `_ToolbarButton` + spacer,
  add another `_ToolbarButton`:
  - `icon`: `Icons.closed_caption` (on) / `Icons.closed_caption_outlined` (off)
  - `label`: `'Tắt phụ đề'` (on) / `'Bật phụ đề'` (off)
  - `onTap`: `onToggleStt ?? () {}`
  - `isActive`: `isSttOn`
  - `activeColor`: `GlassTheme.accent`

---

## Summary table

| # | Action | File | One-liner |
|---|--------|------|-----------|
| 1 | CREATE | `lib/features/session/screens/widgets/subtitle_overlay.dart` | Semi-transparent subtitle pill widget with AnimatedOpacity |
| 2 | MODIFY | `lib/features/session/screens/meeting_room_screen.dart` | Subtitle state, STT subscription (teacher), DataChannel listener (student), Stack wrapping ParticipantGrid |
| 3 | MODIFY | `lib/features/session/screens/widgets/bottom_toolbar.dart` | Add `isSttOn` + `onToggleStt` params; render subtitle toggle button for teacher |

---

## Constraints checklist
- [ ] ParticipantGrid, ParticipantTile, screen share logic — NOT touched
- [ ] SttService, SttPocScreen — NOT touched
- [ ] home_screen.dart, sidebar_navigation.dart — NOT touched
- [ ] `initialize()` NOT called inside meeting screen
- [ ] Mic toggle button only appears on teacher side ✓ (existing guard + new guard)
- [ ] DataChannel topic exactly `'subtitles'`
- [ ] Vietnamese strings: `'Bật phụ đề'` / `'Tắt phụ đề'`
- [ ] Linux/Ubuntu desktop only target ✓
