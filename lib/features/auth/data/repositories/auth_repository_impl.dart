import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Concrete implementation of [AuthRepository].
///
/// Coordinates between [AuthRemoteDataSource] (API) and
/// [AuthLocalDataSource] (secure storage).
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final (:token, :user) = await _remote.signIn(
      email: email,
      password: password,
    );
    await _local.saveToken(token);
    await _local.saveUser(user);
    return user;
  }

  @override
  Future<void> signOut() {
    return _local.clearSession();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await _local.readToken();
    if (token == null || token.isEmpty) return null;
    return _local.readUser();
  }
}
