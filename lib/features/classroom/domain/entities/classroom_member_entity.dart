/// Domain entity representing a member of a classroom.
///
/// Pure Dart — no Flutter or external dependencies.
class ClassroomMemberEntity {
  const ClassroomMemberEntity({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.permission,
    this.joinedAt,
  });

  /// Unique identifier of the user.
  final String userId;

  /// Full display name of the member.
  final String fullName;

  /// Email address of the member.
  final String email;

  /// Role within the system, e.g. "teacher" or "student".
  final String role;

  /// Permission level within this classroom, e.g. "Member".
  final String permission;

  /// When the member joined the classroom.
  final DateTime? joinedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassroomMemberEntity &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() =>
      'ClassroomMemberEntity(userId: $userId, fullName: $fullName, role: $role)';
}
