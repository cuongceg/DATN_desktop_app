# CLAUDE.md — EduDeaf Desktop App

> File này là system prompt cho mọi coding agent làm việc trên dự án này.
> Đọc toàn bộ file trước khi viết bất kỳ dòng code nào.
> Sau đó đọc: `.agent/plans/CURRENT_TASK.md` và `.agent/skills/` liên quan.

---

## 1. Tổng quan dự án

**Tên ứng dụng:** EduDeaf (tên tạm, có thể thay đổi)

**Mô tả:** Ứng dụng học tập desktop dành cho học sinh khiếm thính, tương tự Microsoft Teams nhưng được thiết kế đặc biệt với khả năng Speech-to-Text (STT) realtime, hiển thị phụ đề tự động, và giao diện tối ưu cho người dùng không nghe được âm thanh.

**Đối tượng người dùng:**
- Học sinh khiếm thính (toàn phần hoặc một phần)
- Giáo viên giảng dạy lớp có học sinh khiếm thính
- Quản trị viên trường học

**Platform mục tiêu:**
- Windows 10/11 (primary)
- Ubuntu 22.04+ (secondary)

**Tech stack:**
- Flutter (stable channel, phiên bản mới nhất)
- Dart
- Platform: `flutter_windows`, `flutter_linux`
- State management: Provider
- Backend/realtime: NodeJS, ExpressJS and LiveKit
- STT: Whisper

---

## 2. Cấu trúc thư mục

```
edudeaf/
├── CLAUDE.md                    # file này
├── .agent/
│   ├── skills/
│   │   ├── flutter-ui.md
│   │   ├── stt-integration.md
│   │   ├── accessibility.md
│   │   └── realtime-sync.md
│   ├── plans/
│   │   ├── CURRENT_TASK.md
│   │   └── BACKLOG.md
│   └── memory/
│       ├── project-context.md
│       ├── decisions-log.md
│       └── errors-learned.md
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart               # MaterialApp root
│   │   └── router.dart            # GoRouter config
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_sizes.dart
│   │   ├── extensions/
│   │   ├── utils/
│   │   └── errors/
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── classroom/             # Phòng học realtime
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── stt/                   # Speech-to-Text engine
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── subtitle/              # Hiển thị phụ đề
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── messaging/             # Chat / tin nhắn
│   │   └── dashboard/
│   ├── shared/
│   │   ├── widgets/               # Widget dùng chung
│   │   └── services/
│   └── l10n/                      # Đa ngôn ngữ (vi, en)
├── windows/
├── linux/
├── test/
├── integration_test/
├── assets/
│   ├── fonts/
│   ├── icons/
│   └── sounds/                    # Cảnh báo rung/visual flash
├── docs/
│   ├── ARCHITECTURE.md
│   └── API_DOCS.md
└── pubspec.yaml
```

---

## 3. Lệnh thường dùng

```bash
# Chạy trên Windows
flutter run -d windows

# Chạy trên Linux
flutter run -d linux

# Build release Windows
flutter build windows --release

# Build release Linux
flutter build linux --release

# Chạy tất cả tests
flutter test

# Chạy integration test
flutter test integration_test/

# Phân tích code
flutter analyze

# Format code
dart format lib/ test/

# Generate code (nếu dùng freezed / riverpod generator)
dart run build_runner build --delete-conflicting-outputs

# Xem dependencies
flutter pub deps
```

---

## 4. Nguyên tắc bắt buộc — KHÔNG ĐƯỢC VI PHẠM

### 4.1 Accessibility (ưu tiên cao nhất)

- **MỌI widget tương tác** phải có `Semantics()` wrapper với `label` rõ ràng bằng tiếng Việt
- **Không bao giờ** truyền thông tin chỉ qua âm thanh — luôn có visual feedback kèm theo
- **Font size tối thiểu** là 16sp cho body text, 14sp cho caption. Không hardcode kích thước nhỏ hơn
- **Contrast ratio** tối thiểu 4.5:1 cho text thông thường, 3:1 cho text lớn (WCAG AA)
- **Phụ đề STT** phải hiển thị trong vòng 500ms sau khi có transcript
- **Visual alert** (flash, badge, animation) thay thế cho mọi âm thanh thông báo
- Hỗ trợ **keyboard navigation** hoàn chỉnh — người dùng không dùng chuột phải điều khiển được toàn bộ app

### 4.2 Kiến trúc code

- Tuân thủ **Feature-First** với Clean Architecture (data / domain / presentation) trong mỗi feature
- **Không** để business logic trong Widget — logic vào ViewModel / Controller / Notifier
- **Không** import chéo giữa các feature — dùng shared/ hoặc core/ làm cầu nối
- Mỗi file không quá **300 dòng** — nếu vượt, tách file
- **Không** hardcode string UI — dùng `AppLocalizations` từ `l10n/`

### 4.3 STT & Subtitle

- STT chạy trên **native plugin** riêng cho Windows (`windows/`) và Linux (`linux/`)
- **Không** gọi STT API trực tiếp từ UI layer — luôn qua `SttService` trong `features/stt/`
- Transcript từ STT phải được **buffer và smooth** trước khi hiển thị — tránh nhấp nháy
- Lưu **toàn bộ transcript** của buổi học vào local storage để học sinh xem lại
- Xử lý gracefully khi STT không có kết nối hoặc microphone bị lỗi — hiển thị thông báo rõ ràng

### 4.4 Platform (Windows & Linux)

- **Không dùng** plugin chỉ hỗ trợ mobile (camera trực tiếp, v.v.) — kiểm tra platform support trước khi thêm dependency
- Mọi đường dẫn file phải dùng `path.join()` từ package `path` — không hardcode `/` hay `\`
- Window size mặc định: **1280x720**, minimum: **960x600**
- Kiểm tra `Platform.isWindows` / `Platform.isLinux` khi cần code riêng cho từng platform

### 4.5 Code style

- Dùng **Dart 3.x** features: records, patterns, sealed classes khi phù hợp
- **Không** dùng `dynamic` hoặc `var` khi biết type — khai báo type rõ ràng
- Mọi public API (class, method, field) phải có **dartdoc comment** (`///`)
- Dùng `const` constructor bất cứ khi nào có thể
- Tên file: `snake_case.dart` — Tên class: `PascalCase` — Tên biến/method: `camelCase`
- **Không** để `TODO` hoặc `FIXME` trong code commit — ghi vào `.agent/plans/BACKLOG.md` thay thế

---

## 5. Dependency quan trọng

```yaml
# pubspec.yaml — các package cốt lõi
dependencies:
  flutter:
    sdk: flutter

  # Navigation
  go_router: ^14.x

  # State management
  provider: ^6.x

  # STT
  speech_to_text: ^6.x            # fallback cross-platform
  # + native plugin riêng cho Windows/Linux STT accuracy cao hơn

  # Local storage
  drift: ^2.x                     # SQLite ORM — lưu transcript, messages
  shared_preferences: ^2.x        # settings đơn giản

  # UI / Accessibility
  flutter_screenutil: ^5.x        # responsive layout
  google_fonts: ^6.x

  # Utilities
  freezed_annotation: ^2.x
  json_annotation: ^4.x
  path: ^1.x
  intl: ^0.19.x

dev_dependencies:
  build_runner: ^2.x
  freezed: ^2.x
  json_serializable: ^6.x
  flutter_test:
    sdk: flutter
  mocktail: ^1.x
```

---

## 6. Tính năng cốt lõi — hiểu trước khi code

### Classroom (Phòng học)

Tương tự Teams Meeting nhưng:
- Sidebar trái: danh sách học sinh + trạng thái (online/offline/hand raised)
- Vùng chính: video giáo viên + **Subtitle Panel** nổi bật chiếm 30% màn hình dưới
- Học sinh có thể **pin subtitle** để luôn hiển thị, điều chỉnh font size/màu
- **Visual hand raise**: animation nổi bật thay vì âm thanh beep

### STT Pipeline

```
Microphone (giáo viên)
    ↓
SttService (native plugin / speech_to_text)
    ↓
TranscriptBuffer (smooth, deduplicate)
    ↓
SubtitleDisplayService
    ↓
SubtitleWidget (realtime update, cuộn tự động)
    ↓
TranscriptRepository (lưu vào DB cho xem lại)
```

### Subtitle Display

- Font: lớn, dễ đọc, mặc định **18sp bold**, người dùng tùy chỉnh được
- Background: semi-transparent dark overlay với **high contrast** text
- Auto-scroll: cuộn xuống khi có text mới, dừng nếu người dùng scroll lên xem lại
- Highlight từ **hiện tại** đang được nói (nếu STT hỗ trợ word timing)

---

## 7. Quy trình làm việc với agent

1. **Đọc** `CURRENT_TASK.md` — hiểu task đang làm
2. **Đọc skill** liên quan trong `.agent/skills/`
3. **Đọc** `decisions-log.md` — tránh vi phạm quyết định đã có
4. **Đọc** `errors-learned.md` — tránh lặp lỗi cũ
5. Viết code theo nguyên tắc section 4
6. Sau khi xong: cập nhật `CURRENT_TASK.md` (đánh dấu done) và `errors-learned.md` nếu gặp vấn đề mới

---

## 8. Điều agent KHÔNG được tự ý làm

- **Không** thay đổi state management solution (Riverpod ↔ Bloc) nếu không có task rõ ràng
- **Không** thêm dependency mới vào `pubspec.yaml` mà không ghi lý do vào `decisions-log.md`
- **Không** xóa hoặc rename file có sẵn mà không hỏi confirm
- **Không** commit code có `flutter analyze` warnings chưa được fix
- **Không** tạo widget mới trong `lib/` mà không có test tương ứng trong `test/`
- **Không** thay đổi native code trong `windows/` hoặc `linux/` nếu không phải task liên quan đến platform

---

## 9. Thông tin liên hệ & tài nguyên

- Backend API docs: docs/api-docs.md
- Architecture diagram: Chưa cập nhật,sẽ cập nhật mới trong tương lai
- STT provider documentation: [ Whisper]
---
---

## 10. Stitch MCP — Design Source of Truth


### Công cụ đã kết nối

| Tool | Vai trò |
|------|---------|
| **Google Stitch** (qua MCP) | Nguồn sự thật cho mọi design token |
| **DESIGN.md** (root project) | Bản snapshot của Stitch Design DNA, đồng bộ vào Flutter |
| `lib/core/constants/` | Flutter implementation của DESIGN.md |

### Nguyên tắc bất biến

- **KHÔNG hardcode** bất kỳ giá trị màu, font, spacing nào — luôn dùng `AppColors`, `AppTextStyles`, `AppSizes`
- **Trước khi refactor UI** bất kỳ screen nào: pull Design DNA từ Stitch, đọc `.agent/skills/ui-refactor.md`
- **DESIGN.md là nguồn sự thật** — nếu giá trị trong code khác DESIGN.md, code là sai
- Agent được phép fetch Stitch data tự động khi làm UI task, **không cần hỏi confirm**

### Khi nào dùng Stitch MCP

```
✅ Bắt đầu refactor bất kỳ screen/widget nào
✅ Tạo widget mới cần design token
✅ Có sai lệch visual giữa app và design
✅ Cần thêm component mới chưa có trong constants

❌ Khi đang làm logic/business layer (domain, data)
❌ Khi đang viết test
❌ Khi Stitch không phản hồi — dùng DESIGN.md làm fallback
```

### Skill liên quan

Đọc `.agent/skills/ui-refactor.md` cho toàn bộ workflow chi tiết,
bao gồm prompt mẫu, checklist, và cách map Design DNA sang Flutter constants.

*Cập nhật lần cuối: 26/04/2026 | Người maintain: Domanhcuong*