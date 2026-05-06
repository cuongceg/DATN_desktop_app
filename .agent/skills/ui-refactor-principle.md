# Skill: Coding & Refactoring

> Agent đọc file này trước khi viết hoặc refactor bất kỳ đoạn code nào.
> Dự án đang ở giai đoạn: **restructure codebase có sẵn** — Auth, Classroom, Dashboard đã chạy được.
> Ưu tiên: Tách module → Dọn UI → Đặt tên nhất quán → Viết test

---

## Nguyên tắc tối thượng khi refactor code đang chạy

> **"Make it work, THEN make it right."**
> Code đang chạy là tài sản. Refactor sai tay = mất tính năng.

### Quy tắc an toàn bắt buộc

1. **Đọc toàn bộ file trước khi sửa** — liệt kê: file làm gì, ai gọi nó, state nào nó giữ
2. **Không xóa code cũ ngay** — comment lại với `// REFACTOR: sẽ xóa sau khi [tên file mới] hoạt động`
3. **Chạy app sau mỗi bước nhỏ** — đừng refactor 5 file rồi mới chạy thử
4. **Một task = một feature** — không refactor Auth và Classroom trong cùng một lần
5. **Nếu không chắc** — hỏi, không đoán

---

## Cấu trúc target — sau khi refactor xong

```
lib/
├── main.dart
├── app/
│   ├── app.dart                    # MaterialApp / ProviderScope
│   └── router.dart                 # GoRouter — toàn bộ navigation tập trung đây
│
├── core/                           # Dùng chung, không thuộc feature nào
│   ├── constants/
│   │   ├── app_colors.dart         # Màu sắc — không hardcode hex ở nơi khác
│   │   ├── app_text_styles.dart    # Typography
│   │   └── app_sizes.dart          # Spacing, border radius, icon size
│   ├── extensions/                 # Extension methods tiện ích
│   ├── utils/                      # Helper functions thuần Dart
│   ├── errors/                     # AppException, Failure classes
│   └── widgets/                    # Widget UI dùng chung (LoadingIndicator, ErrorView...)
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── auth_remote_datasource.dart
    │   │   │   └── auth_local_datasource.dart   # token storage
    │   │   ├── models/
    │   │   │   └── user_model.dart              # JSON serializable
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user_entity.dart             # Pure Dart, không import Flutter
    │   │   ├── repositories/
    │   │   │   └── auth_repository.dart         # Abstract interface
    │   │   └── usecases/
    │   │       ├── sign_in_usecase.dart
    │   │       ├── sign_out_usecase.dart
    │   │       └── get_current_user_usecase.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── auth_notifier.dart
    │       ├── screens/
    │       │   └── login_screen.dart            # Chỉ còn UI + ref.watch()
    │       └── widgets/
    │           └── login_form_widget.dart
    │
    ├── classroom/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   ├── classroom_remote_datasource.dart
    │   │   │   └── classroom_realtime_datasource.dart  # WebSocket/realtime
    │   │   ├── models/
    │   │   │   ├── classroom_model.dart
    │   │   │   └── student_model.dart
    │   │   └── repositories/
    │   │       └── classroom_repository_impl.dart
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   ├── classroom_entity.dart
    │   │   │   └── student_entity.dart
    │   │   ├── repositories/
    │   │   │   └── classroom_repository.dart
    │   │   └── usecases/
    │   │       ├── get_classroom_usecase.dart
    │   │       ├── join_classroom_usecase.dart
    │   │       └── get_students_usecase.dart
    │   └── presentation/
    │       ├── controllers/
    │       │   └── classroom_notifier.dart
    │       ├── screens/
    │       │   └── classroom_screen.dart
    │       └── widgets/
    │           ├── student_list_widget.dart
    │           ├── hand_raise_button_widget.dart
    │           └── subtitle_overlay_widget.dart  # Hiển thị phụ đề STT
    │
    └── dashboard/
        ├── data/ ...
        ├── domain/ ...
        └── presentation/
            ├── controllers/
            │   └── dashboard_notifier.dart
            ├── screens/
            │   └── dashboard_screen.dart
            └── widgets/
                └── classroom_card_widget.dart
```

---

## Thứ tự refactor — làm tuần tự, không làm song song

```
Bước 1 ──▶ AUTH          (nền tảng, các feature khác phụ thuộc vào user/token)
Bước 2 ──▶ CLASSROOM     (feature chính, phức tạp nhất)
Bước 3 ──▶ DASHBOARD     (thường đơn giản, ít logic)
Bước 4 ──▶ CORE CLEANUP  (routing, design system, naming)
Bước 5 ──▶ TEST          (viết sau khi structure ổn định)
```

---

## Quy trình tách một file spaghetti → Clean Architecture

### Ví dụ: `login_screen.dart` đang làm quá nhiều

```dart
// ❌ Hiện trạng phổ biến — tất cả lẫn lộn trong 1 file
class LoginScreen extends StatefulWidget {
  // 300+ dòng với:
  // - TextEditingController
  // - Gọi http.post() trực tiếp
  // - Parse JSON response
  // - Lưu token vào SharedPreferences
  // - setState loading
  // - Navigator.push sau login
}
```

**Cách tách an toàn — từng bước nhỏ, chạy app sau mỗi bước:**

```
Bước 1: Tạo UserEntity (pure Dart)                → chạy app ✅
Bước 2: Tạo AuthRepository interface              → chạy app ✅
Bước 3: Tạo AuthRepositoryImpl (move API call)    → chạy app ✅
Bước 4: Tạo SignInUseCase                         → chạy app ✅
Bước 5: Tạo AuthNotifier (Riverpod)               → chạy app ✅
Bước 6: Refactor LoginScreen dùng AuthNotifier    → chạy app ✅
Bước 7: Xóa comment cũ                           → done ✅
```

---

## Quy tắc phân tầng import — vi phạm = refactor sai

| Tầng | ✅ Được import | ❌ KHÔNG được import |
|------|---------------|---------------------|
| `domain/entities` | Dart thuần | Flutter, http, data, presentation |
| `domain/repositories` | entities | Flutter, data, presentation |
| `domain/usecases` | entities + repository abstract | Flutter, data, presentation |
| `data/models` | entities, json_annotation | Flutter, domain/usecases, presentation |
| `data/repositories` | models, datasources, domain/repo | presentation |
| `presentation/controllers` | usecases, entities | data layer trực tiếp |
| `presentation/screens` | controllers, widgets, router | domain/data trực tiếp |

---

## Conventions đặt tên — áp dụng ngay khi tạo file mới

### Files — tất cả snake_case
```
✅ login_screen.dart
✅ auth_repository_impl.dart
✅ get_current_user_usecase.dart

❌ LoginScreen.dart
❌ AuthRepo.dart
❌ getUser.dart
```

### Classes — PascalCase với suffix rõ ràng
```dart
class User {}                                    // Entity — không suffix
class UserModel extends User {}                  // Model — suffix Model
abstract class AuthRepository {}                 // Repo interface — suffix Repository
class AuthRepositoryImpl implements AuthRepository {} // Impl — suffix RepositoryImpl
class SignInUseCase {}                           // UseCase — động từ + UseCase
class AuthNotifier extends AsyncNotifier<User?> {} // Notifier
class LoginScreen extends ConsumerWidget {}      // Screen — suffix Screen
class SubtitleOverlayWidget extends StatelessWidget {} // Widget tái sử dụng
class StudentAvatarTile extends StatelessWidget {}     // Tile = list item
```

---

## Dọn UI widget — những thứ KHÔNG được có trong Screen

```dart
// ❌ Phải chuyển ra ngoài
http.get(...)                         // → vào datasource
dio.post(...)                         // → vào datasource
SharedPreferences.getInstance()       // → vào local datasource
jsonDecode(response.body)             // → vào model.fromJson()
Navigator.push(context, ...)          // → vào router.dart (GoRouter)
setState(() { _isLoading = true; })   // → vào Notifier state

// ✅ Screen chỉ được có
ref.watch(someProvider)               // đọc state
ref.read(someProvider.notifier)       // trigger action
Widget build(BuildContext context)    // render UI
_buildSomePart() / SomeWidget()       // tách UI con
```

### Build method tối đa 50 dòng
```dart
// ❌
@override
Widget build(BuildContext context) {
  return Column(children: [ /* 150 dòng */ ]);
}

// ✅
@override
Widget build(BuildContext context) {
  return Column(children: [
    _buildTopBar(),
    _buildClassroomContent(),
    _buildSubtitlePanel(),
  ]);
}
```

---

## Lỗi Flutter phổ biến khi refactor — TRÁNH

```dart
// ❌ BuildContext qua async gap
onPressed: () async {
  await signIn();
  Navigator.of(context).pop(); // crash nếu widget đã unmount
}
// ✅
onPressed: () async {
  await signIn();
  if (!mounted) return;
  Navigator.of(context).pop();
}

// ❌ Nullable không guard
final user = ref.watch(userProvider); // User?
Text(user.name); // null crash
// ✅
final user = ref.watch(userProvider);
if (user == null) return const SizedBox.shrink();
Text(user.name);

// ❌ var / dynamic khi biết type
var data = response.data;
// ✅
final Map<String, dynamic> data = response.data;

// ❌ AsyncValue không handle đủ 3 case
ref.watch(classroomProvider).whenData((c) => ClassroomView(c)); // bỏ qua error/loading
// ✅
ref.watch(classroomProvider).when(
  data: (c) => ClassroomView(c),
  loading: () => const LoadingIndicator(),
  error: (e, _) => ErrorView(message: e.toString()),
);
```

---

## Accessibility — bắt buộc (dự án cho học sinh khiếm thính)

```dart
// ✅ Mọi button phải có tooltip
IconButton(
  icon: const Icon(Icons.back_hand),
  tooltip: 'Giơ tay phát biểu', // bắt buộc — không được bỏ
  onPressed: onHandRaise,
)

// ✅ Không truyền thông tin chỉ qua âm thanh
// Khi có học sinh giơ tay → hiện badge số + animation viền nhấp nháy
// KHÔNG dùng beep làm thông báo duy nhất

// ✅ Font minimum: body 16sp, caption 14sp, subtitle STT 18sp bold
// ✅ Contrast ratio: tối thiểu 4.5:1
```

---

## Sau khi sửa xong mỗi bước — bắt buộc

```bash
flutter analyze          # 0 error, 0 warning
dart format lib/
flutter run -d windows   # chạy thử thực tế
```

Cập nhật `CURRENT_TASK.md` — tick checkbox, ghi note nếu gặp vấn đề.