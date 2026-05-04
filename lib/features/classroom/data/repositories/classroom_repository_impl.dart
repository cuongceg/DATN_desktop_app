import 'package:dio/dio.dart';

import '../../domain/entities/classroom_entity.dart';
import '../../domain/entities/classroom_member_entity.dart';
import '../../domain/repositories/classroom_repository.dart';
import '../datasources/classroom_remote_datasource.dart';

/// Concrete implementation of [ClassroomRepository].
///
/// Delegates all network calls to [ClassroomRemoteDatasource] and maps
/// [DioException]s to plain [Exception]s so the domain layer stays clean.
class ClassroomRepositoryImpl implements ClassroomRepository {
  const ClassroomRepositoryImpl(this._remote);

  final ClassroomRemoteDatasource _remote;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps a [DioException] to a descriptive [Exception].
  Exception _mapError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'] as String?;
      if (message != null && message.isNotEmpty) {
        return Exception('[$statusCode] $message');
      }
    }
    return Exception(error.message ?? 'Unexpected network error.');
  }

  // ---------------------------------------------------------------------------
  // ClassroomRepository implementation
  // ---------------------------------------------------------------------------

  @override
  Future<List<ClassroomEntity>> getClassrooms(String userId) async {
    try {
      return await _remote.getClassrooms();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ClassroomEntity> createClassroom({
    required String name,
    String? description,
  }) async {
    try {
      return await _remote.createClassroom(
        name: name,
        description: description,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ClassroomEntity> updateClassroom({
    required String id,
    required String name,
    String? description,
  }) async {
    try {
      return await _remote.updateClassroom(
        id: id,
        name: name,
        description: description,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> deleteClassroom(String id) async {
    try {
      await _remote.deleteClassroom(id);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ClassroomEntity> joinClassroom(String classCode) async {
    try {
      return await _remote.joinClassroom(classCode);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<(ClassroomEntity, List<ClassroomMemberEntity>)> fetchClassroomDetails(
    String classroomId,
  ) async {
    try {
      return await _remote.fetchClassroomDetails(classroomId);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ClassroomMemberEntity> addMember({
    required String classId,
    required String userId,
    String permission = 'Member',
  }) async {
    try {
      return await _remote.addMember(
        classId: classId,
        userId: userId,
        permission: permission,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> addMembersBulk({
    required String classId,
    required List<String> studentIds,
  }) async {
    try {
      await _remote.addMembersBulk(classId: classId, studentIds: studentIds);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<ClassroomMemberEntity> updateMemberRole({
    required String classId,
    required String userId,
    required String role,
  }) async {
    try {
      return await _remote.updateMemberRole(
        classId: classId,
        userId: userId,
        role: role,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  Future<void> removeMember({
    required String classId,
    required String userId,
  }) async {
    try {
      await _remote.removeMember(classId: classId, userId: userId);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }
}
