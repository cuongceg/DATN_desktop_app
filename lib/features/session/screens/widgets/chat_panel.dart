import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../models/message_model.dart';

class ChatPanel extends StatefulWidget {
  final String sessionId;
  const ChatPanel({super.key, required this.sessionId});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  List<MessageModel> messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    // Mocking or fetching
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      messages.add(MessageModel(
        id: DateTime.now().toString(),
        sessionId: widget.sessionId,
        senderId: 'me',
        senderName: 'Tôi',
        content: text,
        timestamp: DateTime.now(),
      ));
    });
    _textController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      width: 320,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_bubble_outline),
                SizedBox(width: 8),
                Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == 'me'; // Hardcoded for demo
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? GlassTheme.accent.withOpacity(0.8) : Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!isMe)
                          Text(msg.senderName, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        Text(msg.content, style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: GlassTheme.accent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
