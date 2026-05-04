import 'package:flutter/material.dart';

import '../../features/classroom/presentation/screens/student_dashboard_screen.dart';
import '../../features/classroom/presentation/screens/teacher_dashboard_screen.dart';
import '../../models/class_details.dart';
import '../../models/class_member.dart';
import '../../models/class_notification.dart';
import '../../models/user.dart';
import '../calendar/calendar_screen.dart';
import '../../widgets/sidebar_navigation.dart';

/// Root shell screen that owns the sidebar navigation and routes to the
/// correct dashboard based on [isTeacher].
///
/// Classroom data is no longer prop-drilled here — [TeacherDashboardScreen]
/// and [StudentDashboardScreen] read directly from [ClassroomNotifier].
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isTeacher,
    required this.notifications,
    required this.onSearchUsers,
    required this.onAddMembersToClass,
    required this.onFetchClassDetails,
    required this.onAddMember,
    required this.onUpdateMemberRole,
    required this.onRemoveMember,
    required this.onLogout,
    required this.onToggleTheme,
  });

  final bool isTeacher;
  final List<ClassNotification> notifications;

  // Legacy member-management callbacks (still using EducationApiService).
  // Will be removed in REFACTOR-003 when member management is feature-ified.
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

  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNav = 1;

  void _handleThemeModeChange(ThemeMode desiredMode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if ((desiredMode == ThemeMode.dark && !isDark) ||
        (desiredMode == ThemeMode.light && isDark)) {
      widget.onToggleTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentThemeMode = Theme.of(context).brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SidebarNavigation(
              selectedIndex: _selectedNav,
              onDestinationSelected: (index) {
                setState(() => _selectedNav = index);
              },
            ),
            Expanded(
              child: Container(
                color: scheme.surface,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildBody(currentThemeMode: currentThemeMode),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required ThemeMode currentThemeMode}) {
    switch (_selectedNav) {
      case 0:
        return const _CenterTextScreen(text: 'Thông báo');
      case 1:
        // Route to role-specific dashboard — no if/else inside.
        return widget.isTeacher
            ? TeacherDashboardScreen(
                currentThemeMode: currentThemeMode,
                onThemeToggle: _handleThemeModeChange,
                onSearchUsers: widget.onSearchUsers,
                onAddMembersToClass: widget.onAddMembersToClass,
                onFetchClassDetails: widget.onFetchClassDetails,
                onAddMember: widget.onAddMember,
                onUpdateMemberRole: widget.onUpdateMemberRole,
                onRemoveMember: widget.onRemoveMember,
                onLogout: widget.onLogout,
              )
            : StudentDashboardScreen(
                currentThemeMode: currentThemeMode,
                onThemeToggle: _handleThemeModeChange,
                notifications: widget.notifications,
                onLogout: widget.onLogout,
              );
      case 2:
        return const CalendarDesktopScreen();
      case 3:
        return const _CenterTextScreen(text: 'Cài đặt');
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _CenterTextScreen extends StatelessWidget {
  const _CenterTextScreen({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
