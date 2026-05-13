# Implementation Plan: Session Participants — Full Name & Role

## Objective

Display each participant's **full name** and **role** (teacher / student) inside the
in-meeting Participants panel, sourced from the new backend API.  
Also call `PATCH /leave` so the backend tracks when each user disconnects.

---

## Current State

### What exists

| Layer | File | Current behaviour |
|-------|------|-------------------|
| UI | `participants_panel.dart` | Lists `provider.participants` (LiveKit objects). Shows: first-letter avatar, `p.name`, mic/cam icons. No role, no full name. |
| State | `meeting_room_provider.dart` | Has `List<Participant> participants` (LiveKit). No API participant data. No session context (no sessionId, no service). |
| Data | `session_api.dart` | No `fetchParticipants`, no `leaveSession` method. |
| Data | `session_repository.dart` | No corresponding methods. |
| Data | `session_service.dart` | No corresponding methods. |
| Model | `session_model.dart` | Session metadata only. No participant model. |

### What is MISSING

- [ ] `SessionParticipantModel` — no model for `{ fullName, role, joinedAt, leftAt, isOnline }`
- [ ] `GET /api/sessions/:id/participants` — not wired anywhere in the data layer
- [ ] `PATCH /api/sessions/:id/leave` — not called anywhere in the app
- [ ] `MeetingRoomProvider` session context — provider has no `sessionId` or `SessionService`
- [ ] `ParticipantsPanel` shows full name + role — currently reads only LiveKit `p.name`

---

## Gap Analysis (detail)

### `ParticipantsPanel` — current code

```dart
// participants_panel.dart — what it shows now
final parts = provider.participants; // List<Participant> from LiveKit
ListTile(
  leading: CircleAvatar(child: Text(p.name.isNotEmpty ? p.name[0] : '?')),
  title: Text(p.name),                       // ← LiveKit identity/display name
  trailing: Row([ Icon(mic), Icon(cam) ]),   // ← real-time status
  // NO role, NO full name from backend
)
```

**Gap**: `p.name` is the LiveKit display name (may be a UUID or username), not the
human-readable full name from the user profile. Role is not available at all on the
LiveKit `Participant` object.

### `MeetingRoomProvider` — missing session context

```dart
// meeting_room_provider.dart — disconnect() today
Future<void> disconnect() async {
  // ...disconnects from LiveKit, disposes room...
  // NEVER calls PATCH /leave
}
```

**Gap**: Provider has no `sessionId` or `SessionService` reference, so it cannot call
`/leave` on disconnect.

### Matching LiveKit participants to API participants

The backend generates the LiveKit token with `identity = userId`. So:

```
LiveKit Participant.identity == SessionParticipantModel.userId
```

This lets us merge both data sources in the UI.

---

## Implementation Plan

---

### Step 1 — Create `SessionParticipantModel`

**File to create**: `lib/features/session/models/session_participant_model.dart`

```dart
class SessionParticipantModel {
  final String userId;
  final String fullName;
  final String role;        // 'teacher' | 'student'
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isOnline;

  const SessionParticipantModel({ ... });

  factory SessionParticipantModel.fromJson(Map<String, dynamic> json) => ...
}
```

Map from the API response:
```json
{
  "user_id":    → userId
  "full_name":  → fullName
  "role":       → role
  "joined_at":  → joinedAt (parse ISO 8601, convert .toLocal())
  "left_at":    → leftAt   (nullable)
  "is_online":  → isOnline
}
```

**Why**: All subsequent steps depend on having a typed model for the API data.

**Dependencies**: None.

---

### Step 2 — Add API methods to `SessionApi`

**File to modify**: `lib/features/session/data/session_api.dart`

**Add to `_mapApiError`** (new error messages for the two endpoints):
```dart
// fetchParticipants errors
if (serverMsg == 'You are not a member of this class.') → already exists ✓
if (serverMsg == 'Session not found.')                  → already exists ✓

// leaveSession errors
if (serverMsg == 'You have not joined this session.') {
  return 'Bạn chưa tham gia buổi học này.';
}
if (serverMsg == 'You have already left this session.') {
  return 'Bạn đã rời buổi học này rồi.';
}
```

**Add two new methods**:

```dart
/// GET /api/sessions/:sessionId/participants
Future<Map<String, dynamic>> fetchParticipants(String sessionId) async {
  try {
    final response = await _dio.get('/api/sessions/$sessionId/participants');
    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw Exception(_mapApiError(e));
  }
}

/// PATCH /api/sessions/:sessionId/leave
Future<void> leaveSession(String sessionId) async {
  try {
    await _dio.patch('/api/sessions/$sessionId/leave');
  } on DioException catch (e) {
    throw Exception(_mapApiError(e));
  }
}
```

**Why**: The data layer must expose the two new endpoints before any higher layer can use them.

**Dependencies**: Step 1 (model will be used by the repository, not the API class itself).

---

### Step 3 — Add methods to `SessionRepository` and `SessionService`

**File to modify**: `lib/features/session/data/session_repository.dart`

```dart
Future<List<SessionParticipantModel>> getParticipants(String sessionId) async {
  final data = await _api.fetchParticipants(sessionId);
  final list = data['participants'] as List<dynamic>;
  return list
      .map((j) => SessionParticipantModel.fromJson(j as Map<String, dynamic>))
      .toList();
}

Future<void> leaveSession(String sessionId) {
  return _api.leaveSession(sessionId);
}
```

**File to modify**: `lib/features/session/services/session_service.dart`

```dart
Future<List<SessionParticipantModel>> getParticipants(String sessionId) {
  return _repo.getParticipants(sessionId);
}

Future<void> leaveSession(String sessionId) {
  return _repo.leaveSession(sessionId);
}
```

**Why**: Follows the existing API → Repository → Service layering pattern already used for
`joinSession`, `startSession`, etc.

**Dependencies**: Steps 1 and 2.

---

### Step 4 — Extend `MeetingRoomProvider`

**File to modify**: `lib/features/session/providers/meeting_room_provider.dart`

#### 4a — Add session context (setter, not constructor change)

```dart
// New private fields
String? _sessionId;
SessionService? _sessionService;

// New public fields
List<SessionParticipantModel> sessionParticipants = [];
bool isLoadingParticipants = false;

// Setter called by MeetingRoomScreen after the provider is created
void setSessionContext(String sessionId, SessionService service) {
  _sessionId = sessionId;
  _sessionService = service;
}
```

Using a setter (not a constructor param) means **no call-sites need to change** — callers
still write `MeetingRoomProvider()` with no args.

#### 4b — Add `fetchSessionParticipants()`

```dart
Future<void> fetchSessionParticipants() async {
  if (_sessionId == null || _sessionService == null) return;
  isLoadingParticipants = true;
  notifyListeners();
  try {
    sessionParticipants = await _sessionService!.getParticipants(_sessionId!);
  } catch (e) {
    debugPrint('[MeetingRoom] fetchSessionParticipants error: $e');
  } finally {
    isLoadingParticipants = false;
    notifyListeners();
  }
}
```

#### 4c — Auto-refresh on participant join/leave events

In `_setupListeners()`, add two new event handlers after the existing
`RoomDisconnectedEvent` handler:

```dart
..on<ParticipantConnectedEvent>((_) => fetchSessionParticipants())
..on<ParticipantDisconnectedEvent>((_) => fetchSessionParticipants())
```

This keeps `isOnline` status up-to-date without manual polling.

#### 4d — Call `/leave` inside `disconnect()`

```dart
Future<void> disconnect() async {
  if (room == null || _isDisconnecting) return;
  _isDisconnecting = true;
  // ... existing cleanup ...

  // NEW: record leave — fire-and-forget, must not block UI
  final sid = _sessionId;
  final svc = _sessionService;
  if (sid != null && svc != null) {
    svc.leaveSession(sid).catchError((e) {
      debugPrint('[MeetingRoom] leaveSession error (suppressed): $e');
    });
  }

  // ... existing room.disconnect() and dispose() ...
}
```

**Why fire-and-forget**: The user is already leaving; blocking the disconnect on a network
call would feel frozen. A failed `/leave` is acceptable (stale `is_online` for at most
one polling cycle).

**Dependencies**: Step 3.

---

### Step 5 — Call `setSessionContext` from `MeetingRoomScreen`

**File to modify**: `lib/features/session/screens/meeting_room_screen.dart`

In `initState`, after setting `onDisconnected`, add:

```dart
// Import needed at top of file:
import 'package:provider/provider.dart';  // already present
import '../../../services/session_service_locator.dart';  // or however SessionService is obtained

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  final provider = context.read<MeetingRoomProvider>();

  // Existing
  provider.onDisconnected = () {
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  };

  // NEW — wire session context so provider can fetch participants and call /leave
  final sessionService = context.read<SessionProvider>().service; // see note below
  provider.setSessionContext(widget.sessionId, sessionService);
  provider.fetchSessionParticipants();   // initial load
});
```

> **Note on obtaining `SessionService`**: Check how the existing `SessionProvider` exposes
> its service. If it doesn't, expose it via a getter: `SessionService get service => _service;`
> on `SessionProvider`. This is a one-line addition and keeps DI unchanged.

**Why here, not in `JoinScreen`**: `JoinScreen` creates the provider but doesn't have
`sessionId` readily wired for this purpose yet. `MeetingRoomScreen` already receives
`sessionId` as a constructor param and has access to both the provider and the service
via `context.read`.

**Dependencies**: Step 4.

---

### Step 6 — Upgrade `ParticipantsPanel`

**File to modify**: `lib/features/session/screens/widgets/participants_panel.dart`

#### Data merging

Create a helper inside the file to merge both data sources:

```dart
// Match API participant to a live LiveKit Participant using identity == userId
Participant? _findLiveParticipant(
  String userId,
  List<Participant> liveParticipants,
) {
  try {
    return liveParticipants.firstWhere((p) => p.identity == userId);
  } catch (_) {
    return null;
  }
}
```

#### New list item layout

Replace the current `ListTile` with a richer row:

```
ListTile
  leading: CircleAvatar
    ├── backgroundColor: accent for teacher, grey for student
    └── child: Text(fullName[0].toUpperCase())

  title: Text(fullName, fontWeight: bold)      ← from API

  subtitle: Row(
    ├── _RoleBadge(role)                        ← "Giáo viên" or "Học sinh"
    └── (optional) Text("Tham gia lúc HH:mm")
  )

  trailing: Row(
    ├── Icon(online indicator — green dot / grey dot)   ← from isOnline
    ├── SizedBox(width: 4)
    ├── Icon(mic / mic_off)                             ← from LiveKit if online
    └── Icon(videocam / videocam_off)                   ← from LiveKit if online
  )
```

#### Fallback when API data not loaded

If `provider.sessionParticipants.isEmpty` (initial load or error):
- Show a `LinearProgressIndicator` at the top when `provider.isLoadingParticipants`
- Fall back to the existing LiveKit-only list so the panel is never blank

#### Full refresh button

Add an `IconButton(Icons.refresh)` next to the header title that calls
`provider.fetchSessionParticipants()`.

**Why**: Provides a user-visible recovery path if the auto-refresh on participant events
misses a change.

**Dependencies**: Steps 1 and 4.

---

## Files to Create

| Path | Purpose |
|------|---------|
| `lib/features/session/models/session_participant_model.dart` | Typed model for `GET /participants` response items |

## Files to Modify

| Path | Change summary |
|------|---------------|
| `lib/features/session/data/session_api.dart` | Add `fetchParticipants()` + `leaveSession()` + 2 error strings |
| `lib/features/session/data/session_repository.dart` | Add `getParticipants()` + `leaveSession()` |
| `lib/features/session/services/session_service.dart` | Add `getParticipants()` + `leaveSession()` |
| `lib/features/session/providers/meeting_room_provider.dart` | Add session context setter, `sessionParticipants`, `fetchSessionParticipants()`, `/leave` in disconnect |
| `lib/features/session/screens/meeting_room_screen.dart` | Call `setSessionContext` + `fetchSessionParticipants()` in `initState` |
| `lib/features/session/screens/widgets/participants_panel.dart` | Merge API + LiveKit data; show full name, role, online status |

---

## Checklist

- [ ] **Step 1** — Create `SessionParticipantModel` with `fromJson`
- [ ] **Step 2** — Add `fetchParticipants` + `leaveSession` to `SessionApi`
- [ ] **Step 3** — Add methods to `SessionRepository` + `SessionService`
- [ ] **Step 4** — Extend `MeetingRoomProvider` (context setter, fetch, auto-refresh, `/leave` in disconnect)
- [ ] **Step 5** — Wire `setSessionContext` + initial fetch in `MeetingRoomScreen.initState`
- [ ] **Step 6** — Upgrade `ParticipantsPanel` (full name, role badge, online dot, merge with LiveKit)
