import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/files/models/file_item_mapper.dart';
import '../../features/files/providers/files_provider.dart';
import '../../models/file_item.dart';

// ─── Navigation helpers ───────────────────────────────────────────────────────

enum _NavLevel { root, category, folder }

class _NavEntry {
  const _NavEntry({required this.name, required this.level, this.id});
  final String name;
  final _NavLevel level;
  final String? id;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({
    super.key,
    required this.classId,
    required this.isTeacher,
    required this.currentThemeMode,
    required this.onThemeToggle,
    this.embedded = false,
  });

  final String classId;
  final bool isTeacher;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;
  final bool embedded;

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState
    extends State<DocumentManagementScreen> {
  List<_NavEntry> _navStack = [
    const _NavEntry(name: 'Tài liệu', level: _NavLevel.root),
  ];

  _NavLevel get _currentLevel => _navStack.last.level;
  String? get _currentId => _navStack.last.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<FilesProvider>();
        provider.clearCache();
        provider.fetchCategories(widget.classId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Consumer<FilesProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActionBar(context, provider),
            const Divider(height: 1),
            BreadcrumbWidget(
              path: _navStack
                  .map(
                    (e) => FileItem(
                      id: e.id ?? 'root',
                      name: e.name,
                      isFolder: true,
                    ),
                  )
                  .toList(),
              onNavigate: _navigateToBreadcrumb,
            ),
            const Divider(height: 1),
            Expanded(child: _buildContent(context, provider)),
          ],
        );
      },
    );

    if (widget.embedded) {
      return ColoredBox(color: theme.scaffoldBackgroundColor, child: content);
    }
    return Scaffold(backgroundColor: theme.scaffoldBackgroundColor, body: content);
  }

  // ─── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, FilesProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: colors.primary));
    }

    final items = _getCurrentItems(provider);

    if (provider.errorMessage != null && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _retryFetch(provider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return FileTableWidget(
      items: items,
      onItemTap: (item) => _handleItemTap(context, provider, item),
      onItemDelete:
          widget.isTeacher
              ? (item) => _handleDelete(context, provider, item)
              : null,
    );
  }

  List<FileItem> _getCurrentItems(FilesProvider provider) {
    switch (_currentLevel) {
      case _NavLevel.root:
        return provider.categories
            .map((c) => categoryToFileItem(c, const []))
            .toList();
      case _NavLevel.category:
        final folders = provider.foldersByCategory[_currentId!] ?? const [];
        return folders.map((f) => folderToFileItem(f, const [])).toList();
      case _NavLevel.folder:
        final files = provider.filesByFolder[_currentId!] ?? const [];
        return files.map(classFileToFileItem).toList();
    }
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  void _handleItemTap(
    BuildContext context,
    FilesProvider provider,
    FileItem item,
  ) {
    if (item.isFolder) {
      switch (_currentLevel) {
        case _NavLevel.root:
          setState(() {
            _navStack = [
              ..._navStack,
              _NavEntry(
                name: item.name,
                level: _NavLevel.category,
                id: item.id,
              ),
            ];
          });
          provider.fetchFolders(widget.classId, item.id, forceRefresh: true);
          break;
        case _NavLevel.category:
          setState(() {
            _navStack = [
              ..._navStack,
              _NavEntry(
                name: item.name,
                level: _NavLevel.folder,
                id: item.id,
              ),
            ];
          });
          provider.fetchFiles(widget.classId, item.id, forceRefresh: true);
          break;
        case _NavLevel.folder:
          break;
      }
    } else {
      _handleDownload(context, provider, item.id);
    }
  }

  void _navigateToBreadcrumb(int index) {
    setState(() {
      _navStack = _navStack.sublist(0, index + 1);
    });

    final provider = context.read<FilesProvider>();
    switch (_currentLevel) {
      case _NavLevel.root:
        provider.fetchCategories(widget.classId);
        break;
      case _NavLevel.category:
        provider.fetchFolders(widget.classId, _currentId!, forceRefresh: false);
        break;
      case _NavLevel.folder:
        provider.fetchFiles(widget.classId, _currentId!, forceRefresh: false);
        break;
    }
  }

  void _retryFetch(FilesProvider provider) {
    switch (_currentLevel) {
      case _NavLevel.root:
        provider.fetchCategories(widget.classId);
        break;
      case _NavLevel.category:
        provider.fetchFolders(widget.classId, _currentId!, forceRefresh: true);
        break;
      case _NavLevel.folder:
        provider.fetchFiles(widget.classId, _currentId!, forceRefresh: true);
        break;
    }
  }

  // ─── Action bar ──────────────────────────────────────────────────────────────

  Widget _buildActionBar(BuildContext context, FilesProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.isTeacher) ...[
            if (_currentLevel != _NavLevel.folder)
              FilledButton.icon(
                onPressed: () => _handleNew(context, provider),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  _currentLevel == _NavLevel.root
                      ? 'Danh mục mới'
                      : 'Thư mục mới',
                ),
              ),
            if (_currentLevel == _NavLevel.folder)
              provider.isUploading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đang tải lên...',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      onPressed: () => _handleUpload(context, provider),
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('Tải lên'),
                    ),
          ],
          const Spacer(),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: colors.onSurface),
            onPressed: null,
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('All Documents'),
          ),
        ],
      ),
    );
  }

  // ─── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _handleNew(
    BuildContext context,
    FilesProvider provider,
  ) async {
    final nameController = TextEditingController();
    final isCategory = _currentLevel == _NavLevel.root;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(isCategory ? 'Tạo danh mục mới' : 'Tạo thư mục mới'),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: isCategory ? 'Tên danh mục' : 'Tên thư mục',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Tạo'),
              ),
            ],
          ),
    );

    if (confirmed != true ||
        nameController.text.trim().isEmpty ||
        !context.mounted) {
      return;
    }
    final name = nameController.text.trim();
    if (isCategory) {
      await provider.createCategory(widget.classId, name);
    } else {
      await provider.createFolder(widget.classId, _currentId!, name);
    }
  }

  Future<void> _handleUpload(
    BuildContext context,
    FilesProvider provider,
  ) async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null || !context.mounted) return;
    await provider.uploadFile(
      widget.classId,
      _currentId!,
      file.path!,
      file.name,
    );

    // Ensure UI matches server state even if upload response parsing fails.
    if (!context.mounted) return;
    await provider.fetchFiles(widget.classId, _currentId!, forceRefresh: true);
  }

  Future<void> _handleDelete(
    BuildContext context,
    FilesProvider provider,
    FileItem item,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final typeName =
        !item.isFolder
            ? 'tệp'
            : (_currentLevel == _NavLevel.root ? 'danh mục' : 'thư mục');

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Xóa $typeName'),
            content: Text('Bạn có chắc muốn xóa "${item.name}" không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Huỷ'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colors.error),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;
    switch (_currentLevel) {
      case _NavLevel.root:
        await provider.deleteCategory(widget.classId, item.id);
        break;
      case _NavLevel.category:
        await provider.deleteFolder(widget.classId, _currentId!, item.id);
        break;
      case _NavLevel.folder:
        await provider.deleteFile(widget.classId, _currentId!, item.id);
        break;
    }
  }

  Future<void> _handleDownload(
    BuildContext context,
    FilesProvider provider,
    String fileId,
  ) async {
    final url = await provider.getDownloadUrl(fileId);
    if (url == null || !context.mounted) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Breadcrumb ───────────────────────────────────────────────────────────────

class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({
    super.key,
    required this.path,
    required this.onNavigate,
  });

  final List<FileItem> path;
  final void Function(int index) onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(path.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            );
          }
          final pathIndex = index ~/ 2;
          final isLast = pathIndex == path.length - 1;
          return InkWell(
            onTap: () => onNavigate(pathIndex),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                path[pathIndex].name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight:
                      isLast ? FontWeight.bold : FontWeight.normal,
                  color:
                      isLast ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── File table ───────────────────────────────────────────────────────────────

class FileTableWidget extends StatelessWidget {
  const FileTableWidget({
    super.key,
    required this.items,
    required this.onItemTap,
    this.onItemDelete,
  });

  final List<FileItem> items;
  final void Function(FileItem item) onItemTap;
  final void Function(FileItem item)? onItemDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 24,
      minWidth: 600,
      showCheckboxColumn: false,
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return isDark
              ? colors.surfaceContainerHighest
              : colors.surfaceContainerLow;
        }
        return Colors.transparent;
      }),
      headingTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      columns: const [
        DataColumn2(label: Text('Name'), size: ColumnSize.L),
        DataColumn2(label: Text('Modified'), size: ColumnSize.S),
        DataColumn2(label: Text('Modified By'), size: ColumnSize.M),
        DataColumn2(label: Text(''), size: ColumnSize.S),
      ],
      rows: items.map((item) {
        return DataRow2(
          onTap: () => onItemTap(item),
          cells: [
            DataCell(
              Row(
                children: [
                  _buildIcon(context, item),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontWeight:
                            item.isFolder
                                ? FontWeight.w500
                                : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.isFolder)
                    Icon(
                      Icons.push_pin_outlined,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            DataCell(
              Text(
                item.modifiedDate,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            DataCell(
              item.modifiedBy.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.modifiedBy,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            DataCell(
              onItemDelete != null
                  ? PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'delete') onItemDelete!(item);
                      },
                      itemBuilder:
                          (_) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Xóa'),
                            ),
                          ],
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildIcon(BuildContext context, FileItem item) {
    final colors = Theme.of(context).colorScheme;
    if (item.isFolder) {
      return Icon(Icons.folder_rounded, color: colors.secondary, size: 24);
    }
    final name = item.name.toLowerCase();
    if (name.endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf, color: colors.error, size: 24);
    }
    if (name.endsWith('.docx') || name.endsWith('.doc')) {
      return Icon(Icons.description, color: colors.primary, size: 24);
    }
    if (name.endsWith('.pptx') || name.endsWith('.ppt')) {
      return Icon(Icons.slideshow, color: colors.tertiary, size: 24);
    }
    if (name.endsWith('.xlsx') || name.endsWith('.xls')) {
      return Icon(Icons.table_chart, color: colors.secondary, size: 24);
    }
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].any(name.endsWith)) {
      return Icon(Icons.image, color: colors.tertiary, size: 24);
    }
    return Icon(Icons.insert_drive_file, color: colors.onSurfaceVariant, size: 24);
  }
}
