/// Trạng thái của một buổi học (session).
enum SessionStatus { scheduled, ongoing, completed }

/// Model đại diện cho một session.
///
/// Dùng cho cả danh sách session và calendar scheduling.
class SessionModel {
  final String id;
  final String classId;

  /// Tên lớp (chỉ có ở một số endpoint như `GET /api/sessions/my`).
  final String? className;
  final String title;
  final SessionStatus status;
  final String? livekitRoomId;

  /// Thời gian bắt đầu dự kiến (teacher đặt khi lên lịch).
  final DateTime? scheduledAt;

  /// Thời gian kết thúc dự kiến (teacher đặt khi lên lịch).
  final DateTime? scheduledEndAt;

  final DateTime? startTime;
  final DateTime? endTime;

  const SessionModel({
    required this.id,
    required this.classId,
    this.className,
    required this.title,
    required this.status,
    this.livekitRoomId,
    this.scheduledAt,
    this.scheduledEndAt,
    this.startTime,
    this.endTime,
  });

  /// `true` nếu session đang ở trạng thái có thể chỉnh sửa (chưa diễn ra).
  bool get isEditable => status == SessionStatus.scheduled;

  /// `true` nếu session đang diễn ra.
  bool get isOngoing => status == SessionStatus.ongoing;

  /// `true` nếu session đã kết thúc.
  bool get isCompleted => status == SessionStatus.completed;

  /// Thời gian bắt đầu dùng để hiển thị trên calendar.
  ///
  /// Ưu tiên `scheduledAt`, fallback về `startTime`.
  DateTime? get displayTime => scheduledAt ?? startTime;

  /// Thời gian kết thúc dùng để hiển thị trên calendar.
  ///
  /// Ưu tiên `scheduledEndAt`, fallback về `endTime`.
  DateTime? get displayEndTime => scheduledEndAt ?? endTime;

  /// Parse session từ JSON.
  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    id: json['id'] as String,
    classId: json['class_id'] as String,
    className: json['class_name'] as String?,
    title: json['title'] as String,
    status: SessionStatus.values.byName(json['status'] as String),
    livekitRoomId: json['livekit_room_id'] as String?,
    scheduledAt: json['scheduled_at'] != null
        ? DateTime.parse(json['scheduled_at'] as String).toLocal()
        : null,
    scheduledEndAt: json['scheduled_end_at'] != null
        ? DateTime.parse(json['scheduled_end_at'] as String).toLocal()
        : null,
    startTime: json['start_time'] != null
        ? DateTime.parse(json['start_time'] as String).toLocal()
        : null,
    endTime: json['end_time'] != null
        ? DateTime.parse(json['end_time'] as String).toLocal()
        : null,
  );

  /// Tạo bản sao có cập nhật một số field.
  SessionModel copyWith({
    String? id,
    String? classId,
    String? className,
    String? title,
    SessionStatus? status,
    String? livekitRoomId,
    DateTime? scheduledAt,
    DateTime? scheduledEndAt,
    DateTime? startTime,
    DateTime? endTime,
  }) => SessionModel(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    className: className ?? this.className,
    title: title ?? this.title,
    status: status ?? this.status,
    livekitRoomId: livekitRoomId ?? this.livekitRoomId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    scheduledEndAt: scheduledEndAt ?? this.scheduledEndAt,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
  );
}
