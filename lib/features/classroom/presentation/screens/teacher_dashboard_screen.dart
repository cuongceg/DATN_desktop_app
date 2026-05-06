import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

import '../../../../../models/class_details.dart';
import '../../../../../models/class_member.dart';
import '../../../../../models/user.dart';
import 'edit_class_screen.dart';
import '../../../../../models/class_model.dart';
import '../controllers/classroom_notifier.dart';
import '../widgets/create_classroom_dialog_widget.dart';
import '../widgets/teacher_classroom_card_widget.dart';
import '../../domain/entities/classroom_entity.dart';
import '../../../../../screens/class_management/teams_channel_screen.dart';

/// Dashboard screen for teachers.
///
/// Displays a responsive grid of classrooms managed by the teacher.
/// Reads classroom state from [ClassroomNotifier] via [context.watch] —
/// no prop drilling required.
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeToggle,
    required this.onSearchUsers,
    required this.onAddMembersToClass,
    required this.onFetchClassDetails,
    required this.onAddMember,
    required this.onUpdateMemberRole,
    required this.onRemoveMember,
    required this.onLogout,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;
  final VoidCallback onLogout;
  final Future<List<User>> Function(String keyword) onSearchUsers;
  final Future<void> Function({
    required String classId,
    required List<String> studentIds,
  })
  onAddMembersToClass;
  final Future<ClassDetails> Function(String classId) onFetchClassDetails;
  final Future<ClassMember> Function({
    required String classId,
    required String userId,
    String permission,
  })
  onAddMember;
  final Future<ClassMember> Function({
    required String classId,
    required String userId,
    required String role,
  })
  onUpdateMemberRole;
  final Future<void> Function({required String classId, required String userId})
  onRemoveMember;

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String _selectedFilter = 'All Classes';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClassroomNotifier>();
    final allClassrooms = notifier.classrooms;

    final normalizedQuery = _searchQuery.trim().toLowerCase();

    final classrooms = allClassrooms.where((c) {
      final statusMatches = () {
        if (_selectedFilter == 'All Classes') return true;
        final target = _selectedFilter.toLowerCase();
        final status = (c.status ?? 'active').toLowerCase();
        return status == target;
      }();
      if (!statusMatches) return false;

      if (normalizedQuery.isEmpty) return true;

      final name = c.name.toLowerCase();
      final classCode = (c.classCode ?? '').toLowerCase();
      return name.contains(normalizedQuery) ||
          classCode.contains(normalizedQuery);
    }).toList();

    final availableTeams = allClassrooms
        .map((c) => c.name)
        .toList(growable: false);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final currentThemeMode = widget.currentThemeMode;
    final onThemeToggle = widget.onThemeToggle;
    final onLogout = widget.onLogout;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top App Bar area
        Row(
          children: [
            Expanded(
              child: SearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                leading: const Icon(Icons.search, color: AppColors.outline),
                hintText: 'Search classes by name or code',
                hintStyle: WidgetStatePropertyAll(
                  AppTextStyles.bodyLarge.copyWith(color: AppColors.outline),
                ),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  isLight
                      ? AppColors.white
                      : AppColors.surfaceContainer.withValues(alpha: 0.1),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: AppSizes.brFull,
                    side: BorderSide(
                      color: isLight
                          ? AppColors.luminousBorder
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: AppSizes.md),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppSizes.brMedium,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSizes.brMedium,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                ),
                onPressed: () => _openCreateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create New Class'),
              ),
            ),
            const SizedBox(width: AppSizes.lg),
            const Icon(
              Icons.notifications_none,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: AppSizes.md),
            PopupMenuButton<_HeaderMenuAction>(
              tooltip: 'Tùy chọn tài khoản',
              onSelected: (action) {
                if (action == _HeaderMenuAction.toggleTheme) {
                  onThemeToggle(
                    currentThemeMode == ThemeMode.light
                        ? ThemeMode.dark
                        : ThemeMode.light,
                  );
                  return;
                }
                onLogout();
              },
              itemBuilder: (context) => const [
                PopupMenuItem<_HeaderMenuAction>(
                  value: _HeaderMenuAction.toggleTheme,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.brightness_6_outlined),
                    title: Text('Đổi giao diện'),
                  ),
                ),
                PopupMenuItem<_HeaderMenuAction>(
                  value: _HeaderMenuAction.logout,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout_outlined),
                    title: Text('Đăng xuất'),
                  ),
                ),
              ],
              child: const CircleAvatar(
                radius: 20,
                child: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xl),

        // Welcome Section
        Text(
          'Welcome back, Professor',
          style: AppTextStyles.displayLarge.copyWith(
            color: isLight ? AppColors.onSurface : Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'You have ${classrooms.length} classes for the 2026.2 semester.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: isLight
                ? AppColors.onSurfaceVariant
                : AppColors.outlineVariant,
          ),
        ),
        const SizedBox(height: AppSizes.xl),

        // Filter Chips
        Row(
          children: [
            _FilterChip(
              label: 'All Classes',
              isActive: _selectedFilter == 'All Classes',
              onTap: () => setState(() => _selectedFilter = 'All Classes'),
            ),
            const SizedBox(width: AppSizes.sm),
            _FilterChip(
              label: 'Active',
              isActive: _selectedFilter == 'Active',
              onTap: () => setState(() => _selectedFilter = 'Active'),
            ),
            const SizedBox(width: AppSizes.sm),
            _FilterChip(
              label: 'Archived',
              isActive: _selectedFilter == 'Archived',
              onTap: () => setState(() => _selectedFilter = 'Archived'),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),

        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // ClassroomNotifier.loadClassrooms is called from education_app
              // on auth change; a manual pull-to-refresh reloads from the same
              // provider. We propagate to the parent via onRefresh if needed.
            },
            child: notifier.isLoading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 240),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : classrooms.isEmpty
                ? _EmptyState(
                    message: allClassrooms.isEmpty
                        ? 'Bạn chưa có lớp học nào.\nNhấn "Create New Class" để bắt đầu.'
                        : 'Không có lớp học nào trong danh mục "$_selectedFilter".\nHãy thay đổi bộ lọc hoặc thêm lớp mới.',
                  )
                : _ClassroomGrid(
                    classrooms: classrooms,
                    availableTeams: availableTeams,
                    currentThemeMode: currentThemeMode,
                    onThemeToggle: onThemeToggle,
                    onEdit: (classroom) => _openEditScreen(context, classroom),
                    onArchive: (classroom) =>
                        _confirmArchive(context, classroom),
                    onActivate: (classroom) =>
                        _confirmActivate(context, classroom),
                    onDelete: (classroom) => _confirmDelete(context, classroom),
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _openCreateDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateClassroomDialogWidget(
        onSearchUsers: widget.onSearchUsers,
        onAddMembersToClass: widget.onAddMembersToClass,
      ),
    );
  }

  Future<void> _openEditScreen(
    BuildContext context,
    ClassroomEntity classroom,
  ) async {
    // EditClassScreen still uses ClassModel — bridge until Stage 3.
    final classModel = ClassModel(
      id: classroom.id,
      teacherId: classroom.teacherId,
      classCode: classroom.classCode,
      name: classroom.name,
      description: classroom.description,
      createdAt: classroom.createdAt,
      studentCount: classroom.studentCount,
      status: classroom.status,
    );

    final updated = await Navigator.of(context).push<ClassModel>(
      MaterialPageRoute(
        builder: (_) => EditClassScreen(
          initialClass: classModel,
          fetchClassDetails: widget.onFetchClassDetails,
          searchUsers: widget.onSearchUsers,
          addMember: widget.onAddMember,
          updateMemberRole: widget.onUpdateMemberRole,
          removeMember: widget.onRemoveMember,
          saveClassInfo: ({required name, description}) {
            return context
                .read<ClassroomNotifier>()
                .updateClassroom(
                  id: classroom.id,
                  name: name,
                  description: description,
                )
                .then(
                  (entity) => ClassModel(
                    id: entity.id,
                    teacherId: entity.teacherId,
                    classCode: entity.classCode,
                    name: entity.name,
                    description: entity.description,
                    createdAt: entity.createdAt,
                    studentCount: entity.studentCount,
                    status: entity.status,
                  ),
                );
          },
        ),
      ),
    );

    if (updated != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updated.name} đã được cập nhật.')),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ClassroomEntity classroom,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lớp học'),
        content: Text(
          'Bạn có chắc muốn xóa "${classroom.name}"? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          Semantics(
            label: 'Xác nhận xóa lớp ${classroom.name}',
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xóa'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ClassroomNotifier>().deleteClassroom(classroom.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${classroom.name}" đã được xóa.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmArchive(
    BuildContext context,
    ClassroomEntity classroom,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lưu trữ lớp học'),
        content: Text(
          'Bạn có chắc muốn lưu trữ "${classroom.name}"? Bạn có thể kích hoạt lại sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          Semantics(
            label: 'Xác nhận lưu trữ lớp ${classroom.name}',
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Lưu trữ'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ClassroomNotifier>().archiveClassroom(classroom.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${classroom.name}" đã được lưu trữ.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmActivate(
    BuildContext context,
    ClassroomEntity classroom,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kích hoạt lớp học'),
        content: Text('Bạn có muốn kích hoạt lại "${classroom.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          Semantics(
            label: 'Xác nhận kích hoạt lớp ${classroom.name}',
            child: FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Kích hoạt'),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<ClassroomNotifier>().activateClassroom(classroom.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${classroom.name}" đã được kích hoạt.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _ClassroomGrid extends StatelessWidget {
  const _ClassroomGrid({
    required this.classrooms,
    required this.availableTeams,
    required this.currentThemeMode,
    required this.onThemeToggle,
    required this.onEdit,
    required this.onArchive,
    required this.onActivate,
    required this.onDelete,
  });

  final List<ClassroomEntity> classrooms;
  final List<String> availableTeams;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;
  final void Function(ClassroomEntity) onEdit;
  final void Function(ClassroomEntity) onArchive;
  final void Function(ClassroomEntity) onActivate;
  final void Function(ClassroomEntity) onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 260,
        crossAxisSpacing: AppSizes.gutter,
        mainAxisSpacing: AppSizes.gutter,
      ),
      itemCount: classrooms.length,
      itemBuilder: (context, index) {
        final classroom = classrooms[index];
        return TeacherClassroomCardWidget(
          classroom: classroom,
          onTap: () => _openClassroomChannel(context, classroom),
          onEdit: () => onEdit(classroom),
          onArchive: () => onArchive(classroom),
          onActivate: () => onActivate(classroom),
          onDelete: () => onDelete(classroom),
        );
      },
    );
  }

  void _openClassroomChannel(BuildContext context, ClassroomEntity classroom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamsChannelScreen(
          classId: classroom.id,
          initialTeam: classroom.name,
          availableTeams: availableTeams,
          isTeacher: true,
          currentThemeMode: currentThemeMode,
          onThemeToggle: onThemeToggle,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSizes.brFull,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.unit,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer
              : isLight
              ? AppColors.white
              : Colors.transparent,
          borderRadius: AppSizes.brFull,
          border: isActive
              ? null
              : Border.all(
                  color: isLight
                      ? AppColors.surfaceContainer
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isActive
                ? AppColors.white
                : isLight
                ? AppColors.onSurfaceVariant
                : Colors.white,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

enum _HeaderMenuAction { toggleTheme, logout }
