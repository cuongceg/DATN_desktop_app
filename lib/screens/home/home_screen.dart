import 'package:flutter/material.dart';

import '../../models/class_details.dart';
import '../../models/class_member.dart';
import '../../models/class_model.dart';
import '../../models/class_notification.dart';
import '../../models/user.dart';
import '../calendar/calendar_screen.dart';
import '../class_management/class_management_screen.dart';
import '../../widgets/sidebar_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isTeacher,
    required this.classrooms,
    required this.notifications,
    required this.isLoadingClasses,
    required this.onRefreshClasses,
    required this.onCreateClass,
    required this.onSearchUsers,
    required this.onAddMembersToClass,
    required this.onUpdateClass,
    required this.onFetchClassDetails,
    required this.onAddMember,
    required this.onUpdateMemberRole,
    required this.onRemoveMember,
    required this.onDeleteClass,
    required this.onJoinClass,
    required this.onLogout,
    required this.onToggleTheme,
  });

  final bool isTeacher;
  final List<ClassModel> classrooms;
  final List<ClassNotification> notifications;
  final bool isLoadingClasses;
  final Future<void> Function() onRefreshClasses;
  final Future<ClassModel> Function({required String name, String? description})
  onCreateClass;
  final Future<List<User>> Function(String keyword) onSearchUsers;
  final Future<void> Function({
    required String classId,
    required List<String> studentIds,
  })
  onAddMembersToClass;
  final Future<ClassModel> Function({
    required ClassModel classModel,
    required String name,
    String? description,
  })
  onUpdateClass;
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
  final Future<void> Function(ClassModel classModel) onDeleteClass;
  final Future<ClassModel?> Function(String classId) onJoinClass;
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
                setState(() {
                  _selectedNav = index;
                });
              },
            ),
            Expanded(
              child: Container(
                color: scheme.surface,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeaderArea(
                      onToggleTheme: widget.onToggleTheme,
                      onLogout: widget.onLogout,
                    ),
                    const SizedBox(height: 20),
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
        return const _CenterTextScreen(text: 'Notifications');
      case 1:
        return ClassManagementScreen(
          isTeacher: widget.isTeacher,
          classrooms: widget.classrooms,
          notifications: widget.notifications,
          isLoading: widget.isLoadingClasses,
          onRefresh: widget.onRefreshClasses,
          onCreateClass: widget.onCreateClass,
          onSearchUsers: widget.onSearchUsers,
          onAddMembersToClass: widget.onAddMembersToClass,
          onUpdateClass: widget.onUpdateClass,
          onFetchClassDetails: widget.onFetchClassDetails,
          onAddMember: widget.onAddMember,
          onUpdateMemberRole: widget.onUpdateMemberRole,
          onRemoveMember: widget.onRemoveMember,
          onDeleteClass: widget.onDeleteClass,
          onJoinClass: widget.onJoinClass,
          currentThemeMode: currentThemeMode,
          onThemeToggle: _handleThemeModeChange,
        );
      case 2:
        return const CalendarDesktopScreen();
      case 3:
        return const _CenterTextScreen(text: 'Settings');
      default:
        return const SizedBox.shrink();
    }
  }
}

class _HeaderArea extends StatelessWidget {
  const _HeaderArea({required this.onToggleTheme, required this.onLogout});

  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final searchBackground = Theme.of(context).brightness == Brightness.light
        ? Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.04),
            scheme.surfaceContainerHighest,
          )
        : Color.alphaBlend(
            Colors.white.withValues(alpha: 0.06),
            scheme.surfaceContainerHighest,
          );

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: searchBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SearchBar(
                      leading: const Icon(Icons.search),
                      hintText: 'Search classes, students, assignments...',
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<_HeaderMenuAction>(
                tooltip: 'Account Options',
                onSelected: (action) {
                  if (action == _HeaderMenuAction.toggleTheme) {
                    onToggleTheme();
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
                      title: Text('Toggle Theme'),
                    ),
                  ),
                  PopupMenuItem<_HeaderMenuAction>(
                    value: _HeaderMenuAction.logout,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout_outlined),
                      title: Text('Logout'),
                    ),
                  ),
                ],
                child: const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person_outline),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

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

enum _HeaderMenuAction { toggleTheme, logout }
