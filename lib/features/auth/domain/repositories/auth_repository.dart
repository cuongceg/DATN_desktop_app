import '../entities/user_entity.dart';

/// Abstract contract for authentication operations.
///
/// Pure Dart — do NOT import Flutter, Dio, or any data-layer package here.
/// The concrete implementation lives in `features/auth/data/repositories/`.
abstract class AuthRepository {
  /// Signs in with [email] and [password].
  ///
  /// Returns the authenticated [UserEntity] on success.
  /// Throws an exception on failure (wrong credentials, network error, etc.).
  Future<UserEntity> signIn({required String email, required String password});

  /// Signs out the current user and clears the stored session.
  Future<void> signOut();

  /// Returns the currently cached [UserEntity], or `null` if no session exists.
  Future<UserEntity?> getCurrentUser();
}
