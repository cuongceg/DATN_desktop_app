# CURRENT_TASKS.md — Frontend Implementation

> Đọc `FLUTTER_SKILLS.md` trước khi bắt đầu bất kỳ task nào.
> Làm tuần tự theo thứ tự task. Mỗi task hoàn thành thì đánh dấu `[x]`.

---

## TASK-FE-01 — Posts: Model & Repository

**Mục tiêu:** Tạo data layer cho feature posts.

**Tạo `lib/features/posts/models/post_model.dart`:**

```dart
class PostModel {
  final String id;
  final String type;        // 'normal' | 'session'
  final String? title;
  final Map<String, dynamic>? bodyDelta;   // Quill Delta JSON: { "ops": [...] }
  final String? bodyPlain;
  final String authorId;
  final String authorName;
  final String? sessionId;
  final String? sessionTitle;
  final String? sessionStatus;  // 'scheduled' | 'ongoing' | 'completed'
  final DateTime? sessionScheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // constructor, fromJson
}
```

`bodyDelta` map từ key `body_delta` (snake_case từ API). `sessionScheduledAt` parse từ `session_scheduled_at` ISO string nullable.

**Tạo `lib/features/posts/data/posts_repository.dart`:**

- `Future<({List<PostModel> posts, int totalCount})> getPosts(String classId, {int limit = 20, int offset = 0})`
  → `GET /api/posts/class/:classId?limit=&offset=`
- `Future<PostModel> getPost(String postId)`
  → `GET /api/posts/:postId`
- `Future<PostModel> createPost({required String classId, String? title, required Map<String, dynamic> bodyDelta, required String bodyPlain})`
  → `POST /api/posts`, body: `{ classId, title, bodyDelta, bodyPlain }`
- `Future<PostModel> updatePost({required String postId, String? title, Map<String, dynamic>? bodyDelta, String? bodyPlain})`
  → `PATCH /api/posts/:postId`
- `Future<void> deletePost(String postId)`
  → `DELETE /api/posts/:postId`

**Acceptance criteria:**
- [x] `fromJson` parse đúng nullable fields (`session_*`, `body_delta`)
- [x] Error từ API throw thành `Exception(message)` để provider catch

---

## TASK-FE-02 — Posts: Provider

**Tạo `lib/features/posts/providers/posts_provider.dart`:**

State: `List<PostModel> posts`, `bool isLoading`, `bool isLoadingMore`, `bool hasMore`, `String? errorMessage`, `int _currentOffset`.

Methods:
- `Future<void> fetchPosts(String classId, {bool refresh = false})` — nếu `refresh: true` reset offset về 0 và clear list.
- `Future<void> loadMorePosts(String classId)` — append vào `posts`, không replace.
- `Future<PostModel?> createPost({...})` — prepend post mới vào đầu list sau khi API thành công.
- `Future<bool> updatePost({...})` — replace item trong list theo id.
- `Future<bool> deletePost(String postId)` — remove khỏi list.

**Đăng ký** vào `MultiProvider` trong `main.dart`.

**Acceptance criteria:**
- [x] `isLoadingMore` và `isLoading` là 2 state độc lập
- [x] Sau `createPost` thành công, post mới đầu list ngay mà không re-fetch
- [x] `hasMore = false` khi `posts.length >= totalCount`

---

## TASK-FE-03 — Posts: Refactor `PostCard` widget

**Mục tiêu:** Thay `PostCardData` mock bằng `PostModel` thật, apply design system.

**Trước khi code: đọc `lib/core/theme/app_theme.dart` và `lib/core/widgets/glass_card.dart`.**

**Refactor `lib/widgets/post_card.dart`:**

1. Nhận `PostModel post`, `String currentUserId`, `bool isTeacher` thay vì `PostCardData`.
2. Hiển thị `authorName`, `createdAt` (format `dd/MM/yyyy HH:mm`), `title`.
3. Body: render `bodyDelta` bằng `QuillEditor` read-only (xem FLUTTER_SKILLS.md §3). Fallback sang `Text(bodyPlain)` nếu `bodyDelta` null.
4. Nút Edit/Delete chỉ hiện khi `post.authorId == currentUserId`.
5. Nếu `post.type == 'session'`: render `SessionPostCard` (tạo widget riêng cùng file hoặc file mới).

**`SessionPostCard`** — card kiểu meeting như screenshot đã cung cấp:
- Icon meeting, `sessionTitle`, thời gian `sessionScheduledAt` (format `HH:mm dd/MM/yyyy`), badge status.
- Nút **Start**: chỉ hiện với teacher khi `sessionStatus == 'scheduled'`. Tap → `SessionProvider.startSession` → navigate `JoinScreen` (tái dùng logic `_handleMeetNow` trong `TeamsChannelScreen`).
- Nút **Join**: chỉ hiện với student khi `sessionStatus == 'ongoing'`. Tap → `SessionProvider.joinSession` → navigate `JoinScreen`.
- `sessionStatus == 'completed'`: badge "Đã kết thúc", không có nút.

**Apply design system:** dùng `GlassCard` làm container (hoặc card style chuẩn của app), màu và typography hoàn toàn từ theme — không hardcode.

**Acceptance criteria:**
- [x] Không còn import `PostCardData` mock
- [x] Quill Delta render đúng formatting
- [x] `SessionPostCard` nút Start/Join đúng điều kiện role + status
- [x] Không hardcode màu hay TextStyle nào

---

## TASK-FE-04 — Posts: Refactor `MessageComposer` widget

**Mục tiêu:** Thay hardcode user info bằng user thật, apply design system.

**Trước khi code: đọc `lib/core/theme/app_theme.dart` và `lib/core/widgets/glass_card.dart`.**

1. Thay `userName: 'Do Manh Cuong 20225172'` hardcode bằng user thật — xem cách `SessionProvider` đang lấy user hiện tại, làm theo cùng pattern (đọc từ `AuthStorage` hoặc `AuthProvider`).
2. Giữ nguyên `onPost` callback signature `(String subject, String bodyPlain, List<dynamic> bodyDelta)` để tương thích với code gọi hiện tại.
3. Apply design system: container, toolbar, button style dùng theme token — không hardcode.

**Acceptance criteria:**
- [x] `userName` và `userInitials` là user đang đăng nhập thật
- [x] Không hardcode màu hay style nào

---

## TASK-FE-05 — Posts: Kết nối `TeamsChannelScreen` với `PostsProvider`
**File: lib/screens/class_management/teams_channel_screen.dart**
**Mục tiêu:** Thay mock `PostCardSamples.posts` bằng data thật từ API.

1. `initState`: gọi `context.read<PostsProvider>().fetchPosts(widget.classId)`.

2. Thay `ListView` render `_posts` mock bằng `Consumer<PostsProvider>`:
   - `isLoading == true` → `CircularProgressIndicator` centered.
   - `errorMessage != null` → error widget + nút Retry gọi lại `fetchPosts`.
   - `posts.isEmpty && !isLoading` → empty state text "Chưa có bài đăng nào".
   - Có data → render list: `PostCard` nếu `type == 'normal'`, `SessionPostCard` nếu `type == 'session'`.

3. **Infinite scroll**: `ScrollController` listener — khi `scrollExtent > 90%` và `!isLoadingMore` và `hasMore` → gọi `loadMorePosts`. Hiển thị `CircularProgressIndicator` nhỏ cuối list khi `isLoadingMore == true`.

4. **`_handlePost`**: gọi `PostsProvider.createPost(classId: widget.classId, title: subject, bodyDelta: {'ops': bodyDelta}, bodyPlain: bodyPlain)`.

5. **`_handleModifyPost`**: gọi `PostsProvider.updatePost(...)`.

6. **`_handleDeletePost`**: gọi `PostsProvider.deletePost(...)`.

7. Truyền `currentUserId` (từ auth) và `isTeacher: widget.isTeacher` vào `PostCard`.

**Acceptance criteria:**
- [x] Posts load từ API khi vào màn hình
- [x] Tạo/sửa/xóa post cập nhật list ngay (không reload trang)
- [x] Infinite scroll gọi loadMore khi cuộn gần cuối
- [x] Session card hiển thị đúng nút theo role và status

---

## TASK-FE-06 — Files: Models & Mapper

**Mục tiêu:** Tạo models mới phù hợp API, mapper sang `FileItem` UI hiện có.

**Tạo `lib/features/files/models/category_model.dart`:**
```dart
class CategoryModel {
  final String id;
  final String classId;
  final String name;
  final int folderCount;
  final DateTime createdAt;
  // constructor, fromJson
}
```

**Tạo `lib/features/files/models/folder_model.dart`:**
```dart
class FolderModel {
  final String id;
  final String classId;
  final String categoryId;
  final String name;
  final int fileCount;
  final DateTime createdAt;
  // constructor, fromJson
}
```

**Tạo `lib/features/files/models/class_file_model.dart`:**
```dart
class ClassFileModel {
  final String id;
  final String originalName;
  final String? mimeType;
  final int? sizeBytes;
  final String uploadedByName;
  final DateTime createdAt;
  // constructor, fromJson
}
```

**Tạo `lib/features/files/models/file_item_mapper.dart`:**

Hàm convert từ API models sang `FileItem` (để tái dùng `FileTableWidget` hiện có):
- `FileItem categoryToFileItem(CategoryModel c, List<FolderModel> folders)` — `isFolder: true`, children = folders mapped.
- `FileItem folderToFileItem(FolderModel f, List<ClassFileModel> files)` — `isFolder: true`, children = files mapped.
- `FileItem classFileToFileItem(ClassFileModel f)` — `isFolder: false`.
- `modifiedDate`: format `'dd MMM'` từ `createdAt`. `modifiedBy` = `uploadedByName`.
- `FileItem.id` = UUID từ API.

**Acceptance criteria:**
- [x] Mapper tạo đúng tree 2 cấp: Category → Folder → File
- [x] `FileItem.id` là UUID thật từ API (không tự sinh)

---

## TASK-FE-07 — Files: Repository

**Tạo `lib/features/files/data/files_repository.dart`:**

- `Future<List<CategoryModel>> getCategories(String classId)`
  → `GET /api/files/class/:classId/categories`
- `Future<CategoryModel> createCategory(String classId, String name)`
  → `POST /api/files/class/:classId/categories`
- `Future<void> deleteCategory(String classId, String categoryId)`
  → `DELETE /api/files/class/:classId/categories/:categoryId`
- `Future<List<FolderModel>> getFolders(String classId, String categoryId)`
  → `GET /api/files/class/:classId/categories/:categoryId/folders`
- `Future<FolderModel> createFolder(String classId, String categoryId, String name)`
  → `POST /api/files/class/:classId/categories/:categoryId/folders`
- `Future<void> deleteFolder(String classId, String categoryId, String folderId)`
  → `DELETE /api/files/class/:classId/categories/:categoryId/folders/:folderId`
- `Future<List<ClassFileModel>> getFiles(String classId, String folderId)`
  → `GET /api/files/class/:classId/folders/:folderId/files`
- `Future<ClassFileModel> uploadFile(String classId, String folderId, String filePath, String fileName)`
  → `POST /api/files/class/:classId/folders/:folderId/upload` dùng `FormData` + `MultipartFile` của Dio, field name `file`
- `Future<String> getDownloadUrl(String fileId)`
  → `GET /api/files/:fileId/download-url` → trả về `download_url` string
- `Future<void> deleteFile(String fileId)`
  → `DELETE /api/files/:fileId`

**Acceptance criteria:**
- [x] `uploadFile` dùng `FormData` Dio đúng cách
- [x] Error handling throw `Exception(message)` nhất quán

---

## TASK-FE-08 — Files: Provider

**Tạo `lib/features/files/providers/files_provider.dart`:**

State:
- `List<CategoryModel> categories`
- `Map<String, List<FolderModel>> foldersByCategory` — key = `categoryId`
- `Map<String, List<ClassFileModel>> filesByFolder` — key = `folderId`
- `bool isLoading`, `bool isUploading`, `String? errorMessage`

Methods:
- `Future<void> fetchCategories(String classId)`
- `Future<void> fetchFolders(String classId, String categoryId)` — lazy: chỉ gọi API nếu `foldersByCategory[categoryId]` chưa có
- `Future<void> fetchFiles(String classId, String folderId)` — lazy tương tự
- `Future<bool> createCategory(String classId, String name)` — thêm vào `categories` local sau thành công
- `Future<bool> deleteCategory(String classId, String categoryId)` — remove khỏi local state ngay
- `Future<bool> createFolder(String classId, String categoryId, String name)`
- `Future<bool> deleteFolder(String classId, String categoryId, String folderId)`
- `Future<bool> uploadFile(String classId, String folderId, String filePath, String fileName)` — set `isUploading` trong lúc upload
- `Future<String?> getDownloadUrl(String fileId)`
- `Future<bool> deleteFile(String classId, String folderId, String fileId)`

**Đăng ký** vào `MultiProvider` trong `main.dart`.

**Acceptance criteria:**
- [x] `fetchFolders` / `fetchFiles` lazy + cache — không gọi API lần 2 nếu đã có data
- [x] Create/delete cập nhật local state ngay không cần re-fetch toàn bộ
- [x] `isUploading` tách biệt với `isLoading`

---

## TASK-FE-09 — Files: Refactor `DocumentManagementScreen`

**Mục tiêu:** Thay mock `rootDirectory` bằng data thật, apply đúng design system.

**Trước khi code: đọc `lib/core/theme/app_theme.dart` và `lib/core/widgets/glass_card.dart`.**

**1. Thêm props:**
```dart
final String classId;
final bool isTeacher;
```
Cập nhật nơi gọi trong `TeamsChannelScreen` — truyền `widget.classId` và `widget.isTeacher`.

**2. Thay `rootDirectory` mock:**
- `initState`: `context.read<FilesProvider>().fetchCategories(widget.classId)`.
- Dùng `Consumer<FilesProvider>` để rebuild khi state thay đổi.

**3. Navigation 3 cấp** (thay vì mock tree):
- **Root**: list categories từ `provider.categories`. Tap → lazy fetch folders (`fetchFolders`) → navigate vào cấp category.
- **Category**: list folders từ `provider.foldersByCategory[categoryId]`. Tap → lazy fetch files (`fetchFiles`) → navigate vào cấp folder.
- **Folder**: list files từ `provider.filesByFolder[folderId]`.
- Breadcrumb cập nhật đúng ở từng cấp.

**4. Map sang `FileItem`** dùng mapper từ TASK-FE-06 để tái dùng `FileTableWidget` — không viết lại table.

**5. Action bar** (chỉ hiện khi `isTeacher == true`):
- Nút **New** (tuỳ cấp hiện tại: tạo category ở root, tạo folder ở cấp category): `showDialog` nhập tên → gọi provider method tương ứng.
- Nút **Upload** (chỉ ở cấp folder): mở file picker (dùng `file_picker` package — thêm vào `pubspec.yaml` nếu chưa có) → gọi `FilesProvider.uploadFile`. Hiển thị loading khi `isUploading == true`.

**6. Delete** (chỉ teacher):
- File: context menu hoặc swipe với option Delete → confirm dialog → `FilesProvider.deleteFile`.
- Folder: tương tự → `deleteFolder`.
- Category: tương tự → `deleteCategory`.

**7. Download** (student tap vào file):
- Gọi `FilesProvider.getDownloadUrl(fileId)` → mở URL bằng `url_launcher` (thêm vào `pubspec.yaml` nếu chưa có).

**8. Loading state:** `isLoading == true` → `CircularProgressIndicator` centered thay vì table rỗng.

**9. Apply design system:** toàn bộ screen — action bar, breadcrumb, table — dùng theme token. Không hardcode màu, style, spacing nào.

**Acceptance criteria:**
- [x] Không còn `rootDirectory` mock trong code
- [x] Breadcrumb đúng ở cả 3 cấp
- [x] Teacher upload file thành công, file xuất hiện trong list ngay
- [x] Student tap file → download URL mở được
- [x] Teacher delete có confirm dialog
- [x] Không hardcode màu hay TextStyle nào

---

## TASK-FE-10 — Design system audit: `TeamsChannelScreen`

**Mục tiêu:** Rà soát và fix toàn bộ `TeamsChannelScreen` sau khi FE-05 và FE-09 xong.

**Trước khi code: đọc `lib/core/theme/app_theme.dart` và `lib/core/widget/glass_card.dart`, liệt kê tất cả token màu/spacing/radius đang dùng trong app.**

Rà soát từng widget, fix các vi phạm:
- Màu hardcode → `colorScheme.*`
- `TextStyle` hardcode → `textTheme.*`
- `BorderRadius` hardcode → constant từ theme
- Spacing không nhất quán → align theo scale `8 / 12 / 16 / 24`
- Sidebar: `surfaceContainerLow`, selected tile color dùng đúng token.
- AppBar: `elevation`, `shadowColor`, `backgroundColor` nhất quán với các screen khác.
- `OutlinedButton` "Meet now": `side`, `foregroundColor`, `disabledForegroundColor` dùng theme token.
- SnackBar success/error: thay `Colors.green` / `Colors.red` bằng `colorScheme.primary` / `colorScheme.error` nếu theme có.

**Acceptance criteria:**
- [ ] Không còn hardcode màu nào
- [ ] Light mode và dark mode đều render đúng

---

## Thứ tự thực hiện

```
FE-01 ──→ FE-02 ──→ FE-03 ──→ FE-04 ──→ FE-05
FE-06 ──→ FE-07 ──→ FE-08 ──→ FE-09
                                         FE-10  (sau khi FE-05 + FE-09 done)
```

FE-01~02 và FE-06~07 có thể làm song song (data layer độc lập).
FE-03, FE-04 phụ thuộc FE-01 (cần `PostModel`).
FE-05 phụ thuộc FE-02, FE-03, FE-04.
FE-09 phụ thuộc FE-06, FE-07, FE-08.