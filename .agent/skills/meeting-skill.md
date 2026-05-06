# SKILLS_FLUTTER.md — Flutter Desktop UI: Session (Meeting) Feature

> Tech stack: Flutter Desktop, Provider, go_router, Glassmorphism (dark + light theme)
> Feature-based architecture

---

## 1. Folder Structure

```
lib/
├── features/
│   ├── auth/                  # ✅ Done
│   ├── dashboard/             # ✅ Done
│   ├── class/                 # ✅ Done
│   └── session/               # ← MỚI
│       ├── data/
│       │   ├── session_api.dart          # Gọi REST API backend
│       │   └── session_repository.dart   # Xử lý data, map JSON → model
│       ├── models/
│       │   ├── session_model.dart        # Session, SessionStatus
│       │   └── message_model.dart        # Chat message
│       ├── providers/
│       │   ├── session_provider.dart     # State: list sessions, create, start, end
│       │   └── meeting_room_provider.dart # State: in-room (mic, cam, participants)
│       └── screens/
│           ├── session_list_screen.dart  # Danh sách sessions của 1 lớp
│           ├── session_detail_screen.dart # Chi tiết session + nút join
│           └── meeting_room_screen.dart  # Màn hình trong buổi học (LiveKit)
│               └── widgets/
│                   ├── participant_grid.dart    # Grid video các participants
│                   ├── participant_tile.dart    # 1 ô video của 1 người
│                   ├── bottom_toolbar.dart      # Mic, Cam, Chat, End
│                   ├── chat_panel.dart          # Slide-in chat sidebar
│                   └── participants_panel.dart  # Slide-in danh sách người
├── core/
│   ├── theme/
│   │   ├── app_theme.dart       # ThemeData dark + light
│   │   └── glass_theme.dart     # Glassmorphism helpers
│   └── widgets/
│       └── glass_card.dart      # Reusable GlassCard widget
```

---

## 2. Glassmorphism Design Tokens

### `lib/core/theme/glass_theme.dart`
```dart
import 'package:flutter/material.dart';
import 'dart:ui';

class GlassTheme {
  // --- Dark theme ---
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface    = Color(0x1AFFFFFF); // white 10%
  static const Color darkBorder     = Color(0x33FFFFFF); // white 20%
  static const Color darkText       = Color(0xFFFFFFFF);
  static const Color darkSubText    = Color(0x99FFFFFF); // white 60%
  static const Color accent         = Color(0xFF6C63FF); // purple accent

  // --- Light theme ---
  static const Color lightBackground = Color(0xFFF0F4FF);
  static const Color lightSurface    = Color(0x99FFFFFF); // white 60%
  static const Color lightBorder     = Color(0x33000000); // black 20%
  static const Color lightText       = Color(0xFF1A1A2E);
  static const Color lightSubText    = Color(0x991A1A2E); // dark 60%

  // --- Blur ---
  static const double blurStrength = 12.0;
  static const double cardRadius   = 16.0;
  static const double panelRadius  = 20.0;
}
```

### Reusable `GlassCard` widget — `lib/core/widgets/glass_card.dart`
```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = GlassTheme.cardRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? GlassTheme.darkSurface : GlassTheme.lightSurface;
    final border  = isDark ? GlassTheme.darkBorder  : GlassTheme.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTheme.blurStrength,
            sigmaY: GlassTheme.blurStrength,
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

---

## 3. Data Models

### `session_model.dart`
```dart
enum SessionStatus { scheduled, ongoing, completed }

class SessionModel {
  final String id;
  final String classId;
  final String title;
  final SessionStatus status;
  final String? livekitRoomId;
  final DateTime? startTime;
  final DateTime? endTime;

  const SessionModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.status,
    this.livekitRoomId,
    this.startTime,
    this.endTime,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    id:             json['id'],
    classId:        json['class_id'],
    title:          json['title'],
    status:         SessionStatus.values.byName(json['status']),
    livekitRoomId:  json['livekit_room_id'],
    startTime:      json['start_time'] != null
                      ? DateTime.parse(json['start_time']) : null,
    endTime:        json['end_time'] != null
                      ? DateTime.parse(json['end_time']) : null,
  );
}
```

### `message_model.dart`
```dart
class MessageModel {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id:          json['id'],
    sessionId:   json['session_id'],
    senderId:    json['sender_id'],
    senderName:  json['sender_name'] ?? 'Unknown',
    content:     json['content'],
    timestamp:   DateTime.parse(json['timestamp']),
  );
}
```

---

## 4. Provider Patterns

### `session_provider.dart`
```dart
import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../data/session_repository.dart';

enum SessionLoadState { idle, loading, success, error }

class SessionProvider extends ChangeNotifier {
  final SessionRepository _repo;
  SessionProvider(this._repo);

  List<SessionModel> sessions = [];
  SessionLoadState  loadState = SessionLoadState.idle;
  String?           errorMessage;

  Future<void> fetchSessions(String classId) async {
    loadState = SessionLoadState.loading;
    notifyListeners();
    try {
      sessions  = await _repo.getSessionsByClass(classId);
      loadState = SessionLoadState.success;
    } catch (e) {
      errorMessage = e.toString();
      loadState    = SessionLoadState.error;
    }
    notifyListeners();
  }

  Future<SessionModel?> createSession(String classId, String title) async {
    try {
      final session = await _repo.createSession(classId, title);
      sessions = [session, ...sessions];
      notifyListeners();
      return session;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> startSession(String sessionId) async {
    final updated = await _repo.startSession(sessionId);
    _updateLocal(updated);
  }

  Future<void> endSession(String sessionId) async {
    final updated = await _repo.endSession(sessionId);
    _updateLocal(updated);
  }

  void _updateLocal(SessionModel updated) {
    sessions = sessions.map((s) => s.id == updated.id ? updated : s).toList();
    notifyListeners();
  }
}
```

### `meeting_room_provider.dart`
```dart
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class MeetingRoomProvider extends ChangeNotifier {
  Room? room;
  bool isMicOn  = true;
  bool isCamOn  = true;
  bool isChatOpen         = false;
  bool isParticipantsOpen = false;
  List<Participant> participants = [];

  Future<void> connect(String url, String token) async {
    room = Room();
    room!.addListener(_onRoomUpdate);
    await room!.connect(url, token);
    await room!.localParticipant?.setCameraEnabled(true);
    await room!.localParticipant?.setMicrophoneEnabled(true);
    _syncParticipants();
  }

  void _onRoomUpdate() {
    _syncParticipants();
    notifyListeners();
  }

  void _syncParticipants() {
    participants = [
      if (room?.localParticipant != null) room!.localParticipant!,
      ...room?.remoteParticipants.values ?? [],
    ];
  }

  Future<void> toggleMic() async {
    isMicOn = !isMicOn;
    await room?.localParticipant?.setMicrophoneEnabled(isMicOn);
    notifyListeners();
  }

  Future<void> toggleCam() async {
    isCamOn = !isCamOn;
    await room?.localParticipant?.setCameraEnabled(isCamOn);
    notifyListeners();
  }

  void toggleChat() {
    isChatOpen = !isChatOpen;
    if (isChatOpen) isParticipantsOpen = false;
    notifyListeners();
  }

  void toggleParticipants() {
    isParticipantsOpen = !isParticipantsOpen;
    if (isParticipantsOpen) isChatOpen = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    room?.removeListener(_onRoomUpdate);
    await room?.disconnect();
    room = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
```

---

## 5. go_router Route Pattern

```dart
// Thêm vào router config hiện tại
GoRoute(
  path: '/class/:classId/sessions',
  name: 'session-list',
  builder: (context, state) => SessionListScreen(
    classId: state.pathParameters['classId']!,
  ),
  routes: [
    GoRoute(
      path: ':sessionId',
      name: 'session-detail',
      builder: (context, state) => SessionDetailScreen(
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),
    GoRoute(
      path: ':sessionId/room',
      name: 'meeting-room',
      builder: (context, state) => ChangeNotifierProvider(
        create: (_) => MeetingRoomProvider(),
        child: MeetingRoomScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
    ),
  ],
),
```

---

## 6. Meeting Room Layout

```
┌─────────────────────────────────────────────────────┐
│  TopBar: title, timer, participants count       [X] │  ← GlassCard
├──────────────────────────────────┬──────────────────┤
│                                  │                  │
│     ParticipantGrid              │  ChatPanel       │
│     (VideoTrackRenderer)         │  hoặc            │
│                                  │  ParticipantsPanel│
│                                  │  (slide in/out)  │
├──────────────────────────────────┴──────────────────┤
│  BottomToolbar: 🎤 📷 💬 👥 🖥️ [End Call]          │  ← GlassCard
└─────────────────────────────────────────────────────┘
```

### `participant_tile.dart` — 1 ô video
```dart
class ParticipantTile extends StatelessWidget {
  final Participant participant;

  const ParticipantTile({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    final videoTrack = participant.videoTrackPublications.values
        .where((p) => p.kind == TrackType.VIDEO)
        .firstOrNull?.track as VideoTrack?;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Video feed hoặc avatar nếu cam tắt
          if (videoTrack != null)
            VideoTrackRenderer(videoTrack)
          else
            _AvatarPlaceholder(name: participant.name ?? '?'),

          // Tên + mic status
          Positioned(
            bottom: 8, left: 8,
            child: _ParticipantLabel(participant: participant),
          ),
        ],
      ),
    );
  }
}
```

### `bottom_toolbar.dart` — Thanh điều khiển
```dart
// Dùng Consumer<MeetingRoomProvider> để lắng nghe state
Consumer<MeetingRoomProvider>(
  builder: (context, provider, _) => GlassCard(
    borderRadius: GlassTheme.panelRadius,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToolbarButton(
          icon: provider.isMicOn ? Icons.mic : Icons.mic_off,
          label: provider.isMicOn ? 'Mute' : 'Unmute',
          onTap: provider.toggleMic,
          isActive: provider.isMicOn,
        ),
        _ToolbarButton(
          icon: provider.isCamOn ? Icons.videocam : Icons.videocam_off,
          label: provider.isCamOn ? 'Stop Video' : 'Start Video',
          onTap: provider.toggleCam,
          isActive: provider.isCamOn,
        ),
        _ToolbarButton(
          icon: Icons.chat_bubble_outline,
          label: 'Chat',
          onTap: provider.toggleChat,
          isActive: provider.isChatOpen,
        ),
        _ToolbarButton(
          icon: Icons.people_outline,
          label: 'Participants',
          onTap: provider.toggleParticipants,
          isActive: provider.isParticipantsOpen,
        ),
        const SizedBox(width: 24),
        // End call — màu đỏ, nổi bật
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          icon: const Icon(Icons.call_end),
          label: const Text('End'),
          onPressed: () async {
            await provider.disconnect();
            context.go('/class/${classId}/sessions');
          },
        ),
      ],
    ),
  ),
)
```

---

## 7. Tips đặc thù cho học sinh khiếm thính

- **Video tile lớn hơn bình thường** — tăng kích thước `ParticipantTile`, ưu tiên không gian video hơn chat
- **Không auto-mute cam** — khởi tạo với `isCamOn = true` luôn
- **Highlight speaker bằng border** thay vì âm thanh:
  ```dart
  // Viền sáng khi participant đang nói (dùng isSpeaking)
  border: Border.all(
    color: participant.isSpeaking ? GlassTheme.accent : Colors.transparent,
    width: 2,
  )
  ```
- **Pin video** — cho phép click vào 1 tile để phóng to (teacher giảng bài)
- **Caption bar** — dành chỗ sẵn phía dưới video để hiển thị subtitle realtime sau này