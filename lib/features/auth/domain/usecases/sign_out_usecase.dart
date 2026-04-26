import '../repositories/auth_repository.dart';

/// Use-case: sign out the current user and clear the local session.
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the sign-out flow.
  Future<void> call() {
    return _repository.signOut();
  }
}
