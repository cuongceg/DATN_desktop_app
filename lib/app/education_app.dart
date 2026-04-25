import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/class_details.dart';
import '../models/class_member.dart';
import '../models/class_model.dart';
import '../models/class_notification.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../screens/home/home_screen.dart';
import '../screens/login/login_screen.dart';
import '../services/api_client.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../theme/app_theme.dart';

class EducationDesktopApp extends StatefulWidget {
  const EducationDesktopApp({super.key});

  @override
  State<EducationDesktopApp> createState() => _EducationDesktopAppState();
}

class _EducationDesktopAppState extends State<EducationDesktopApp> {
  ThemeMode _themeMode = ThemeMode.light;
  User? _currentUser;
  bool _isRestoringSession = true;
  bool _isLoadingClasses = false;
  List<ClassModel> _classes = const [];
  final List<ClassNotification> _notifications = [];

  late final AuthStorage _authStorage;
  late final EducationApiService _apiService;

  @override
  void initState() {
    super.initState();
    _authStorage = AuthStorage(const FlutterSecureStorage());
    _apiService = EducationApiService(
      apiClient: ApiClient(authStorage: _authStorage),
      storage: _authStorage,
    );
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Education Desktop UI',
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home: _isRestoringSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _currentUser == null
          ? LoginScreen(
              themeMode: _themeMode,
              onToggleTheme: _toggleTheme,
              onLogin: _handleLogin,
            )
          : HomeScreen(
              isTeacher: _isTeacher,
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

  Future<void> _restoreSession() async {
    try {
      final token = await _authStorage.readToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final cachedUser = await _authStorage.readUser();
      if (cachedUser == null) {
        await _apiService.logout();
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUser = cachedUser;
      });

      await _refreshClassrooms();
    } catch (_) {
      await _apiService.logout();
      if (mounted) {
        setState(() {
          _currentUser = null;
          _classes = const [];
          _notifications.clear();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoringSession = false;
        });
      }
    }
  }

  bool get _isTeacher {
    if (_currentUser == null) {
      return false;
    }
    return _currentUser!.role.toLowerCase() == UserRole.teacher.apiValue;
  }

  Future<void> _handleLogin({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    final result = await _apiService.login(email: email, password: password);
    final role = UserRoleX.fromApiValue(result.user.role);
    if (role != selectedRole) {
      await _apiService.logout();
      throw Exception(
        'Logged in as ${result.user.role}, but ${selectedRole.apiValue} was selected.',
      );
    }

    setState(() {
      _currentUser = result.user;
    });
    await _refreshClassrooms();
  }

  Future<void> _refreshClassrooms() async {
    if (_currentUser == null) {
      return;
    }

    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final classes = await _apiService.getClasses();
      setState(() {
        _classes = classes;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
      }
    }
  }

  Future<ClassModel> _createClass({
    required String name,
    String? description,
  }) async {
    final created = await _apiService.createClass(
      name: name,
      description: description,
    );
    setState(() {
      _classes = [created, ..._classes];
    });
    return created;
  }

  Future<List<User>> _searchUsers(String keyword) async {
    final users = await _apiService.searchUsers(keyword: keyword);
    final currentUserId = _currentUser?.id;
    return users
        .where((user) => user.role.toLowerCase() != 'admin')
        .where((user) => user.id != currentUserId)
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

  Future<void> _logout() async {
    await _apiService.logout();
    setState(() {
      _currentUser = null;
      _classes = const [];
      _notifications.clear();
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }
}
