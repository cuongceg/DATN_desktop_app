class User {
  const User({
    required this.id,
    required this.role,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String role;
  final String fullName;
  final String email;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'email': email,
    };
  }
}
