# BACKLOG.md

> Toàn bộ task của dự án EduDeaf.
>
> **Luồng:** `Icebox` → `Planned` → `Up Next` → `CURRENT_TASK.md` → `Completed`
>
> ⚠️ **Chỉ người dùng mới được chuyển task vào CURRENT_TASK.md.**
> Agent không tự ý quyết định task tiếp theo.

---

## 📊 Snapshot tiến độ

| Trạng thái | Số task |
|------------|---------|
| 🔄 In Progress | 1 (REFACTOR-001) |
| 🔴 Up Next | 3 |
| 🟡 Planned | 5 |
| 🧊 Icebox | 4 |
| ✅ Completed | 0 |
| **Tổng** | **13** |

---

## 🔴 Up Next — sẵn sàng làm ngay sau task hiện tại

### [REFACTOR-002] Tách feature `classroom` ra khỏi UI

**Ưu tiên:** Cao
**Ước tính:** 4–5 giờ
**Phụ thuộc:** REFACTOR-001 phải xong (cần UserEntity từ auth)

**Hiện trạng cần fix:**
- WebSocket / realtime logic đang nằm trong `classroom_screen.dart`
- Danh sách học sinh được fetch và render trong cùng 1 widget
- STT trigger đang gọi trực tiếp từ UI

**Target:**
```
features/classroom/
  data/datasources/classroom_realtime_datasource.dart  ← WebSocket
  data/repositories/classroom_repository_impl.dart
  domain/entities/classroom_entity.dart
  domain/entities/student_entity.dart
  domain/usecases/join_classroom_usecase.dart
  domain/usecases/get_students_usecase.dart
  presentation/controllers/classroom_notifier.dart
  presentation/screens/classroom_screen.dart          ← chỉ còn UI
  presentation/widgets/student_list_widget.dart
  presentation/widgets/subtitle_overlay_widget.dart
  presentation/widgets/hand_raise_button_widget.dart
```

---

### [REFACTOR-003] Tách feature `dashboard` ra khỏi UI

**Ưu tiên:** Cao
**Ước tính:** 2–3 giờ
**Phụ thuộc:** REFACTOR-001

**Hiện trạng cần fix:**
- Fetch danh sách lớp học đang ở trong widget
- Navigation vào classroom hardcode trong dashboard screen

**Target:** Clean Architecture tương tự auth, tách `DashboardNotifier` + `GetClassroomsUseCase`

---

### [CORE-001] Tập trung design system — xóa hardcode màu/size

**Ưu tiên:** Trung bình
**Ước tính:** 2–3 giờ
**Phụ thuộc:** Không (có thể làm song song sau REFACTOR-001)

**Hiện trạng cần fix:**
- Màu sắc hardcode `Color(0xFF...)` rải rác khắp nơi
- Font size hardcode `fontSize: 14` không nhất quán
- Spacing dùng `SizedBox(height: 8)` không theo hệ thống

**Target:**
```
core/constants/app_colors.dart       ← tất cả màu về đây
core/constants/app_text_styles.dart  ← tất cả text style về đây
core/constants/app_sizes.dart        ← spacing, radius, icon size
```

---

## 🟡 Planned — đã lên kế hoạch, chờ Up Next trống

### [CORE-002] Tập trung navigation với GoRouter

**Ưu tiên:** Trung bình
**Ước tính:** 2 giờ
**Phụ thuộc:** REFACTOR-001, 002, 003 xong

**Mô tả:**
`Navigator.push()` đang rải rác trong các screen. Tập trung về `app/router.dart` với GoRouter, thêm auth guard (redirect về login nếu chưa đăng nhập).

---

### [REFACTOR-004] Tách STT thành feature độc lập

**Ưu tiên:** Cao
**Ước tính:** 5–6 giờ
**Phụ thuộc:** REFACTOR-002 (classroom)

**Mô tả:**
STT hiện đang gắn chặt vào classroom. Tách thành `SttService` với interface riêng để dễ swap provider sau này (Azure / Google Cloud / Whisper local).

**Pipeline cần xây:**
```
Microphone → SttService → TranscriptBuffer → Stream<String> → SubtitleWidget
                                           → TranscriptRepository (lưu DB)
```

---

### [REFACTOR-005] Tách Subtitle thành widget độc lập

**Ưu tiên:** Cao
**Ước tính:** 2–3 giờ
**Phụ thuộc:** REFACTOR-004 (STT service)

**Mô tả:**
`SubtitleOverlayWidget` cần nhận `Stream<String>` làm input, tự quản lý scroll, cho phép user chỉnh font size và màu nền.

---

### [IMPROVE-001] Viết unit test cho domain layer

**Ưu tiên:** Trung bình
**Ước tính:** 1–2 giờ/feature × 5 feature
**Phụ thuộc:** Tất cả REFACTOR xong

**Target:** 80% coverage cho tất cả usecase + repository impl

---

### [IMPROVE-002] Audit accessibility toàn bộ UI

**Ưu tiên:** Cao — đây là app cho học sinh khiếm thính
**Ước tính:** 3–4 giờ
**Phụ thuộc:** Tất cả REFACTOR xong (UI ổn định)

**Checklist:**
- Tất cả IconButton có `tooltip`
- Tất cả tương tác quan trọng có visual feedback (không chỉ sound)
- Font size tối thiểu 16sp body, 18sp subtitle STT
- Contrast ratio đạt WCAG AA (4.5:1)
- Keyboard navigation hoạt động toàn bộ app

---

## 🧊 Icebox — ý tưởng, chưa commit làm

### [IDEA-001] Export transcript buổi học thành PDF

Học sinh tải về toàn bộ nội dung phụ đề sau buổi học.

### [IDEA-002] Offline mode cho STT

Dùng Whisper local khi không có internet — quan trọng cho trường vùng sâu.

### [IDEA-003] Teacher analytics dashboard

Thống kê học sinh giơ tay nhiều nhất, thời gian tham gia, v.v.

### [IDEA-004] Custom từ điển STT

Giáo viên thêm từ chuyên ngành để STT nhận diện chính xác hơn.

---

## ✅ Completed

> Task xong được move vào đây. Format: `[ID] Tên — ✅ Xong ngày [ngày]`

*(chưa có task nào hoàn thành)*

---

## Cách thêm task mới

```markdown
### [LOẠI-XXX] Tên task

**Ưu tiên:** Cao / Trung bình / Thấp
**Ước tính:** X giờ
**Phụ thuộc:** Task nào phải xong trước / Không

**Hiện trạng cần fix:**
- Mô tả vấn đề cụ thể hiện tại

**Target:**
- Kết quả mong đợi sau khi xong
```

**Prefix loại task:**
- `REFACTOR-` → dọn dẹp code hiện có
- `FEATURE-` → tính năng hoàn toàn mới
- `CORE-` → infrastructure, shared, design system
- `IMPROVE-` → chất lượng (test, a11y, performance)
- `BUG-` → sửa lỗi
- `IDEA-` → ý tưởng chưa xác nhận