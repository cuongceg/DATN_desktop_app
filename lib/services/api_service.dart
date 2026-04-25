import 'package:dio/dio.dart';

import '../models/class_details.dart';
import '../models/class_member.dart';
import '../models/class_model.dart';
import '../models/user.dart';
import 'api_client.dart';
import 'auth_storage.dart';

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final User user;
}

class EducationApiService {
  EducationApiService({
    required ApiClient apiClient,
    required AuthStorage storage,
  }) : _dio = apiClient.dio,
       _storage = storage;

  final Dio _dio;
  final AuthStorage _storage;

  Future<AuthResponse> login({
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
        throw const ApiException(message: 'Token is missing from response.');
      }
      final user = User.fromJson(userJson);
      await _storage.saveToken(token);
      await _storage.saveUser(user);
      return AuthResponse(token: token, user: user);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> register({
    required String role,
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'role': role,
          'full_name': fullName,
          'email': email,
          'password': password,
        },
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<List<ClassModel>> getClasses() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/classes');
      final classesRaw =
          response.data?['classes'] as List<dynamic>? ?? const [];
      return classesRaw
          .whereType<Map<String, dynamic>>()
          .map(ClassModel.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<List<ClassModel>> getTeacherClasses() {
    return getClasses();
  }

  Future<ClassModel> createClass({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/classes',
        data: {'name': name, 'description': description},
      );
      final classJson =
          response.data?['class'] as Map<String, dynamic>? ?? const {};
      return ClassModel.fromJson(classJson);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<ClassModel> updateClass({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) {
        payload['name'] = name;
      }
      if (description != null) {
        payload['description'] = description;
      }
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/classes/$id',
        data: payload,
      );
      final classJson =
          response.data?['class'] as Map<String, dynamic>? ?? const {};
      return ClassModel.fromJson(classJson);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<ClassDetails> fetchClassDetails({required String id}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/classes/$id');
      final data = response.data ?? const <String, dynamic>{};
      return ClassDetails.fromJson(data);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<ClassModel> updateClassInfo({
    required String id,
    String? name,
    String? description,
  }) {
    return updateClass(id: id, name: name, description: description);
  }

  Future<void> deleteClass(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/api/classes/$id');
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<ClassModel> joinClass(String classCode) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/classes/join',
        data: {'class_code': classCode},
      );
      final classJson =
          response.data?['class'] as Map<String, dynamic>? ?? const {};
      return ClassModel.fromJson(classJson);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> addStudentToClass({
    required String classId,
    required String studentId,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/classes/$classId/members',
        data: {'student_id': studentId},
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<List<User>> searchUsers({required String keyword}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/users/search',
        queryParameters: {'query': keyword},
      );
      final usersRaw = response.data?['users'] as List<dynamic>? ?? const [];
      return usersRaw
          .whereType<Map<String, dynamic>>()
          .map(User.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<ClassMember> addMember({
    required String classId,
    required String userId,
    String permission = 'Member',
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/classes/$classId/members',
        data: {'student_id': userId, 'permission': permission},
      );
      final membership =
          response.data?['membership'] as Map<String, dynamic>? ?? const {};
      return ClassMember.fromJson(membership);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<ClassMember> updateMemberRole({
    required String classId,
    required String userId,
    required String role,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/classes/$classId/members/$userId/role',
        data: {'role': role},
      );
      final membership =
          response.data?['membership'] as Map<String, dynamic>? ?? const {};
      return ClassMember.fromJson(membership);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> removeMember({
    required String classId,
    required String userId,
  }) async {
    try {
      await _dio.delete<Map<String, dynamic>>(
        '/api/classes/$classId/members/$userId',
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> addMembersToClassBulk({
    required String classId,
    required List<String> studentIds,
    String permission = 'Member',
  }) async {
    if (studentIds.isEmpty) {
      return;
    }

    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/classes/$classId/members/bulk',
        data: {
          'members': studentIds
              .map(
                (studentId) => {
                  'student_id': studentId,
                  'permission': permission,
                },
              )
              .toList(growable: false),
        },
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  ApiException _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return ApiException(message: message, statusCode: statusCode);
      }
    }
    return ApiException(
      message: error.message ?? 'Unexpected network error.',
      statusCode: statusCode,
    );
  }
}
