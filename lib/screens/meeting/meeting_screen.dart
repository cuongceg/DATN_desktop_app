import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/screens/meeting/chat_sidebar.dart';
import 'package:flutter_web_rtc/widgets/app_react_button.dart';

enum SidebarType { none, people, chat }

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  // Biến điều khiển hiển thị Right Sidebar
  bool isSidebarVisible = true;
  SidebarType _currentSidebar = SidebarType.none;
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isSharingScreen = false;
  bool _isHandRaised = false;

  // Dữ liệu giả (Mock Data)
  final List<Map<String, dynamic>> mockParticipants = [
    {
      'name': 'Do Manh Cuong 20225172',
      'isMuted': true,
      'role': 'Organizer',
      'handRaised': false,
    },
    {
      'name': 'Nguyen Van An 20220458',
      'isMuted': false,
      'role': null,
      'handRaised': false,
    },
    {
      'name': 'Tran Thi Bich 20223719',
      'isMuted': true,
      'role': null,
      'handRaised': false,
    },
    {
      'name': 'Le Quoc Bao 20229831',
      'isMuted': false,
      'role': null,
      'handRaised': true,
    },
    {
      'name': 'Phan Minh Chau 20222647',
      'isMuted': true,
      'role': null,
      'handRaised': false,
    },
    {
      'name': 'Vo Duc Duy 20228905',
      'isMuted': false,
      'role': null,
      'handRaised': false,
    },
    {
      'name': 'Hoang Gia Han 20224563',
      'isMuted': true,
      'role': null,
      'handRaised': false,
    },
    {
      'name': 'Bui Tuan Kiet 20227314',
      'isMuted': false,
      'role': null,
      'handRaised': false,
    },
    {
      'name': 'Dang Thu Linh 20221239',
      'isMuted': true,
      'role': null,
      'handRaised': false,
    },
    {
      'name': 'Pham Nhat Nam 20226788',
      'isMuted': true,
      'role': null,
      'handRaised': false,
    },
  ];

  void _toggleSidebar(SidebarType type) {
    setState(() {
      if (_currentSidebar == type) {
        _currentSidebar = SidebarType.none;
      } else {
        _currentSidebar = type;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    isSidebarVisible = screenWidth > 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          _buildTopBar(theme, isDark),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildVideoGrid(theme, isDark)),
                // Right Sidebar
                if (isSidebarVisible)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    width: _currentSidebar == SidebarType.none ? 0 : 320,
                    child: ClipRect(
                      child: OverflowBox(
                        minWidth: 320,
                        maxWidth: 320,
                        alignment: Alignment
                            .centerLeft, // neo nội dung bên trái để trượt mượt mà
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            border: Border(
                              left: BorderSide(
                                color: theme.dividerColor,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _buildSidebarContent(theme, isDark),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Tiêu đề
          Text(
            'Weekly Sync Meeting',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Trái: Thời gian & Các avatar thu nhỏ
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text('00:22:06', style: theme.textTheme.labelMedium),
                ],
              ),
              // Phải: Các nút điều khiển
              Row(
                children: [
                  ControlIconButton(
                    icon: Icons.people_alt_outlined,
                    label: 'People',
                    onPressed: () => _toggleSidebar(SidebarType.people),
                  ),
                  ControlIconButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    onPressed: () => _toggleSidebar(SidebarType.chat),
                  ),
                  AppReactButton(
                    tooltip: 'React',
                    itemSize: Size(40, 40),
                    onReactionChanged: (reaction) => print(reaction?.value), // Không cần xử lý phản ứng trong demo
                  ),
                  ControlIconButton(
                    icon: _isHandRaised
                        ? Icons.back_hand
                        : Icons.back_hand_outlined,
                    label: 'Raise Hand',
                    onPressed: () =>
                        setState(() => _isHandRaised = !_isHandRaised),
                    color: _isHandRaised ? Colors.amber : null,
                  ),
                  const SizedBox(width: 8),
                  ControlIconButton(
                    icon: _isMicOn ? Icons.mic_none : Icons.mic_off,
                    label: 'Mic',
                    onPressed: () => setState(() => _isMicOn = !_isMicOn),
                  ),
                  ControlIconButton(
                    icon: _isCameraOn
                        ? Icons.videocam_outlined
                        : Icons.videocam_off_outlined,
                    label: 'Camera',
                    onPressed: () => setState(() => _isCameraOn = !_isCameraOn),
                  ),
                  ControlIconButton(
                    icon: _isSharingScreen
                        ? Icons.stop_screen_share_outlined
                        : Icons.screen_share_outlined,
                    label: 'Share',
                    onPressed: () =>
                        setState(() => _isSharingScreen = !_isSharingScreen),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.call_end, size: 18),
                    label: const Text('Leave'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 16 / 9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: mockParticipants.length,
        itemBuilder: (context, index) {
          return VideoBox(participant: mockParticipants[index], isDark: isDark);
        },
      ),
    );
  }

  Widget _buildSidebarContent(ThemeData theme, bool isDark) {
    switch (_currentSidebar) {
      case SidebarType.people:
        return _buildPeopleSidebar(
          theme,
          isDark,
        ); // Widget danh sách người tham gia (code cũ)
      case SidebarType.chat:
        return ChatSidebar(
          isDark: isDark,
          onClose: () => _toggleSidebar(SidebarType.none),
        ); // Widget Chat mới
      case SidebarType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPeopleSidebar(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('people_sidebar'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Participants',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => _toggleSidebar(SidebarType.none),
                child: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Invite someone or dial a number',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              suffixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.link, size: 18),
            label: const Text('Share invite'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'In the meeting (${mockParticipants.length})',
                style: theme.textTheme.labelLarge,
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Mute all',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: mockParticipants.length,
            itemBuilder: (context, index) {
              return ParticipantListTile(
                participant: mockParticipants[index],
                isDark: isDark,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Nút điều khiển chức năng ở thanh TopBar
class ControlIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const ControlIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
}

/// Khối Video hiển thị trong Grid chính (Mock bằng Avatar)
class VideoBox extends StatelessWidget {
  final Map<String, dynamic> participant;
  final bool isDark;

  const VideoBox({super.key, required this.participant, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name = participant['name'];
    final bool isMuted = participant['isMuted'];
    final bool handRaised = participant['handRaised'] ?? false;

    // Màu nền của ô video giả lập
    final boxColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0);

    return Container(
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Center(child: _buildLargeAvatar(name, isDark)),

          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (handRaised) ...[
                    const Icon(Icons.back_hand, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isMuted) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.mic_off, color: Colors.white70, size: 14),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeAvatar(String name, bool isDark) {
    String initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';
    Color bgColor = isDark ? Colors.grey.shade700 : Colors.grey.shade400;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return CircleAvatar(
      radius: 40,
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Item danh sách người tham gia ở Right Sidebar
class ParticipantListTile extends StatelessWidget {
  final Map<String, dynamic> participant;
  final bool isDark;

  const ParticipantListTile({
    super.key,
    required this.participant,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name = participant['name'];
    final bool isMuted = participant['isMuted'];
    final String? role = participant['role'];
    final bool handRaised = participant['handRaised'] ?? false;

    String initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';
    Color bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 0.0,
      ),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: bgColor,
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: theme.textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: role != null
          ? Text(
              role,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (handRaised)
            const Icon(Icons.back_hand, color: Colors.amber, size: 16),
          const SizedBox(width: 12),
          Icon(
            isMuted ? Icons.mic_off : Icons.mic,
            size: 18,
            color: isMuted ? theme.hintColor : theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
