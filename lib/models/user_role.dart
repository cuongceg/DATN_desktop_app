enum UserRole { teacher, student }

extension UserRoleX on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
    }
  }

  static UserRole fromApiValue(String value) {
    switch (value.toLowerCase()) {
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      default:
        throw ArgumentError('Unsupported role: $value');
    }
  }
}
