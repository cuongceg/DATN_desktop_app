import 'package:flutter/material.dart';

class ChatSidebar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClose;

  const ChatSidebar({super.key, required this.isDark, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      key: const ValueKey('chat_sidebar'), // RẤT QUAN TRỌNG CHO ANIMATEDSWITCHER
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Meeting chat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              InkWell(onTap: onClose, child: const Icon(Icons.close, size: 20)),
            ],
          ),
        ),
        
        // Chat List (Mock data giống hình)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildOtherMessage(
                name: 'Nguyen Van An 20220458',
                time: '10:27',
                isDark: isDark,
                messages: [
                  'Nhom da test xong luong dang nhap bang JWT tren localhost.',
                  'Can review them phan xu ly timeout cho token het han.',
                  'Em gui ban thiet ke API de ca nhom check.',
                ],
                attachment: _buildAttachmentBox(isDark),
              ),
              const SizedBox(height: 16),
              _buildMyMessage(
                name: 'Do Manh Cuong 20225172',
                time: '10:28',
                isDark: isDark,
                messages: [
                  'Tot, minh uu tien fix bug WebRTC mat ket noi sau 2 phut idle.',
                  'Ai phu trach module bao cao tien do sprint 3?',
                ],
              ),
              const SizedBox(height: 16),
              _buildOtherMessage(
                name: 'Tran Thi Bich 20223719',
                time: '10:29',
                isDark: isDark,
                messages: [
                  'Em dang cap nhat test case cho chuc nang chia se man hinh.',
                  'Toi nay em push branch feature/screen-share-test.',
                ],
              ),
              const SizedBox(height: 16),
              _buildMyMessage(
                name: 'Do Manh Cuong 20225172',
                time: '10:30',
                isDark: isDark,
                messages: [
                  'Ok, 16h review code tren meeting va chot tai lieu nop mon.',
                ],
              ),
            ],
          ),
        ),

        // Input Area
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
          ),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Nhap tin nhan hoc thuat IT',
                  hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_size, size: 18, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Icon(Icons.attach_file, size: 18, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Icon(Icons.emoji_emotions_outlined, size: 18, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Icon(Icons.gif_box_outlined, size: 18, color: theme.iconTheme.color),
                    ],
                  ),
                  Icon(Icons.send, size: 18, color: theme.iconTheme.color),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  // UI Tin nhắn của người khác
  Widget _buildOtherMessage({
    required String name,
    required String time,
    required List<String> messages,
    Widget? attachment,
    required bool isDark,
  }) {
    final bgColor = isDark ? const Color(0xFF3B3B3B) : Colors.grey.shade200;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.amber.shade700,
          child: Text(
            _getInitials(name),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 4),
              ...messages.map(
                (msg) => Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(msg, style: const TextStyle(fontSize: 13)),
                ),
              ),
              if (attachment != null)
                Padding(padding: const EdgeInsets.only(top: 4), child: attachment),
            ],
          ),
        ),
      ],
    );
  }

  // UI Tin nhắn của bản thân (căn phải, màu tím)
  Widget _buildMyMessage({
    required String name,
    required String time,
    required List<String> messages,
    required bool isDark,
  }) {
    final bgColor = isDark ? const Color(0xFF5B5FC7) : const Color(0xFFE8EBFA);
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        ...messages.map(
          (msg) => Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(msg, style: TextStyle(fontSize: 13, color: textColor)),
          ),
        ),
      ],
    );
  }

  // UI File đính kèm (giống file Word trong hình)
  Widget _buildAttachmentBox(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            color: Colors.blue.shade700,
            child: const Icon(Icons.description, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('De_cuong_do_an_WebRTC_v2.pdf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text('Cap nhat 10 phut truoc', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String fullName) {
    final nameOnly = fullName.replaceAll(RegExp(r'\\d'), '').trim();
    if (nameOnly.isEmpty) return '?';
    return nameOnly
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(1)
        .map((part) => part[0])
        .join()
        .toUpperCase();
  }
}