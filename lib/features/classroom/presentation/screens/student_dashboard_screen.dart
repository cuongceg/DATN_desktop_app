import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

import '../../../../../models/class_notification.dart';
import '../controllers/classroom_notifier.dart';
import '../widgets/student_classroom_card_widget.dart';
import '../../domain/entities/classroom_entity.dart';
import '../../../../../screens/class_management/teams_channel_screen.dart';
import '../../../../../models/classroom.dart';

/// Dashboard screen for students.
///
/// Displays a responsive grid of joined classrooms and provides a
/// "Join Class" button that opens an inline join dialog.
/// Reads classroom state from [ClassroomNotifier] via [context.watch] —
/// no prop drilling required.
class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({
    super.key,
    required this.currentThemeMode,
    required this.onThemeToggle,
    required this.notifications,
    required this.onLogout,
  });

  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;
  final List<ClassNotification> notifications;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ClassroomNotifier>();
    final classrooms = notifier.classrooms;
    final availableTeams = classrooms
        .map((c) => c.name)
        .toList(growable: false);

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top App Bar area
        Row(
          children: [
            Expanded(
              child: SearchBar(
                leading: const Icon(Icons.search, color: AppColors.outline),
                hintText: 'Search classes, students, or resources...',
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
                onPressed: () => _openJoinDialog(context),
                icon: const Icon(Icons.login),
                label: const Text('Join Class'),
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
          'Welcome back, Student',
          style: AppTextStyles.displayLarge.copyWith(
            color: isLight ? AppColors.onSurface : Colors.white,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'You have ${classrooms.length} active classes for this semester.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: isLight
                ? AppColors.onSurfaceVariant
                : AppColors.outlineVariant,
          ),
        ),
        const SizedBox(height: AppSizes.xl),
        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {},
            child: notifier.isLoading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 240),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : classrooms.isEmpty
                ? const _EmptyState(
                    message:
                        'Bạn chưa tham gia lớp học nào.\nNhấn "Tham gia lớp" để nhập mã lớp.',
                  )
                : _ClassroomGrid(
                    classrooms: classrooms,
                    availableTeams: availableTeams,
                    currentThemeMode: currentThemeMode,
                    onThemeToggle: onThemeToggle,
                  ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Join dialog (inline, no navigation to a new screen)
  // ---------------------------------------------------------------------------

  Future<void> _openJoinDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _JoinClassDialog(notifications: notifications),
    );
  }
}

// ---------------------------------------------------------------------------
// Join dialog widget
// ---------------------------------------------------------------------------

class _JoinClassDialog extends StatefulWidget {
  const _JoinClassDialog({required this.notifications});
  final List<ClassNotification> notifications;

  @override
  State<_JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<_JoinClassDialog> {
  final _codeCtrl = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã lớp.')));
      return;
    }

    setState(() => _isJoining = true);

    try {
      final joined = await context.read<ClassroomNotifier>().joinClassroom(
        code,
      );
      if (!mounted) return;
      _codeCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tham gia lớp "${joined.name}" thành công.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tham gia lớp học'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập mã lớp học do giáo viên cung cấp để tham gia.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Ô nhập mã lớp học',
              child: TextField(
                controller: _codeCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Mã lớp',
                  hintText: 'Ví dụ: A1B2C3',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _handleJoin(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        Semantics(
          label: 'Xác nhận tham gia lớp học',
          child: FilledButton.icon(
            onPressed: _isJoining ? null : _handleJoin,
            icon: _isJoining
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(_isJoining ? 'Đang tham gia...' : 'Tham gia'),
          ),
        ),
      ],
    );
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
  });

  final List<ClassroomEntity> classrooms;
  final List<String> availableTeams;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;

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
        return StudentClassroomCardWidget(
          classroom: classroom,
          onTap: () => _openClassroomChannel(context, classroom),
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
          availableClasses: classrooms
              .map((c) => Classroom(id: c.id, name: c.name))
              .toList(growable: false),
          isTeacher: false,
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

enum _HeaderMenuAction { toggleTheme, logout }
