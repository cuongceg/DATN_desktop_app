class PostModel {
  final String id;
  final String type; // 'normal' | 'session'
  final String? title;
  final Map<String, dynamic>? bodyDelta; // Quill Delta JSON: { "ops": [...] }
  final String? bodyPlain;
  final String authorId;
  final String authorName;
  final String? sessionId;
  final String? sessionTitle;
  final String? sessionStatus; // 'scheduled' | 'ongoing' | 'completed'
  final DateTime? sessionScheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.type,
    this.title,
    this.bodyDelta,
    this.bodyPlain,
    required this.authorId,
    required this.authorName,
    this.sessionId,
    this.sessionTitle,
    this.sessionStatus,
    this.sessionScheduledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String?,
    bodyDelta: json['body_delta'] as Map<String, dynamic>?,
    bodyPlain: json['body_plain'] as String?,
    authorId: json['author_id'] as String,
    authorName: json['author_name'] as String,
    sessionId: json['session_id'] as String?,
    sessionTitle: json['session_title'] as String?,
    sessionStatus: json['session_status'] as String?,
    sessionScheduledAt: json['session_scheduled_at'] != null
        ? DateTime.parse(json['session_scheduled_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
