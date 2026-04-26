import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use-case: retrieve the currently cached authenticated user.
///
/// Returns `null` when no valid session exists (user not logged in or
/// session has been cleared).
class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  /// Returns the cached [UserEntity] or `null` if there is no active session.
  Future<UserEntity?> call() {
    return _repository.getCurrentUser();
  }
}
