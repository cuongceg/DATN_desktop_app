import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/glass_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../models/session_participant_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/meeting_room_provider.dart';
import '../../providers/session_provider.dart';

class ChatPanel extends StatefulWidget {
  final String sessionId;
  const ChatPanel({super.key, required this.sessionId});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Step 4 — resolve sender's full name from the participant list
  String _resolveName(
    String senderId,
    String currentUserId,
    List<SessionParticipantModel> participants,
  ) {
    if (senderId == currentUserId) return 'Tôi';
    try {
      return participants.firstWhere((p) => p.userId == senderId).fullName;
    } catch (_) {
      return 'Người dùng';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(ChatProvider chat) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await chat.sendMessage(text);
    _scrollToBottom();
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    // Step 3 — scope ChatProvider to this panel's lifetime
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(
        service: context.read<SessionProvider>().service,
        sessionId: widget.sessionId,
        currentUserId: context.read<AuthNotifier>().currentUser!.id,
      )
        ..loadMessages()
        ..startPolling(),
      child: Consumer<ChatProvider>(
        builder: (context, chat, _) {
          // Auto-scroll only when new messages arrive
          if (chat.messages.length > _lastMessageCount) {
            _lastMessageCount = chat.messages.length;
            _scrollToBottom();
          }

          // Step 4 — read participant list for name resolution
          final participants =
              context.read<MeetingRoomProvider>().sessionParticipants;

          return GlassCard(
            width: 320,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white24)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline),
                      SizedBox(width: 8),
                      Text(
                        'Chat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (chat.isLoading) const LinearProgressIndicator(minHeight: 2),
                // Message list
                Expanded(
                  child: chat.messages.isEmpty && !chat.isLoading
                      ? const Center(
                          child: Text(
                            'Chưa có tin nhắn nào.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: chat.messages.length,
                          itemBuilder: (_, index) {
                            final msg = chat.messages[index];
                            final isMe = msg.senderId == chat.currentUserId;
                            final senderName = _resolveName(
                              msg.senderId,
                              chat.currentUserId,
                              participants,
                            );

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? GlassTheme.accent.withValues(alpha: 0.8)
                                      : Colors.black45,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 2),
                                        child: Text(
                                          senderName,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      msg.content,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTime(msg.timestamp),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Error display
                if (chat.errorMessage != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      chat.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                // Input row
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final isDark = Theme.of(context).brightness == Brightness.dark;
                            return TextField(
                              controller: _textController,
                              enabled: !chat.isSending,
                              style: TextStyle(
                                color: isDark ? GlassTheme.darkText : GlassTheme.lightText,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                hintStyle: TextStyle(
                                  color: isDark ? GlassTheme.darkSubText : GlassTheme.lightSubText,
                                ),
                                filled: true,
                                fillColor: isDark ? GlassTheme.darkSurface : GlassTheme.lightSurface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: isDark ? GlassTheme.darkBorder : GlassTheme.lightBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(
                                    color: isDark ? GlassTheme.darkBorder : GlassTheme.lightBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: GlassTheme.accent),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              onSubmitted:
                                  chat.isSending ? null : (_) => _send(chat),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (chat.isSending)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.send, color: GlassTheme.accent),
                          onPressed: () => _send(chat),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
