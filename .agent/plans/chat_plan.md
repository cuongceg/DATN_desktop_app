# Implementation Plan: Real-Time Chat Panel

## Objective

Connect the existing `ChatPanel` widget to the real backend APIs:
- `GET /api/sessions/:sessionId/messages` — load message history (with pagination)
- `POST /api/sessions/:sessionId/messages` — send a message

Also fix the "who am I" detection so sent messages appear on the correct side, and add periodic polling so new messages from other participants appear automatically.

---

## Current State

### What exists

| Layer | File | Current behaviour |
|-------|------|-------------------|
| Model | `message_model.dart` | Has `senderName` field but API only returns `sender_id` — `fromJson` falls back to `'Unknown'` |
| Data | `session_api.dart` | `fetchMessages()` + `sendMessage()` already implemented |
| Data | `session_repository.dart` | `fetchMessages()` + `sendMessage()` already delegate to API |
| Service | `session_service.dart` | No chat methods (repository methods not surfaced) |
| UI | `chat_panel.dart` | `_fetchMessages()` is an empty stub; `_sendMessage()` adds a **local fake** message and never calls the API |

### What is MISSING

- [ ] `SessionService` does not expose `fetchMessages` / `sendMessage`
- [ ] `ChatPanel` is not connected to any real data source
- [ ] "IsMe" detection is hardcoded: `msg.senderId == 'me'` — always false for real data
- [ ] No polling — messages from other participants never appear
- [ ] `MessageModel.senderName` is not returned by the API; needs to be resolved from participant data or left nullable
- [ ] No pagination (limit / offset) implemented in the UI

---

## Gap Analysis

### API response vs `MessageModel`

```
API response field  →  MessageModel field
id                  →  id          ✓
session_id          →  sessionId   ✓
sender_id           →  senderId    ✓
content             →  content     ✓
timestamp           →  timestamp   ✓
(absent)            →  senderName  ← must be resolved from SessionParticipantModel list
```

`senderName` is not returned by the API. Resolution strategy: match `senderId == SessionParticipantModel.userId` and take `fullName`. Fallback: show `'Người dùng'`.

### "IsMe" detection

`context.read<AuthNotifier>().currentUser?.id` gives the current user's ID. Compare with `msg.senderId` to determine message alignment.

---

## Implementation Plan

---

### Step 1 — Surface chat methods in `SessionService`

**File to modify**: `lib/features/session/services/session_service.dart`

Add two methods that delegate to the repository:

```dart
Future<List<MessageModel>> fetchMessages(String sessionId) {
  return _repo.fetchMessages(sessionId);
}

Future<MessageModel> sendMessage(String sessionId, String content) {
  return _repo.sendMessage(sessionId, content);
}
```

Also import `MessageModel`.

**Why**: The service layer is currently missing these two methods, so `ChatPanel` cannot use DI-provided services.

**Dependencies**: None.

---

### Step 2 — Create `ChatProvider`

**File to create**: `lib/features/session/providers/chat_provider.dart`

```dart
class ChatProvider extends ChangeNotifier {
  final SessionService _service;
  final String _sessionId;
  final String currentUserId;

  List<MessageModel> messages = [];
  bool isLoading = false;
  bool isSending = false;
  String? errorMessage;
  Timer? _pollTimer;

  ChatProvider({
    required SessionService service,
    required String sessionId,
    required this.currentUserId,
  })  : _service = service,
        _sessionId = sessionId;

  Future<void> loadMessages() async { ... }

  Future<void> sendMessage(String content) async { ... }

  void startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => loadMessages());
  }

  void stopPolling() => _pollTimer?.cancel();

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
```

**Polling strategy**: Every 5 seconds call `loadMessages()` silently (no loading indicator on poll, only on initial load).

**Why**: Centralises state (loading, sending, list), enables testability, and decouples polling lifecycle from the widget.

**Dependencies**: Step 1.

---

### Step 3 — Wire `ChatProvider` into `ChatPanel`

**File to modify**: `lib/features/session/screens/widgets/chat_panel.dart`

Replace local `List<MessageModel> messages` state with a `ChatProvider` scoped to the panel:

```dart
@override
Widget build(BuildContext context) {
  return ChangeNotifierProvider(
    create: (_) => ChatProvider(
      service: context.read<SessionProvider>().service,
      sessionId: widget.sessionId,
      currentUserId: context.read<AuthNotifier>().currentUser!.id,
    )..loadMessages()..startPolling(),
    child: Consumer<ChatProvider>(
      builder: (_, chat, __) => _buildBody(context, chat),
    ),
  );
}
```

The `isMe` check becomes:
```dart
final isMe = msg.senderId == chat.currentUserId;
```

**Why**: The provider is scoped to `ChatPanel`'s lifetime so polling starts when the panel opens and stops automatically when it closes (via `dispose`).

**Dependencies**: Step 2.

---

### Step 4 — Resolve `senderName` from participant list

**File to modify**: `lib/features/session/screens/widgets/chat_panel.dart`

Add a helper that looks up the sender's full name from `MeetingRoomProvider.sessionParticipants`:

```dart
String _resolveName(
  String senderId,
  String currentUserId,
  List<SessionParticipantModel> participants,
) {
  if (senderId == currentUserId) return 'Tôi';
  try {
    return participants.firstWhere((p) => p.userId == senderId).fullName;
  } catch (_) {
    return 'Người dùng';
  }
}
```

Use `context.read<MeetingRoomProvider>().sessionParticipants` inside the list item builder.

**Why**: API messages carry only `sender_id`; full names must be resolved from the participant list already loaded by `MeetingRoomProvider`.

**Dependencies**: Step 3, participants feature (already implemented).

---

### Step 5 — Wire send + UI polish

**File to modify**: `lib/features/session/screens/widgets/chat_panel.dart`

- `_sendMessage` calls `chat.sendMessage(text)` and awaits it
- Disable the send `IconButton` + show `CircularProgressIndicator` while `chat.isSending`
- Show error `SnackBar` if `chat.errorMessage` is non-null after a send
- Auto-scroll to bottom after new messages (post-frame callback on `ScrollController`)
- Show a small timestamp (`HH:mm`) below each message bubble

**Why**: Completes the visible chat feature for the user.

**Dependencies**: Step 3.

# Step 6: Fix the mic feature on student side
Student join in the meeting room, the mic is open in current. But I want to turn off by default, and student can't open it. 
---

## Files to Create

| Path | Purpose |
|------|---------|
| `lib/features/session/providers/chat_provider.dart` | State, polling, send logic |

## Files to Modify

| Path | Change |
|------|--------|
| `lib/features/session/services/session_service.dart` | Expose `fetchMessages` + `sendMessage` |
| `lib/features/session/screens/widgets/chat_panel.dart` | Wire real data, polling, name resolution, UI polish |

---

## Checklist

- [ ] **Step 1** — Surface chat methods in `SessionService`
- [ ] **Step 2** — Create `ChatProvider` with `loadMessages`, `sendMessage`, `startPolling`/`stopPolling`
- [ ] **Step 3** — Replace local state in `ChatPanel` with `ChatProvider`; fix `isMe` detection
- [ ] **Step 4** — Resolve `senderName` from `MeetingRoomProvider.sessionParticipants`
- [ ] **Step 5** — Wire real send, loading indicator, error handling, auto-scroll, timestamps
- [ ] **Step 6** — Fix the mic feature on student side