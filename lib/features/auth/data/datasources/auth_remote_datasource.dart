import 'package:dio/dio.dart';

import '../models/user_model.dart';

/// Exception thrown when an auth API call fails.
class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException($statusCode): $message';
}

/// Contract for remote authentication operations.
abstract class AuthRemoteDataSource {
  /// Calls the login endpoint and returns a token + [UserModel] pair.
  Future<({String token, UserModel user})> signIn({
    required String email,
    required String password,
  });
}

/// Concrete implementation using [Dio].
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<({String token, UserModel user})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data ?? const <String, dynamic>{};
      final token = data['token'] as String? ?? '';
      final userJson = data['user'] as Map<String, dynamic>? ?? const {};
      if (token.isEmpty) {
        throw const AuthException('Token is missing from response.');
      }
      return (token: token, user: UserModel.fromJson(userJson));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  AuthException _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final msg = responseData['message'] as String?;
      if (msg != null && msg.isNotEmpty) {
        return AuthException(msg, statusCode: statusCode);
      }
    }
    return AuthException(
      error.message ?? 'Unexpected network error.',
      statusCode: statusCode,
    );
  }
}
