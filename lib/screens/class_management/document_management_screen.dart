import 'package:data_table_2/data_table_2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/files/models/file_node_mapper.dart';
import '../../features/files/providers/files_provider.dart';
import '../../models/file_item.dart';

// ─── Navigation helpers ───────────────────────────────────────────────────────

class _NavEntry {
  const _NavEntry({required this.name, required this.path});
  final String name;
  final String path; // POSIX path e.g. "/", "/slides", "/slides/week1"
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

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  List<_NavEntry> _navStack = [
    const _NavEntry(name: 'Tài liệu', path: '/'),
  ];

  String get _currentPath => _navStack.last.path;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<FilesProvider>();
        provider.clearCache();
        provider.fetchContent(widget.classId, '/');
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
                    (e) => FileItem(id: e.path, name: e.name, isFolder: true),
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
    return (provider.itemsByPath[_currentPath] ?? const [])
        .map(fileNodeToFileItem)
        .toList();
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  void _handleItemTap(
    BuildContext context,
    FilesProvider provider,
    FileItem item,
  ) {
    if (item.isFolder) {
      setState(() {
        _navStack = [
          ..._navStack,
          _NavEntry(name: item.name, path: item.path),
        ];
      });
      provider.fetchContent(widget.classId, item.path);
    } else {
      _handleDownload(context, provider, item.path);
    }
  }

  void _navigateToBreadcrumb(int index) {
    setState(() {
      _navStack = _navStack.sublist(0, index + 1);
    });
    context.read<FilesProvider>().fetchContent(widget.classId, _currentPath);
  }

  void _retryFetch(FilesProvider provider) {
    provider.fetchContent(widget.classId, _currentPath, forceRefresh: true);
  }

  // ─── Action bar ──────────────────────────────────────────────────────────────

  Widget _buildActionBar(BuildContext context, FilesProvider provider) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (widget.isTeacher)
            PopupMenuButton<String>(
              offset: const Offset(0, 44),
              onSelected: (val) {
                if (val == 'folder') _handleNew(context, provider);
                if (val == 'upload') _handleUpload(context, provider);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'folder',
                  child: ListTile(
                    leading: Icon(Icons.create_new_folder_outlined),
                    title: Text('Thư mục mới'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'upload',
                  enabled: !provider.isUploading,
                  child: ListTile(
                    leading: provider.isUploading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : const Icon(Icons.upload_outlined),
                    title: Text(
                      provider.isUploading ? 'Đang tải lên...' : 'Tải lên tệp',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: FilledButton.icon(
                // PopupMenuButton tự xử lý tap
                onPressed: null,
                icon: Icon(Icons.add, size: 18, color: colors.primary),
                label:  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tạo', style: TextStyle(fontSize: 14, color: colors.primary)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: colors.primary),
                  ],
                ),
              ),
            ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Tạo thư mục mới'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thư mục',
                border: OutlineInputBorder(),
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

    if (confirmed != true || nameController.text.trim().isEmpty || !context.mounted) {
      return;
    }
    final name = nameController.text.trim();
    final folderPath = '$_currentPath/$name'.replaceAll('//', '/');
    final ok = await provider.createFolder(widget.classId, folderPath);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Tạo thư mục thất bại.')),
      );
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
    final filePath = '$_currentPath/${file.name}'.replaceAll('//', '/');
    final ok = await provider.uploadFile(
      widget.classId,
      filePath,
      file.path!,
      file.name,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Tải lên thất bại.')),
      );
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    FilesProvider provider,
    FileItem item,
  ) async {
    final colors = Theme.of(context).colorScheme;
    final typeName = item.isFolder ? 'thư mục' : 'tệp';

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
    final ok = await provider.deleteContent(widget.classId, item.path);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Xóa thất bại.')),
      );
    }
  }

  Future<void> _handleDownload(
    BuildContext context,
    FilesProvider provider,
    String filePath,
  ) async {
    final url = await provider.getDownloadUrl(widget.classId, filePath);
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
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  color: isLast ? colors.onSurface : colors.onSurfaceVariant,
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
                            item.isFolder ? FontWeight.w500 : FontWeight.normal,
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
