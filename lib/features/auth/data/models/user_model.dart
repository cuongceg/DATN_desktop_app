import '../../domain/entities/user_entity.dart';

/// Data model for User — adds JSON serialization on top of [UserEntity].
///
/// Lives in the data layer only. Domain layer uses [UserEntity] directly.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.role,
    required super.fullName,
    required super.email,
  });

  /// Creates a [UserModel] from a JSON map returned by the API.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  /// Converts this model to a JSON map for local storage.
  Map<String, dynamic> toJson() {
    return {'id': id, 'role': role, 'full_name': fullName, 'email': email};
  }
}
