# Skill: UI Refactor với Stitch MCP

> Dùng skill này khi refactor hoặc xây dựng bất kỳ UI widget/screen nào.
> Stitch là source of truth về design — KHÔNG tự đoán màu, font, spacing.

---

## Stitch MCP là gì trong workflow này

Stitch (stitch.withgoogle.com) là AI design canvas của Google Labs.
Khi kết nối qua MCP, Antigravity agent có thể:

- Fetch **Design DNA** (màu, font, spacing, component pattern) từ Stitch project
- Lấy HTML/CSS của từng screen làm reference
- So sánh implementation với design gốc để phát hiện sai lệch

**Nguyên tắc:** Mọi giá trị design (màu, font size, border radius, spacing) đều phải đến từ Stitch hoặc `DESIGN.md` — không hardcode, không tự đặt.

---

## Workflow bắt buộc trước khi viết bất kỳ dòng UI nào

### Bước 1 — Pull Design DNA từ Stitch

Trong Antigravity Agent chat, chạy lệnh:

```
List my Stitch projects
```

Sau khi xác định đúng project EduDeaf, lấy design context:

```
Extract the Design DNA from the [tên screen] screen in project [project ID]
```

Agent sẽ trả về một block JSON/CSS chứa:
```
colors:
  primary: #...
  surface: #...
  on-surface: #...
  subtitle-bg: #...      ← quan trọng cho màn hình phụ đề
  ...

typography:
  heading: { font, size, weight, lineHeight }
  body: { font, size, weight, lineHeight }
  subtitle-text: { font, size, weight }    ← cho STT overlay

spacing:
  xs: ...
  sm: ...
  md: ...
  lg: ...

radius:
  card: ...
  button: ...
  overlay: ...
```

### Bước 2 — Cập nhật DESIGN.md

Sau khi lấy được Design DNA, cập nhật file `DESIGN.md` ở root project:

```bash
# DESIGN.md là nguồn sự thật duy nhất cho mọi design token
# Mọi file Dart đều import từ đây (qua AppColors, AppTextStyles, AppSizes)
```

### Bước 3 — Sync vào Flutter constants

Map giá trị từ DESIGN.md vào 3 file constants của Flutter:

```
DESIGN.md → lib/core/constants/app_colors.dart
           → lib/core/constants/app_text_styles.dart
           → lib/core/constants/app_sizes.dart
```

### Bước 4 — Lấy screen code làm reference

```
Get the screen code for [tên screen] in project [project ID]
```

Dùng HTML/CSS output này làm **visual reference**, không copy sang Dart trực tiếp.
Mục đích: hiểu layout intent, spacing ratio, component hierarchy.

### Bước 5 — Viết/refactor Flutter widget

Chỉ sau khi có Design DNA và screen reference, mới bắt đầu viết code.

---

## Map Design Token → Flutter

### Màu sắc

```dart
// lib/core/constants/app_colors.dart
// CẬP NHẬT các giá trị này sau khi pull Design DNA từ Stitch

import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary palette — lấy từ Stitch Design DNA
  static const primary         = Color(0xFF______);  // ← điền từ Stitch
  static const primaryVariant  = Color(0xFF______);
  static const onPrimary       = Color(0xFF______);

  // Surface
  static const surface         = Color(0xFF______);
  static const surfaceVariant  = Color(0xFF______);
  static const onSurface       = Color(0xFF______);

  // Subtitle overlay — đặc biệt quan trọng cho học sinh khiếm thính
  static const subtitleBg      = Color(0xCC______);  // semi-transparent
  static const subtitleText    = Color(0xFF______);  // phải đạt contrast 4.5:1

  // Status
  static const error           = Color(0xFF______);
  static const success         = Color(0xFF______);
  static const warning         = Color(0xFF______);

  // Hand raise highlight — visual alert thay âm thanh
  static const handRaiseActive = Color(0xFF______);
}
```

### Typography

```dart
// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract class AppTextStyles {
  // Font family từ Stitch — đảm bảo add vào pubspec.yaml
  static const _fontFamily = '______';  // ← điền từ Stitch

  static const heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: ___,   // từ Stitch
    fontWeight: FontWeight.w___,
    color: AppColors.onSurface,
    height: _.__,    // line height ratio
  );

  static const heading2 = TextStyle( /* ... */ );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: ___,   // tối thiểu 16 — accessibility requirement
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static const caption = TextStyle(
    fontSize: ___,   // tối thiểu 14 — accessibility requirement
  );

  // Đặc biệt cho subtitle STT — học sinh đọc realtime, cần rõ ràng
  static const subtitleLive = TextStyle(
    fontFamily: _fontFamily,
    fontSize: ___,       // tối thiểu 18 — bắt buộc
    fontWeight: FontWeight.bold,
    color: AppColors.subtitleText,
    height: 1.4,         // line height thoáng hơn cho dễ đọc
    letterSpacing: 0.3,
  );
}
```

### Spacing & Sizes

```dart
// lib/core/constants/app_sizes.dart
abstract class AppSizes {
  // Spacing — lấy từ Stitch spacing scale
  static const double xs  = ___;  // ← điền từ Stitch (thường 4)
  static const double sm  = ___;  // thường 8
  static const double md  = ___;  // thường 16
  static const double lg  = ___;  // thường 24
  static const double xl  = ___;  // thường 32
  static const double xxl = ___;  // thường 48

  // Border radius
  static const double radiusCard    = ___;
  static const double radiusButton  = ___;
  static const double radiusOverlay = ___;  // cho subtitle panel

  // Icon sizes
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;

  // Subtitle overlay
  static const double subtitlePanelMinHeight = 120;
  static const double subtitleFontSizeDefault = 18;  // user có thể override
  static const double subtitleFontSizeMin = 16;
  static const double subtitleFontSizeMax = 28;
}
```

---

## Refactor widget hiện có — checklist Stitch-aware

```
□ 1. Pull Design DNA từ Stitch cho screen đang refactor
□ 2. Cập nhật DESIGN.md với giá trị mới (nếu thay đổi)
□ 3. Cập nhật app_colors.dart / app_text_styles.dart / app_sizes.dart
□ 4. Lấy screen HTML từ Stitch làm visual reference
□ 5. Refactor widget — thay tất cả hardcode bằng AppColors/AppTextStyles/AppSizes
□ 6. Kiểm tra contrast ratio của text (đặc biệt subtitle)
□ 7. So sánh với Stitch screenshot — có sai lệch rõ ràng không?
□ 8. Nếu sai lệch: prompt agent "Refer back to Stitch design and fix [element]"
□ 9. flutter analyze → 0 warning
□ 10. Chạy app, visual check trên Windows
```

---

## Những gì KHÔNG được làm khi có Stitch MCP

```dart
// ❌ Hardcode màu — nguồn sự thật là Stitch/DESIGN.md
Container(color: const Color(0xFF1A73E8))
Text('Hello', style: TextStyle(color: Colors.blue))

// ❌ Hardcode font size
Text('Hello', style: TextStyle(fontSize: 16))

// ❌ Hardcode spacing
SizedBox(height: 24)
Padding(padding: EdgeInsets.all(16))

// ✅ Dùng constants đồng bộ từ Stitch
Container(color: AppColors.primary)
Text('Hello', style: AppTextStyles.body)
SizedBox(height: AppSizes.md)
Padding(padding: EdgeInsets.all(AppSizes.md))
```

---

## Khi Stitch MCP không available (offline / lỗi kết nối)

1. Dùng giá trị từ `DESIGN.md` (đã sync trước đó) thay thế
2. Nếu `DESIGN.md` chưa có giá trị → dùng placeholder và đánh dấu `// TODO: sync from Stitch`
3. Ghi vào `memory/errors-learned.md`: Stitch MCP offline ngày [ngày], dùng fallback

---

## Ví dụ prompt hiệu quả trong Antigravity Agent

```
# Lấy design context
"Extract Design DNA from the Classroom screen in EduDeaf project"

# Refactor với context
"Refactor SubtitleOverlayWidget to match the Stitch design.
 Use the Design DNA you just fetched. Ensure subtitle font is at
 least 18sp, background has 80% opacity, and contrast ratio meets WCAG AA."

# Kiểm tra sai lệch
"Compare the current SubtitleOverlayWidget implementation with the
 Stitch design screenshot. List any visual discrepancies."

# Fix sai lệch
"The subtitle panel bottom margin is off. Refer back to Stitch spacing
 tokens and update AppSizes accordingly."
```