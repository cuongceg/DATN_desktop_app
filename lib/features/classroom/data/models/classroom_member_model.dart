import '../../domain/entities/classroom_member_entity.dart';

/// Data model for a classroom member.
///
/// Handles JSON serialization/deserialization and maps to [ClassroomMemberEntity].
class ClassroomMemberModel extends ClassroomMemberEntity {
  const ClassroomMemberModel({
    required super.userId,
    required super.fullName,
    required super.email,
    required super.role,
    required super.permission,
    super.joinedAt,
  });

  /// Constructs a [ClassroomMemberModel] from a JSON map returned by the API.
  factory ClassroomMemberModel.fromJson(Map<String, dynamic> json) {
    return ClassroomMemberModel(
      userId: json['user_id'] as String? ?? json['student_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      permission: json['permission'] as String? ?? 'Member',
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'] as String)
          : null,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'permission': permission,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }
}
