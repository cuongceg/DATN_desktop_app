enum SessionStatus { scheduled, ongoing, completed }

class SessionModel {
  final String id;
  final String classId;
  final String title;
  final SessionStatus status;
  final String? livekitRoomId;
  final DateTime? startTime;
  final DateTime? endTime;

  const SessionModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.status,
    this.livekitRoomId,
    this.startTime,
    this.endTime,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    id:             json['id'] as String,
    classId:        json['class_id'] as String,
    title:          json['title'] as String,
    status:         SessionStatus.values.byName(json['status'] as String),
    livekitRoomId:  json['livekit_room_id'] as String?,
    startTime:      json['start_time'] != null
                      ? DateTime.parse(json['start_time'] as String) : null,
    endTime:        json['end_time'] != null
                      ? DateTime.parse(json['end_time'] as String) : null,
  );
}
