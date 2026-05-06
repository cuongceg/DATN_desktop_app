class MessageModel {
  final String id;
  final String sessionId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id:          json['id'] as String,
    sessionId:   json['session_id'] as String,
    senderId:    json['sender_id'] as String,
    senderName:  json['sender_name'] as String? ?? 'Unknown',
    content:     json['content'] as String,
    timestamp:   DateTime.parse(json['timestamp'] as String),
  );
}
