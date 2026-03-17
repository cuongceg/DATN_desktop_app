enum MessageSender { user, deai }

class ChatMessage {
  final MessageSender sender;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.sender,
    required this.text,
    required this.createdAt,
  });
}
