/// Domain entity representing a classroom.
///
/// Pure Dart — no Flutter or external dependencies.
class ClassroomEntity {
  const ClassroomEntity({
    required this.id,
    required this.name,
    required this.teacherId,
    this.classCode,
    this.description,
    this.createdAt,
    this.studentCount,
    this.status,
  });

  /// Unique identifier of the classroom.
  final String id;

  /// Display name of the classroom.
  final String name;

  /// User ID of the teacher who owns this classroom.
  final String teacherId;

  /// Invite code students use to join the classroom.
  final String? classCode;

  /// Optional description of the classroom.
  final String? description;

  /// When the classroom was created.
  final DateTime? createdAt;

  /// Cached count of enrolled students.
  final int? studentCount;

  /// The current status of the classroom.
  final String? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassroomEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClassroomEntity(id: $id, name: $name, teacherId: $teacherId)';
}
