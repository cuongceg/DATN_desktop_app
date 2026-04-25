class ClassMember {
  const ClassMember({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.permission,
    this.joinedAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String permission;
  final DateTime? joinedAt;

  factory ClassMember.fromJson(Map<String, dynamic> json) {
    return ClassMember(
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

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'role': role,
      'permission': permission,
      'joined_at': joinedAt?.toIso8601String(),
    };
  }

  ClassMember copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? role,
    String? permission,
    DateTime? joinedAt,
  }) {
    return ClassMember(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      permission: permission ?? this.permission,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
