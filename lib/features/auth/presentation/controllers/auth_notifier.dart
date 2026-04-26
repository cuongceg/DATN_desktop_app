import 'package:flutter/foundation.dart';

import '../../../../models/user_role.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';

/// Manages authentication state for the entire application.
///
/// Consumed via [ChangeNotifierProvider] — screens call
/// `context.read<AuthNotifier>()` to trigger actions and
/// `context.watch<AuthNotifier>()` to rebuild on state changes.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier({
    required SignInUseCase signInUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _signIn = signInUseCase,
       _signOut = signOutUseCase,
       _getCurrentUser = getCurrentUserUseCase;

  final SignInUseCase _signIn;
  final SignOutUseCase _signOut;
  final GetCurrentUserUseCase _getCurrentUser;

  UserEntity? _currentUser;
  bool _isRestoringSession = true;
  bool _isLoading = false;
  String? _error;

  UserEntity? get currentUser => _currentUser;
  bool get isRestoringSession => _isRestoringSession;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Reads the cached session from secure storage. Call once on app start.
  Future<void> tryRestoreSession() async {
    try {
      _currentUser = await _getCurrentUser();
    } catch (_) {
      _currentUser = null;
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  /// Signs in with [email] and [password].
  ///
  /// Throws if credentials are wrong or [selectedRole] mismatches the
  /// server-returned role. Callers should catch and display the error.
  Future<void> signIn({
    required String email,
    required String password,
    required UserRole selectedRole,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _signIn(email: email, password: password);
      final serverRole = UserRoleX.fromApiValue(user.role);
      if (serverRole != selectedRole) {
        await _signOut();
        throw Exception(
          'Logged in as ${user.role}, but ${selectedRole.apiValue} was selected.',
        );
      }
      _currentUser = user;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs out and clears the local session.
  Future<void> signOut() async {
    await _signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }
}
