# CURRENT_TASKS_FLUTTER.md — Flutter Desktop UI: Session Feature

> Cập nhật lần cuối: 2026-05-05
> Stack: Flutter Desktop · Provider · Glassmorphism (dark + light)
> Trạng thái: 🚧 Đang kết nối API

---

## ✅ Đã hoàn thành

- [x] Login / Register screen
- [x] Dashboard / Home screen
- [x] Class list screen
- [x] Class detail screen
- [x] GlassCard widget + theme tokens (dark + light)
- [x] TASK-UI-01 — Cài đặt package LiveKit
- [x] TASK-UI-02 — Data layer (`session_api.dart`, `session_repository.dart`)
- [x] TASK-UI-03 — Models (`session_model.dart`, `message_model.dart`)
- [x] TASK-UI-04 — Providers (`session_provider.dart`, `meeting_room_provider.dart`)
- [x] TASK-UI-05 — Session List Screen
- [x] TASK-UI-06 — Session Detail Screen
- [x] TASK-UI-07 — Meeting Room Screen (UI layout)
- [x] TASK-UI-08 — Participant Grid & Tile
- [x] TASK-UI-09 — Bottom Toolbar
- [x] TASK-UI-10 — Chat Panel
- [x] TASK-UI-11 — Participants Panel
- [x] TASK-UI-13 — Register Providers
- [x] TASK-UI-15 — Kết nối Meet Now với API thật (`SessionProvider.joinSession`, `MeetingRoomScreen` params thật)
- [x] TASK-UI-16 — Dropdown "Meet now" vs "Tạo cuộc họp sau" (`PopupMenuButton` + schedule dialog)

> ~~TASK-UI-12 — go_router Integration~~ — **Bỏ qua** (dự án không dùng go_router)

---

## 🎯 Sprint hiện tại: Kết nối API thật

---

### TASK-UI-15 — Kết nối Meet Now với API thật

**File:** `lib/screens/teams_channel_screen.dart`

**Vấn đề hiện tại:** Nút "Meet now" đang hardcode `sessionId: 'instant-meeting'`
và truyền `wss://mock-url` / `mock-token` vào `MeetingRoomProvider.connect()`.

**Việc cần làm:**

- [ ] Inject `SessionProvider` và `AuthProvider` vào `TeamsChannelScreen`
  - Cần lấy `classId` từ context hiện tại (team đang được chọn → map sang `classId`)
  - Cần lấy `userRole` để phân nhánh xử lý teacher vs student

- [ ] Thay nút "Meet now" hiện tại bằng logic sau:

  ```dart
  // Trong _buildAppBar() — thay onPressed của OutlinedButton.icon "Meet now"
  onPressed: () => _handleMeetNow(context),
  ```

  ```dart
  Future<void> _handleMeetNow(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    final classId = _getCurrentClassId(); // map _selectedTeam → classId

    // Bước 1: Tạo session mới — POST /api/sessions
    final session = await sessionProvider.createSession(classId, 'Buổi học nhanh');
    if (session == null) return;

    // Bước 2: Start session — PATCH /api/sessions/:id/start
    await sessionProvider.startSession(session.id);

    // Bước 3: Lấy token — POST /api/sessions/:id/token
    final joinData = await sessionProvider.joinSession(session.id);
    if (joinData == null || !context.mounted) return;

    // Bước 4: Navigate vào MeetingRoomScreen với token thật
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MeetingRoomProvider(),
          child: MeetingRoomScreen(
            sessionId: session.id,
            livekitUrl: joinData['livekit_url'],
            token: joinData['token'],
          ),
        ),
      ),
    );
  }
  ```

- [ ] Thêm loading indicator khi đang gọi API (disable nút, hiện spinner)
- [ ] Xử lý lỗi: hiện `SnackBar` nếu tạo session thất bại

---

### TASK-UI-16 — Dropdown "Meet now" vs "Tạo cuộc họp sau"

**File:** `lib/screens/teams_channel_screen.dart`

**Mục tiêu:** Tách nút "Meet now" thành dropdown 2 lựa chọn (giống Microsoft Teams).

- [ ] Thay `OutlinedButton.icon` + `Icon(Icons.keyboard_arrow_down)` riêng lẻ
  hiện tại bằng 1 `PopupMenuButton` duy nhất:

  ```dart
  PopupMenuButton<String>(
    offset: const Offset(0, 40),
    onSelected: (value) {
      if (value == 'now') _handleMeetNow(context);
      if (value == 'schedule') _handleScheduleMeeting(context);
    },
    itemBuilder: (_) => [
      const PopupMenuItem(
        value: 'now',
        child: ListTile(
          leading: Icon(Icons.videocam_outlined),
          title: Text('Meet now'),
          subtitle: Text('Bắt đầu ngay lập tức'),
        ),
      ),
      const PopupMenuItem(
        value: 'schedule',
        child: ListTile(
          leading: Icon(Icons.calendar_today_outlined),
          title: Text('Tạo cuộc họp sau'),
          subtitle: Text('Đặt lịch buổi học'),
        ),
      ),
    ],
    child: OutlinedButton.icon(
      onPressed: null, // PopupMenuButton tự handle tap
      icon: const Icon(Icons.videocam_outlined, size: 20),
      label: const Row(children: [
        Text('Meet now'),
        SizedBox(width: 4),
        Icon(Icons.keyboard_arrow_down, size: 16),
      ]),
    ),
  )
  ```

- [ ] Implement `_handleScheduleMeeting(context)`:
  - Hiện `showDialog` với form nhập `title` + `DateTimePicker` cho `scheduledAt`
  - Gọi `POST /api/sessions` với `scheduledAt` — **không** start ngay
  - Hiện `SnackBar` xác nhận: "Đã lên lịch buổi học lúc HH:mm dd/MM"
  - **Không** navigate vào room (chỉ tạo, chưa start)

> Giao diện form "Tạo cuộc họp sau" sẽ implement chi tiết sau (xem TASK-UI-20)

---

### TASK-UI-17 — Kết nối `MeetingRoomScreen` với token thật

**File:** `lib/features/session/screens/meeting_room_screen.dart`

**Vấn đề hiện tại:** `_connectToRoom()` đang dùng `'wss://mock-url'` và `'mock-token'`.

- [ ] Thêm 2 tham số bắt buộc vào constructor:

  ```dart
  class MeetingRoomScreen extends StatefulWidget {
    final String sessionId;
    final String livekitUrl;  // ← THÊM MỚI
    final String token;       // ← THÊM MỚI

    const MeetingRoomScreen({
      super.key,
      required this.sessionId,
      required this.livekitUrl,
      required this.token,
    });
  }
  ```

- [ ] Cập nhật `_connectToRoom()` — bỏ hardcode, dùng tham số thật:

  ```dart
  Future<void> _connectToRoom() async {
    try {
      // Bỏ Future.delayed mock
      await context.read<MeetingRoomProvider>().connect(
        widget.livekitUrl,  // wss://dev-monitor.id.vn
        widget.token,       // JWT từ POST /sessions/:id/token
      );
      if (mounted) setState(() => _isConnecting = false);
    } catch (e) {
      if (mounted) setState(() {
        _isConnecting = false;
        _error = e.toString();
      });
    }
  }
  ```

- [ ] Cập nhật `TopBar` — hiển thị title session thật thay vì hardcode `'Phòng học trực tuyến'`:
  - Truyền thêm `sessionTitle` vào `MeetingRoomScreen` hoặc fetch từ `SessionProvider`

---

### TASK-UI-18 — Kết nối `SessionProvider.joinSession()` trả về token

**File:** `lib/features/session/providers/session_provider.dart`

**Mục tiêu:** Đảm bảo `joinSession()` gọi đúng
`POST /api/sessions/:sessionId/token` và trả về `{ token, livekit_url, room_name }`.

- [ ] Kiểm tra `session_api.dart` — `joinSession(sessionId)` đang gọi đúng endpoint chưa:
  ```dart
  // Đúng:
  POST /api/sessions/$sessionId/token
  // Response theo api-docs:
  { "token": "...", "livekit_url": "wss://...", "room_name": "uuid" }
  ```

- [ ] Kiểm tra error handling — api-docs định nghĩa các lỗi cần handle:
  - `400 "Session has not started yet."` → hiện thông báo "Buổi học chưa bắt đầu"
  - `400 "Session has already ended."` → hiện thông báo "Buổi học đã kết thúc"
  - `403 "You are not a member of this class."` → hiện thông báo "Bạn không thuộc lớp này"

- [ ] Thêm method `joinSession(sessionId)` vào `SessionProvider` nếu chưa có:
  ```dart
  Future<Map<String, dynamic>?> joinSession(String sessionId) async {
    try {
      return await _repo.joinSession(sessionId);
      // trả về { 'token': '...', 'livekit_url': '...', 'room_name': '...' }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
  ```

---

### TASK-UI-19 — End session gọi API thật

**File:** `lib/features/session/screens/widgets/bottom_toolbar.dart`

**Vấn đề hiện tại:** Nút "End Call" chỉ đang `disconnect()` khỏi LiveKit,
chưa gọi `PATCH /api/sessions/:id/end` về backend.

- [ ] Cập nhật confirm dialog "End Call":
  - Teacher → hiện 2 lựa chọn: **"Rời phòng"** (chỉ disconnect) vs **"Kết thúc buổi học"** (end + disconnect)
  - Student → chỉ có **"Rời phòng"**

- [ ] Khi teacher chọn "Kết thúc buổi học":
  ```dart
  // 1. Gọi PATCH /api/sessions/:sessionId/end
  await context.read<SessionProvider>().endSession(sessionId);
  // 2. Disconnect khỏi LiveKit
  await context.read<MeetingRoomProvider>().disconnect();
  // 3. Navigate về màn hình trước
  Navigator.of(context).pop();
  ```

- [ ] `BottomToolbar` cần nhận thêm `sessionId` và `isTeacher` làm tham số

---

### TASK-UI-20 — Map `_selectedTeam` → `classId`

**File:** `lib/screens/teams_channel_screen.dart`

**Vấn đề:** `_selectedTeam` hiện là `String` tên lớp,
nhưng API cần `classId` (UUID) để tạo session.

- [ ] Thay `List<String> _teams` bằng `List<ClassModel> _classes`
  - Lấy từ `ClassProvider` hoặc truyền vào qua constructor
- [ ] Thay `String _selectedTeam` bằng `ClassModel? _selectedClass`
- [ ] `_getCurrentClassId()` chỉ cần return `_selectedClass?.id`
- [ ] Cập nhật sidebar: hiển thị `class.name` thay vì raw string

---

## 🧪 TASK-UI-21 — Testing flow đầu cuối

- [ ] **Flow Teacher — Meet now:**
  1. Chọn lớp trong sidebar
  2. Click "Meet now" → dropdown → chọn "Meet now"
  3. Spinner hiện trong lúc gọi 3 API (create → start → token)
  4. Navigate vào `MeetingRoomScreen` với token thật
  5. Cam + mic bật, `TopBar` hiện đúng tên session
  6. Click "Kết thúc buổi học" → confirm dialog → `endSession` + disconnect → về màn hình trước

- [ ] **Flow Teacher — Lên lịch:**
  1. Click "Meet now" → chọn "Tạo cuộc họp sau"
  2. Dialog nhập title + chọn ngày giờ
  3. Gọi `POST /api/sessions` với `scheduledAt`
  4. SnackBar xác nhận, không vào room

- [ ] **Flow Student — Tham gia:**
  1. Vào Session List → thấy session `ongoing`
  2. Click "Tham gia" → gọi `POST /sessions/:id/token`
  3. Navigate vào `MeetingRoomScreen` với token student
  4. Thấy video của teacher + các student khác
  5. Click "Rời phòng" → chỉ disconnect, session vẫn `ongoing`

- [ ] **Test lỗi:**
  - Join session chưa start → SnackBar "Buổi học chưa bắt đầu"
  - Join session đã end → SnackBar "Buổi học đã kết thúc"
  - Mất mạng khi đang trong room → hiện reconnecting indicator

---

## 📋 Backlog (làm sau)

### TASK-UI-22 — Form "Tạo cuộc họp sau" chi tiết
- [ ] `DateTimePicker` chọn ngày giờ
- [ ] Hiển thị session đã lên lịch trong Session List với countdown timer

### TASK-UI-23 — Screen Share
- [ ] Nút share screen trong toolbar
- [ ] Hiển thị screen share track trong grid (ưu tiên pin)

### TASK-UI-24 — Caption Bar
- [ ] Vùng cố định dưới video hiển thị subtitle
- [ ] Nhận text từ LiveKit Data Channel

### TASK-UI-25 — Notification khi session bắt đầu
- [ ] Toast/desktop notification khi teacher start session

---

## 📝 Ghi chú kỹ thuật

| Vấn đề | Vị trí | Ghi chú |
|---|---|---|
| `sessionId: 'instant-meeting'` hardcode | `teams_channel_screen.dart` L~60 | Sửa ở TASK-UI-15 |
| `'wss://mock-url'`, `'mock-token'` | `meeting_room_screen.dart` L~21 | Sửa ở TASK-UI-17 |
| `_selectedTeam` là String, không có classId | `teams_channel_screen.dart` | Sửa ở TASK-UI-20 |
| End Call chưa gọi API end session | `bottom_toolbar.dart` | Sửa ở TASK-UI-19 |

- LiveKit server: `wss://dev-monitor.id.vn`
- Thứ tự làm: **TASK-UI-20 → TASK-UI-18 → TASK-UI-17 → TASK-UI-15 → TASK-UI-16 → TASK-UI-19 → TASK-UI-21**
- `MeetingRoomProvider` không được đặt global — provide cục bộ tại mỗi `MaterialPageRoute`
- Không auto-mute cam khi vào phòng (học sinh khiếm thính)