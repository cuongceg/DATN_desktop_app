import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../models/file_item.dart';

final FileItem rootDirectory = FileItem(
  id: 'root',
  name: 'Documents',
  isFolder: true,
  children: [
    FileItem(
      id: 'general',
      name: 'General',
      isFolder: true,
      modifiedDate: 'April 1',
      modifiedBy: 'System',
      children: [
        FileItem(
          id: 'folder1',
          name: 'Tài liệu lớp học',
          isFolder: true,
          modifiedDate: 'March 25',
          modifiedBy: 'Do Manh Cuong',
          children: [
            FileItem(
              id: 'file2',
              name: 'Bài tập nhóm.docx',
              isFolder: false,
              modifiedDate: 'April 2',
              modifiedBy: 'Nguyen Van An',
            ),
            FileItem(
              id: 'file3',
              name: 'Slide bài giảng.pptx',
              isFolder: false,
              modifiedDate: 'April 5',
              modifiedBy: 'Tran Thi Bich',
            ),
          ],
        ),
        FileItem(
          id: 'file1',
          name: 'Loop paragraph.loop',
          isFolder: false,
          modifiedDate: 'March 31',
          modifiedBy: 'Nguyen Thi Thuy Linh',
        ),
      ],
    ),
    FileItem(
      id: 'design',
      name: 'Design Assets',
      isFolder: true,
      modifiedDate: 'April 8',
      modifiedBy: 'Le Quoc Bao',
      children: [
        FileItem(
          id: 'file4',
          name: 'Logo_Final.png',
          isFolder: false,
          modifiedDate: 'April 8',
          modifiedBy: 'Le Quoc Bao',
        ),
      ],
    ),
  ],
);

class DocumentManagementScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;
  final bool embedded;

  const DocumentManagementScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeToggle,
    this.embedded = false,
  });

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  // Trạng thái theo dõi đường dẫn hiện tại (Breadcrumbs state)
  List<FileItem> currentPath = [
    rootDirectory,
    rootDirectory.children.first,
  ]; // Mặc định vào Documents > General

  // Chuyển vào thư mục con
  void _navigateToFolder(FileItem folder) {
    if (folder.isFolder) {
      setState(() {
        currentPath.add(folder);
      });
    }
  }

  // Quay lại thư mục cha thông qua Breadcrumb
  void _navigateToBreadcrumb(int index) {
    setState(() {
      currentPath = currentPath.sublist(0, index + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Danh sách file/folder trong thư mục hiện tại
    final currentDirectoryContents = currentPath.last.children;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Action Bar
        const ActionBarWidget(),
        const Divider(height: 1),

        // 2. Breadcrumb Area
        BreadcrumbWidget(path: currentPath, onNavigate: _navigateToBreadcrumb),
        const Divider(height: 1),

        Expanded(
          child: FileTableWidget(
            items: currentDirectoryContents,
            onItemTap: _navigateToFolder,
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: theme.scaffoldBackgroundColor, child: content);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: content,
    );
  }
}

/// --- TOP ACTION BAR ---
class ActionBarWidget extends StatelessWidget {
  const ActionBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 980;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: isCompact
              ? Row(
                  children: [
                    Wrap(
                      spacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildIconBtn(
                          context,
                          Icons.filter_list,
                          'Filter documents',
                        ),
                        _buildIconBtn(
                          context,
                          Icons.download_outlined,
                          'Download',
                        ),
                        _buildIconBtn(context, Icons.upload_outlined, 'Upload'),
                        _buildPrimaryIconBtn(context, Icons.add, 'New'),
                        _buildIconBtn(
                          context,
                          Icons.more_horiz,
                          'More actions',
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Actions
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Nút + New màu tím đặc trưng
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF5B5FC7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New'),
                        ),
                        _buildTextBtn(context, Icons.upload_outlined, 'Upload'),
                        _buildTextBtn(
                          context,
                          Icons.download_outlined,
                          'Download',
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.more_horiz, size: 20),
                        ),
                      ],
                    ),
                    // Right Actions
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildTextBtn(
                          context,
                          Icons.filter_list,
                          'All Documents',
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildIconBtn(BuildContext context, IconData icon, String tooltip) {
    return IconButton(
      onPressed: () {},
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
    );
  }

  Widget _buildPrimaryIconBtn(
    BuildContext context,
    IconData icon,
    String tooltip,
  ) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF5B5FC7),
        foregroundColor: Colors.white,
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () {},
      child: Tooltip(message: tooltip, child: Icon(icon, size: 20)),
    );
  }

  Widget _buildTextBtn(BuildContext context, IconData icon, String label) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

/// --- BREADCRUMB AREA ---
class BreadcrumbWidget extends StatelessWidget {
  final List<FileItem> path;
  final Function(int) onNavigate;

  const BreadcrumbWidget({
    super.key,
    required this.path,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: List.generate(path.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            );
          }
          final pathIndex = index ~/ 2;
          final isLast = pathIndex == path.length - 1;

          return InkWell(
            onTap: () => onNavigate(pathIndex),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                path[pathIndex].name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  color: isLast
                      ? theme.colorScheme.onSurface
                      : Colors.grey.shade600,
                  fontSize: 20,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// --- FILE DATA TABLE ---
class FileTableWidget extends StatelessWidget {
  final List<FileItem> items;
  final Function(FileItem) onItemTap;

  const FileTableWidget({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 24,
      minWidth: 600,
      showCheckboxColumn: false,
      // Cấu hình màu hover cho hàng
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return isDark ? const Color(0xFF292929) : Colors.grey.shade100;
        }
        return Colors.transparent;
      }),
      headingTextStyle: TextStyle(
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
      columns: const [
        DataColumn2(label: Text('Name'), size: ColumnSize.L),
        DataColumn2(label: Text('Modified'), size: ColumnSize.S),
        DataColumn2(label: Text('Modified By'), size: ColumnSize.M),
        DataColumn2(label: Text('+ Add column'), size: ColumnSize.S),
      ],
      rows: items.map((item) {
        return DataRow2(
          onTap: () => onItemTap(item),
          cells: [
            DataCell(
              Row(
                children: [
                  _buildIcon(item),
                  const SizedBox(width: 12),
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: item.isFolder
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                  if (item.isFolder) ...[
                    const Spacer(),
                    Icon(
                      Icons.push_pin_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ],
              ),
            ),
            DataCell(Text(item.modifiedDate)),
            DataCell(
              item.modifiedBy.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF252525)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.modifiedBy,
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const DataCell(Text('')), // Cột trống cho "Add column"
          ],
        );
      }).toList(),
    );
  }

  // Helper function để lấy icon phù hợp
  Widget _buildIcon(FileItem item) {
    if (item.isFolder) {
      return const Icon(Icons.folder, color: Colors.amber, size: 24);
    }

    // Icon tùy chỉnh theo loại file
    if (item.name.endsWith('.loop')) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF5B5FC7).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.all_inclusive,
          color: Color(0xFF5B5FC7),
          size: 16,
        ),
      );
    } else if (item.name.endsWith('.docx')) {
      return const Icon(Icons.description, color: Colors.blue, size: 24);
    } else if (item.name.endsWith('.pptx')) {
      return const Icon(Icons.pie_chart, color: Colors.orange, size: 24);
    }

    return const Icon(Icons.insert_drive_file, color: Colors.grey, size: 24);
  }
}
