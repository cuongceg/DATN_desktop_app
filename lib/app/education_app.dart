import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/controllers/auth_notifier.dart';
import '../features/classroom/presentation/controllers/classroom_notifier.dart';
import '../models/class_details.dart';
import '../models/class_member.dart';
import '../models/class_notification.dart';
import '../models/user.dart';
import '../screens/home/home_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../theme/app_theme.dart';

class EducationDesktopApp extends StatefulWidget {
  const EducationDesktopApp({
    super.key,
    required this.authStorage,
    required this.apiClient,
  });

  final AuthStorage authStorage;
  final ApiClient apiClient;

  @override
  State<EducationDesktopApp> createState() => _EducationDesktopAppState();
}

class _EducationDesktopAppState extends State<EducationDesktopApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final List<ClassNotification> _notifications = [];

  // Legacy service kept for non-classroom operations that are not yet
  // migrated: searchUsers, member management, class details.
  // REFACTOR: Remove in REFACTOR-003 when those are also feature-ified.
  late final EducationApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = EducationApiService(
      apiClient: widget.apiClient,
      storage: widget.authStorage,
    );

    // Restore session and listen for auth changes to refresh classrooms.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthNotifier>();
      auth.addListener(_onAuthChanged);
      auth.tryRestoreSession();
    });
  }

  @override
  void dispose() {
    // ignore: invalid_use_of_protected_member
    context.read<AuthNotifier>().removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Called whenever [AuthNotifier] notifies. Refreshes classrooms on login.
  void _onAuthChanged() {
    final auth = context.read<AuthNotifier>();
    if (auth.isAuthenticated) {
      _refreshClassrooms();
    } else {
      // User signed out — clear classroom data.
      context.read<ClassroomNotifier>().clear();
      if (mounted) {
        setState(() {
          _notifications.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    // Watch ClassroomNotifier so the loading spinner in child screens rebuilds.
    context.watch<ClassroomNotifier>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Education Desktop UI',
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home: auth.isRestoringSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.currentUser == null
          ? LoginScreen(themeMode: _themeMode, onToggleTheme: _toggleTheme)
          : HomeScreen(
              isTeacher: _isTeacher(auth),
              notifications: _notifications,
              onSearchUsers: _searchUsers,
              onAddMembersToClass: _addMembersToClass,
              onFetchClassDetails: _fetchClassDetails,
              onAddMember: _addMember,
              onUpdateMemberRole: _updateMemberRole,
              onRemoveMember: _removeMember,
              onLogout: _logout,
              onToggleTheme: _toggleTheme,
            ),
    );
  }

  bool _isTeacher(AuthNotifier auth) {
    return auth.currentUser?.role.toLowerCase() == 'teacher';
  }

  // ---------------------------------------------------------------------------
  // Classroom actions — delegate to ClassroomNotifier
  // ---------------------------------------------------------------------------

  Future<void> _refreshClassrooms() async {
    final auth = context.read<AuthNotifier>();
    final userId = auth.currentUser?.id ?? '';
    await context.read<ClassroomNotifier>().loadClassrooms(userId);
  }

  Future<void> _logout() async {
    await context.read<AuthNotifier>().signOut();
  }


  // ---------------------------------------------------------------------------
  // Legacy operations still using EducationApiService (out of scope for
  // REFACTOR-002): user search, member management, class details.
  // ---------------------------------------------------------------------------

  Future<List<User>> _searchUsers(String keyword) async {
    final auth = context.read<AuthNotifier>();
    final users = await _apiService.searchUsers(keyword: keyword);
    return users
        .where((u) => u.role.toLowerCase() != 'admin')
        .where((u) => u.id != auth.currentUser?.id)
        .toList(growable: false);
  }

  Future<void> _addMembersToClass({
    required String classId,
    required List<String> studentIds,
  }) {
    return _apiService.addMembersToClassBulk(
      classId: classId,
      studentIds: studentIds,
    );
  }

  Future<ClassDetails> _fetchClassDetails(String classId) {
    return _apiService.fetchClassDetails(id: classId);
  }

  Future<ClassMember> _addMember({
    required String classId,
    required String userId,
    String permission = 'Member',
  }) {
    return _apiService.addMember(
      classId: classId,
      userId: userId,
      permission: permission,
    );
  }

  Future<ClassMember> _updateMemberRole({
    required String classId,
    required String userId,
    required String role,
  }) {
    return _apiService.updateMemberRole(
      classId: classId,
      userId: userId,
      role: role,
    );
  }

  Future<void> _removeMember({
    required String classId,
    required String userId,
  }) {
    return _apiService.removeMember(classId: classId, userId: userId);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }
}
