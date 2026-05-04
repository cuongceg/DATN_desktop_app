import 'package:dio/dio.dart';

import '../models/classroom_member_model.dart';
import '../models/classroom_model.dart';

/// Remote datasource for classroom-related API calls.
///
/// All HTTP communication for the classroom feature lives here.
/// This class depends directly on [Dio]; it is created and injected by
/// [ClassroomRepositoryImpl].
class ClassroomRemoteDatasource {
  const ClassroomRemoteDatasource(this._dio);

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Classrooms
  // ---------------------------------------------------------------------------

  /// Fetches all classrooms accessible to the authenticated user.
  ///
  /// Endpoint: `GET /api/classes`
  Future<List<ClassroomModel>> getClassrooms() async {
    final response = await _dio.get<Map<String, dynamic>>('/api/classes');
    final raw = response.data?['classes'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ClassroomModel.fromJson)
        .toList(growable: false);
  }

  /// Creates a new classroom.
  ///
  /// Endpoint: `POST /api/classes`
  Future<ClassroomModel> createClassroom({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/classes',
      data: <String, dynamic>{'name': name, 'description': description},
    );
    final classJson =
        response.data?['class'] as Map<String, dynamic>? ?? const {};
    return ClassroomModel.fromJson(classJson);
  }

  /// Updates the name and/or description of a classroom.
  ///
  /// Endpoint: `PUT /api/classes/{id}`
  Future<ClassroomModel> updateClassroom({
    required String id,
    String? name,
    String? description,
  }) async {
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (description != null) payload['description'] = description;

    final response = await _dio.put<Map<String, dynamic>>(
      '/api/classes/$id',
      data: payload,
    );
    final classJson =
        response.data?['class'] as Map<String, dynamic>? ?? const {};
    return ClassroomModel.fromJson(classJson);
  }

  /// Permanently deletes a classroom.
  ///
  /// Endpoint: `DELETE /api/classes/{id}`
  Future<void> deleteClassroom(String id) async {
    await _dio.delete<Map<String, dynamic>>('/api/classes/$id');
  }

  /// Joins a classroom using an invite code.
  ///
  /// Endpoint: `POST /api/classes/join`
  Future<ClassroomModel> joinClassroom(String classCode) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/classes/join',
      data: <String, dynamic>{'class_code': classCode},
    );
    final classJson =
        response.data?['class'] as Map<String, dynamic>? ?? const {};
    return ClassroomModel.fromJson(classJson);
  }

  // ---------------------------------------------------------------------------
  // Classroom Details & Members
  // ---------------------------------------------------------------------------

  /// Fetches full details of a classroom including its members.
  ///
  /// Endpoint: `GET /api/classes/{id}`
  Future<(ClassroomModel, List<ClassroomMemberModel>)> fetchClassroomDetails(
    String classroomId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/classes/$classroomId',
    );
    final data = response.data ?? const <String, dynamic>{};
    final classJson = data['class'] as Map<String, dynamic>? ?? const {};
    final membersRaw = data['members'] as List<dynamic>? ?? const [];

    final classroom = ClassroomModel.fromJson(classJson);
    final members = membersRaw
        .whereType<Map<String, dynamic>>()
        .map(ClassroomMemberModel.fromJson)
        .toList(growable: false);

    return (classroom, members);
  }

  /// Adds a single member to a classroom.
  ///
  /// Endpoint: `POST /api/classes/{classId}/members`
  Future<ClassroomMemberModel> addMember({
    required String classId,
    required String userId,
    String permission = 'Member',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/classes/$classId/members',
      data: <String, dynamic>{'student_id': userId, 'permission': permission},
    );
    final membership =
        response.data?['membership'] as Map<String, dynamic>? ?? const {};
    return ClassroomMemberModel.fromJson(membership);
  }

  /// Adds multiple members to a classroom in a single request.
  ///
  /// Endpoint: `POST /api/classes/{classId}/members/bulk`
  Future<void> addMembersBulk({
    required String classId,
    required List<String> studentIds,
    String permission = 'Member',
  }) async {
    if (studentIds.isEmpty) return;
    await _dio.post<Map<String, dynamic>>(
      '/api/classes/$classId/members/bulk',
      data: <String, dynamic>{
        'members': studentIds
            .map(
              (id) => <String, dynamic>{
                'student_id': id,
                'permission': permission,
              },
            )
            .toList(growable: false),
      },
    );
  }

  /// Updates the role of a member within a classroom.
  ///
  /// Endpoint: `PATCH /api/classes/{classId}/members/{userId}/role`
  Future<ClassroomMemberModel> updateMemberRole({
    required String classId,
    required String userId,
    required String role,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/api/classes/$classId/members/$userId/role',
      data: <String, dynamic>{'role': role},
    );
    final membership =
        response.data?['membership'] as Map<String, dynamic>? ?? const {};
    return ClassroomMemberModel.fromJson(membership);
  }

  /// Removes a member from a classroom.
  ///
  /// Endpoint: `DELETE /api/classes/{classId}/members/{userId}`
  Future<void> removeMember({
    required String classId,
    required String userId,
  }) async {
    await _dio.delete<Map<String, dynamic>>(
      '/api/classes/$classId/members/$userId',
    );
  }
}
