/// Domain entity representing an authenticated user.
///
/// Pure Dart — do NOT import Flutter, Dio, or any data-layer package here.
class UserEntity {
  const UserEntity({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
  });

  /// Unique identifier of the user.
  final String id;

  /// Role string as returned by the API (e.g. "teacher", "student").
  final String role;

  /// Display name of the user.
  final String fullName;

  /// Email address of the user.
  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserEntity(id: $id, role: $role, fullName: $fullName, email: $email)';
}
