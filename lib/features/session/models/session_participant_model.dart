class SessionParticipantModel {
  final String userId;
  final String fullName;
  final String role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isOnline;

  const SessionParticipantModel({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    required this.isOnline,
  });

  factory SessionParticipantModel.fromJson(Map<String, dynamic> json) =>
      SessionParticipantModel(
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
        joinedAt: DateTime.parse(json['joined_at'] as String).toLocal(),
        leftAt: json['left_at'] != null
            ? DateTime.parse(json['left_at'] as String).toLocal()
            : null,
        isOnline: json['is_online'] as bool,
      );
}
