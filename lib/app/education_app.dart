import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../features/auth/presentation/controllers/auth_notifier.dart';
import '../models/class_details.dart';
import '../models/class_member.dart';
import '../models/class_model.dart';
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
  bool _isLoadingClasses = false;
  List<ClassModel> _classes = const [];
  final List<ClassNotification> _notifications = [];

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
    // Safe: context.read does not listen, but addListener requires removal.
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
      if (mounted) {
        setState(() {
          _classes = const [];
          _notifications.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();

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
              classrooms: _classes,
              notifications: _notifications,
              isLoadingClasses: _isLoadingClasses,
              onRefreshClasses: _refreshClassrooms,
              onCreateClass: _createClass,
              onSearchUsers: _searchUsers,
              onAddMembersToClass: _addMembersToClass,
              onUpdateClass: _updateClass,
              onFetchClassDetails: _fetchClassDetails,
              onAddMember: _addMember,
              onUpdateMemberRole: _updateMemberRole,
              onRemoveMember: _removeMember,
              onDeleteClass: _deleteClass,
              onJoinClass: _joinClass,
              onLogout: _logout,
              onToggleTheme: _toggleTheme,
            ),
    );
  }

  bool _isTeacher(AuthNotifier auth) {
    return auth.currentUser?.role.toLowerCase() == 'teacher';
  }

  Future<void> _refreshClassrooms() async {
    if (!mounted) return;
    setState(() => _isLoadingClasses = true);
    try {
      final classes = await _apiService.getClasses();
      if (mounted) setState(() => _classes = classes);
    } finally {
      if (mounted) setState(() => _isLoadingClasses = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthNotifier>().signOut();
  }

  Future<ClassModel> _createClass({
    required String name,
    String? description,
  }) async {
    final created = await _apiService.createClass(
      name: name,
      description: description,
    );
    setState(() => _classes = [created, ..._classes]);
    return created;
  }

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

  Future<ClassModel> _updateClass({
    required ClassModel classModel,
    required String name,
    String? description,
  }) async {
    final updated = await _apiService.updateClass(
      id: classModel.id,
      name: name,
      description: description,
    );
    setState(() {
      _classes = _classes
          .map((item) => item.id == updated.id ? updated : item)
          .toList(growable: false);
    });
    return updated;
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

  Future<void> _deleteClass(ClassModel classModel) async {
    await _apiService.deleteClass(classModel.id);
    setState(() {
      _classes = _classes.where((item) => item.id != classModel.id).toList();
    });
  }

  Future<ClassModel?> _joinClass(String classCode) async {
    final joinedClass = await _apiService.joinClass(classCode);
    setState(() {
      final alreadyExists = _classes.any((item) => item.id == joinedClass.id);
      if (!alreadyExists) {
        _classes = [joinedClass, ..._classes];
      }
      _notifications.insert(
        0,
        ClassNotification(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          message: 'You were added to class ${joinedClass.name}.',
          createdAt: DateTime.now(),
        ),
      );
    });
    return joinedClass;
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }
}
