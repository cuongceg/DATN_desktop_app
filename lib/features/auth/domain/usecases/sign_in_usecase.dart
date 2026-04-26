import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use-case: sign in a user with email and password.
///
/// Delegates entirely to [AuthRepository]; contains no business logic beyond
/// the call itself so that future validation rules can be added here without
/// touching the repository or presentation layer.
class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  /// Executes the sign-in flow.
  ///
  /// [email] and [password] must be non-empty (UI layer is responsible for
  /// basic validation before calling this use-case).
  ///
  /// Returns the authenticated [UserEntity] or throws on failure.
  Future<UserEntity> call({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }
}
