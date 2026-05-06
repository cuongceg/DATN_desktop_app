# SKILL.md — Session Scheduling Feature

## Mục đích

Skill này hướng dẫn implement chức năng **lên lịch buổi học (session scheduling)** trong ứng dụng desktop Flutter + Node.js/Express + PostgreSQL. Đọc file này trước khi viết bất kỳ code nào liên quan đến sessions/calendar.

---

## 1. Architecture Overview

```
Flutter Desktop (Provider)
    └── SessionProvider
          ├── SessionService  ──→  Express API  ──→  PostgreSQL
          └── SessionModel               ↑
                                    sessions table
                                    (có cột scheduled_at)

CalendarDesktopScreen
    └── SfCalendar (syncfusion)
          └── SessionDataSource (CalendarDataSource)
```

---

## 2. Database

### Bảng `sessions` — schema đầy đủ sau migration

```sql
CREATE TABLE sessions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id         UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  livekit_room_id  VARCHAR(255),
  title            VARCHAR(255) NOT NULL,
  scheduled_at     TIMESTAMPTZ,        -- ← cột mới, thêm bằng migration
  start_time       TIMESTAMPTZ,
  end_time         TIMESTAMPTZ,
  status           session_status NOT NULL DEFAULT 'scheduled',
  CONSTRAINT chk_sessions_time
    CHECK (end_time IS NULL OR start_time IS NULL OR end_time >= start_time)
);
```

**Quy tắc:**
- `scheduled_at`: thời gian dự kiến, do teacher đặt khi tạo lịch.
- `start_time`: thời gian thực tế khi session được start (set bởi `PATCH /start`).
- Calendar hiển thị theo `scheduled_at`. Nếu null fallback về `start_time`.

---

## 3. API Endpoints (Sessions)

### Endpoints hiện có (giữ nguyên, cập nhật nhỏ)

| Method | Path | Role | Ghi chú |
|--------|------|------|---------|
| POST | `/api/sessions` | teacher | Thêm `scheduled_at` vào body và response |
| GET | `/api/sessions/class/:classId` | all | Thêm `scheduled_at` vào response |
| GET | `/api/sessions/:sessionId` | all | Thêm `scheduled_at` vào response |
| PATCH | `/api/sessions/:sessionId/start` | teacher | Không thay đổi |
| PATCH | `/api/sessions/:sessionId/end` | teacher | Không thay đổi |

### Endpoints mới cần thêm

| Method | Path | Role | Ghi chú |
|--------|------|------|---------|
| GET | `/api/sessions/my` | all | Query `?from=&to=` — cho calendar view |
| PATCH | `/api/sessions/:sessionId` | teacher | Update title/scheduledAt |
| DELETE | `/api/sessions/:sessionId` | teacher | Chỉ status `scheduled` |

### Body schemas

**POST/PATCH session:**
```json
{
  "classId": "uuid",        // chỉ bắt buộc khi POST
  "title": "string",
  "scheduledAt": "ISO8601"  // optional
}
```

**GET /api/sessions/my response:**
```json
{
  "sessions": [{
    "id": "uuid",
    "class_id": "uuid",
    "class_name": "string",   // JOIN từ classes
    "title": "string",
    "scheduled_at": "ISO8601 | null",
    "start_time": "ISO8601 | null",
    "end_time": "ISO8601 | null",
    "status": "scheduled | ongoing | completed"
  }]
}
```

---

## 4. Flutter — Conventions

### 4.1 SessionModel

```dart
// lib/features/sessions/models/session_model.dart

class SessionModel {
  final String id;
  final String classId;
  final String className;
  final String title;
  final DateTime? scheduledAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;

  // Helper getters
  bool get isScheduled => status == 'scheduled';
  bool get isOngoing   => status == 'ongoing';
  bool get isCompleted => status == 'completed';
  bool get isEditable  => isScheduled;

  // Effective display time: scheduled_at ?? start_time
  DateTime? get displayTime => scheduledAt ?? startTime;

  factory SessionModel.fromJson(Map<String, dynamic> json) { ... }
  SessionModel copyWith({ ... }) { ... }
}
```

### 4.2 SessionService

```dart
// lib/features/sessions/services/session_service.dart

class SessionService {
  final String _baseUrl;
  final String _token;

  // Luôn attach header:
  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  Future<List<SessionModel>> fetchMySessionsInRange(DateTime from, DateTime to);
  Future<SessionModel> createSession({
    required String classId,
    required String title,
    DateTime? scheduledAt,
  });
  Future<SessionModel> updateSession({
    required String sessionId,
    String? title,
    DateTime? scheduledAt,
  });
  Future<void> deleteSession(String sessionId);
}
```

### 4.3 SessionProvider

```dart
// lib/features/sessions/providers/session_provider.dart

class SessionProvider extends ChangeNotifier {
  final SessionService _service;

  List<SessionModel> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Gọi khi calendar range thay đổi
  Future<void> loadSessionsForRange(DateTime from, DateTime to) async {
    _isLoading = true;
    notifyListeners();
    try {
      _sessions = await _service.fetchMySessionsInRange(from, to);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sau khi create/update/delete → gọi lại loadSessionsForRange
}
```

### 4.4 SessionDataSource (Syncfusion)

```dart
// lib/features/sessions/widgets/session_data_source.dart

class SessionDataSource extends CalendarDataSource {
  final List<SessionModel> sessions;

  SessionDataSource(this.sessions) {
    appointments = sessions
      .where((s) => s.displayTime != null)
      .map((s) => Appointment(
        startTime: s.displayTime!,
        endTime: s.displayTime!.add(const Duration(hours: 1)),
        subject: s.title,
        notes: s.className,
        color: _statusColor(s.status, context),
        id: s.id,                  // dùng để lookup lại SessionModel khi tap
      ))
      .toList();
  }
}
```

**Color scheme cho status:**
| Status | Color |
|--------|-------|
| `scheduled` | `colorScheme.primary` |
| `ongoing` | `colorScheme.secondary` |
| `completed` | `colorScheme.outline` |

### 4.5 Tích hợp vào CalendarDesktopScreen

```dart
// Trong _CalendarDesktopScreenState

@override
void initState() {
  super.initState();
  _calendarController.displayDate = _focusedDate;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadSessionsForCurrentView();
  });
}

void _loadSessionsForCurrentView() {
  final monday = _focusedDate.subtract(
    Duration(days: _focusedDate.weekday - 1),
  );
  final friday = monday.add(const Duration(days: 4));
  context.read<SessionProvider>().loadSessionsForRange(monday, friday);
}

// Trong MainCalendarGrid — thêm dataSource và onTap:
SfCalendar(
  ...
  dataSource: SessionDataSource(
    context.watch<SessionProvider>().sessions,
  ),
  onTap: (CalendarTapDetails details) {
    if (details.appointments?.isNotEmpty == true) {
      final sessionId = details.appointments!.first.id as String;
      final session = context.read<SessionProvider>()
        .sessions.firstWhere((s) => s.id == sessionId);
      _showSessionDetail(context, session);
    } else if (details.targetElement == CalendarElement.calendarCell) {
      final role = context.read<AuthProvider>().user?.role;
      if (role == 'teacher') {
        _showCreateDialog(context, prefilledDate: details.date);
      }
    }
  },
)
```

---

## 5. Glassmorphism UI — Conventions

Tuân theo style glassmorphism đã có trong `core/`:

```dart
// Pattern chuẩn cho dialog/popup
Container(
  decoration: BoxDecoration(
    color: scheme.surfaceContainerHighest.withOpacity(0.6),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: scheme.outline.withOpacity(0.2),
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: /* content */,
    ),
  ),
)
```

- Dùng `showDialog` với `barrierColor: Colors.black.withOpacity(0.3)`.
- Tất cả form field dùng `filled: true`, `fillColor: scheme.surface.withOpacity(0.5)`.
- Buttons: `FilledButton` cho primary action, `TextButton` cho cancel.

---

## 6. Role-Based UI Rules

| UI Element | teacher | student |
|---|---|---|
| Nút "New" trên TopBar | ✅ Hiện | ❌ Ẩn |
| Tap vào empty cell | Mở CreateDialog | Không làm gì |
| Tap vào session chip | Mở DetailPopup (có Edit/Delete) | Mở DetailPopup (read-only + Join nếu ongoing) |
| Nút Edit trong popup | ✅ | ❌ |
| Nút Delete trong popup | ✅ (chỉ khi `scheduled`) | ❌ |
| Nút Join trong popup | ❌ | ✅ (chỉ khi `ongoing`) |

---

## 7. Error Handling Pattern

```dart
// Trong SessionProvider methods
try {
  final result = await _service.someMethod(...);
  // update state
} on SessionException catch (e) {
  _errorMessage = e.message;
} catch (e) {
  _errorMessage = 'Đã xảy ra lỗi. Vui lòng thử lại.';
} finally {
  _isLoading = false;
  notifyListeners();
}
```

Hiển thị lỗi trong UI:
```dart
// Trong consumer widget
if (provider.errorMessage != null)
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(provider.errorMessage!)),
  );
```

---

## 8. Checklist trước khi ship

- [ ] Migration `add_scheduled_at_to_sessions.sql` đã chạy trên DB.
- [ ] `GET /api/sessions/my` trả về `class_name` (JOIN với `classes`).
- [ ] `SessionProvider` đã được đăng ký trong `MultiProvider` ở `main.dart`.
- [ ] `SessionDataSource` không crash khi `sessions` list rỗng.
- [ ] Nút "New" ẩn với student role.
- [ ] Dialog đóng lại sau khi create/update/delete thành công.
- [ ] Sau mỗi CRUD operation, gọi lại `loadSessionsForRange` để refresh calendar.
- [ ] Test navigation qua nhiều tuần — data load đúng cho từng range.