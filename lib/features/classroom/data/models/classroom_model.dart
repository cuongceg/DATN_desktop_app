import '../../domain/entities/classroom_entity.dart';

/// Data model for a classroom.
///
/// Handles JSON serialization/deserialization and maps to [ClassroomEntity].
class ClassroomModel extends ClassroomEntity {
  const ClassroomModel({
    required super.id,
    required super.name,
    required super.teacherId,
    super.classCode,
    super.description,
    super.createdAt,
    super.studentCount,
  });

  /// Constructs a [ClassroomModel] from a JSON map returned by the API.
  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: json['id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      classCode: json['class_code'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      studentCount: json['student_count'] as int?,
    );
  }

  /// Converts this model to a JSON map for API requests.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'teacher_id': teacherId,
      'class_code': classCode,
      'name': name,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'student_count': studentCount,
    };
  }
}
