# FLUTTER_SKILLS.md — Frontend Agent

> Đọc file này trước khi bắt đầu bất kỳ task nào.

---

## 1. Project conventions

### Feature structure
Mỗi feature nằm trong `lib/features/<feature_name>/` với cấu trúc:
```
lib/features/<feature_name>/
  data/          ← raw API response parsing, repository impl
  models/        ← Dart model classes (fromJson, toJson)
  providers/     ← ChangeNotifier providers
  screens/       ← Screen widgets
  services/      ← (tuỳ chọn) business logic tách khỏi provider
```
Tham khảo `lib/features/session/` để biết pattern đang dùng — làm đúng theo cấu trúc đó.

### State management
- **Provider + ChangeNotifier** — không dùng Riverpod, Bloc, hay GetX.
- Pattern chuẩn của provider trong project:
  ```dart
  class XxxProvider extends ChangeNotifier {
    bool _isLoading = false;
    String? _errorMessage;
    List<XxxModel> _items = [];

    bool get isLoading => _isLoading;
    String? get errorMessage => _errorMessage;
    List<XxxModel> get items => _items;

    Future<void> fetchItems(...) async {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      try {
        _items = await _repository.getItems(...);
      } catch (e) {
        _errorMessage = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
  ```
- Đăng ký provider mới vào `MultiProvider` trong `main.dart`.
- Dùng `context.read<XxxProvider>()` cho action, `context.watch<XxxProvider>()` hoặc `Consumer<XxxProvider>` cho rebuild.

### HTTP client
- Dùng **Dio** package — client singleton đã được cấu hình sẵn với base URL hardcode.
- Đọc file dio client hiện tại trước khi tạo repository mới để dùng đúng instance.
- Mọi request cần auth đều gắn Bearer token — interceptor đã xử lý tự động, không cần set header thủ công.
- Token JWT lưu ở **SecureStorage**, đọc qua `AuthStorage` tại `services/auth_storage.dart`.

### API response handling pattern
```dart
// Trong repository/data layer
Future<List<PostModel>> getPosts(String classId, {int limit = 20, int offset = 0}) async {
  try {
    final response = await _dio.get(
      '/api/posts/class/$classId',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final list = response.data['posts'] as List;
    return list.map((e) => PostModel.fromJson(e)).toList();
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}

String _handleDioError(DioException e) {
  return e.response?.data['message'] as String? ?? 'Unknown error occurred.';
}
```

### Model convention
```dart
class PostModel {
  final String id;
  final String type; // 'normal' | 'session'
  // ...

  const PostModel({required this.id, required this.type, ...});

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id: json['id'] as String,
    type: json['type'] as String,
    // nullable fields dùng json['field'] as String?
  );
}
```
- Model là **immutable** (dùng `const` constructor, `final` fields).
- Nullable fields dùng `Type?`.
- Không dùng `json_serializable` hay `freezed` — viết tay `fromJson`.

---

## 2. Design system

### Nguyên tắc chung
Tất cả UI mới và UI được refactor **phải tuân thủ design system của app**. Trước khi viết bất kỳ widget nào:
1. Đọc `app_theme.dart` (hoặc `theme.dart`) để lấy đúng màu sắc, typography, border radius.
2. Đọc `glass_card.dart` / `glass_theme.dart` để dùng đúng glass effect component.
3. **Không hardcode màu** — luôn dùng `Theme.of(context).colorScheme.*` hoặc các constant từ theme file.
4. **Không hardcode TextStyle** — dùng `Theme.of(context).textTheme.*`.

### Spacing & layout
- Dùng spacing nhất quán: `8, 12, 16, 24` dp.
- Card border radius: đọc từ theme, không tự đặt số.
- Responsive: dùng `LayoutBuilder` khi layout thay đổi theo width (đã có ví dụ trong `ActionBarWidget`).

### Component reuse
- Nếu đã có `GlassCard` widget → dùng nó cho card container, không tự tạo `Container` với decoration riêng.
- Nếu cần avatar/initials → kiểm tra xem project đã có shared widget chưa trước khi tạo mới.
- Loading state: dùng `CircularProgressIndicator` với `color: Theme.of(context).colorScheme.primary`.
- Error state: hiển thị trong UI (không chỉ SnackBar) nếu là lỗi load trang.

### Dark/Light mode
- App hỗ trợ cả dark và light mode — mọi widget mới phải test cả 2.
- Không dùng `Colors.white` hay `Colors.black` trực tiếp — dùng `colorScheme.surface`, `colorScheme.onSurface`, v.v.

---

## 3. Rich text (Flutter Quill)

- Package: `flutter_quill`
- `body_delta` từ API là `Map<String, dynamic>` (Quill Delta JSON object với key `ops`).
- **Render** (read-only):
  ```dart
  final controller = QuillController(
    document: Document.fromJson(post.bodyDelta?['ops'] ?? [{'insert': ''}]),
    selection: const TextSelection.collapsed(offset: 0),
  );
  QuillEditor.basic(controller: controller, readOnly: true)
  ```
- **Edit** (composer): `QuillEditor` + `QuillToolbar` — xem `MessageComposer` widget hiện tại để tái sử dụng.
- Khi POST/PATCH lên API:
  - `bodyDelta`: `controller.document.toDelta().toJson()` → wrap thành `{'ops': [...]}` nếu cần.
  - `bodyPlain`: `controller.document.toPlainText().trim()`.

---

## 4. File & MIME type helpers

Khi hiển thị icon cho file trong `DocumentManagementScreen`, dùng MIME type từ API (`mime_type` field) thay vì đoán từ extension:
```dart
IconData fileIconFromMime(String? mimeType) {
  if (mimeType == null) return Icons.insert_drive_file;
  if (mimeType.startsWith('image/')) return Icons.image;
  if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
  if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
  if (mimeType.contains('sheet') || mimeType.contains('excel')) return Icons.table_chart;
  if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) return Icons.slideshow;
  return Icons.insert_drive_file;
}
```

File size display helper:
```dart
String formatFileSize(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}
```

---

## 5. Navigation pattern
- Dùng `Navigator.of(context).push(MaterialPageRoute(...))` — project chưa dùng go_router hay auto_route.
- Sau action thành công (create/delete), dùng `context.read<XxxProvider>().fetchXxx(...)` để refresh — không pop và push lại màn hình.

---

## 6. Form & validation pattern
- Validate inline trước khi gọi provider, hiển thị lỗi qua `SnackBar` hoặc inline text.
- Dùng `TextEditingController` và dispose trong `dispose()`.
- Dialog confirm trước khi delete: dùng `showDialog<bool>` pattern như đã có trong `_handleScheduleMeeting`.