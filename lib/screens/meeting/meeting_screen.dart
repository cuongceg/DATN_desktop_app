import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/screens/meeting/chat_sidebar.dart';

enum SidebarType { none, people, chat }

enum MeetingReaction { none, handRaised, understood, needHelp }

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key, required this.isTeacher});
  final bool isTeacher;

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
  bool _isEnglishSubtitleOn = false;
  MeetingReaction _myReaction = MeetingReaction.none;

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

  void _toggleMyReaction(MeetingReaction reaction) {
    setState(() {
      _myReaction = _myReaction == reaction ? MeetingReaction.none : reaction;
    });
  }

  IconData? _reactionIcon(MeetingReaction reaction) {
    switch (reaction) {
      case MeetingReaction.handRaised:
        return Icons.back_hand;
      case MeetingReaction.understood:
        return Icons.check_circle;
      case MeetingReaction.needHelp:
        return Icons.help;
      case MeetingReaction.none:
        return null;
    }
  }

  Color _reactionColor(MeetingReaction reaction) {
    switch (reaction) {
      case MeetingReaction.handRaised:
        return Colors.amber;
      case MeetingReaction.understood:
        return Colors.green;
      case MeetingReaction.needHelp:
        return Colors.redAccent;
      case MeetingReaction.none:
        return Colors.transparent;
    }
  }

  Widget _buildControlGroup(List<Widget> children) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildControlDivider(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 1,
      height: 24,
      color: theme.dividerColor.withOpacity(0.35),
    );
  }

  Widget _buildSubtitleMenuButton(ThemeData theme) {
    return PopupMenuButton<String>(
      tooltip: 'Subtitle settings',
      onSelected: (value) {
        setState(() {
          if (value == 'subtitle_on') {
            _isEnglishSubtitleOn = true;
          } else if (value == 'subtitle_off') {
            _isEnglishSubtitleOn = false;
          }
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'subtitle_on',
          child: Row(
            children: [
              const Icon(Icons.subtitles, size: 18),
              const SizedBox(width: 8),
              Text('English subtitles on', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'subtitle_off',
          child: Row(
            children: [
              const Icon(Icons.subtitles_off, size: 18),
              const SizedBox(width: 8),
              Text('English subtitles off', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
      child: ControlIconButton(
        icon: Icons.more_horiz,
        label: 'More',
        onPressed: () {},
        isActive: _isEnglishSubtitleOn,
      ),
    );
  }

  List<Widget> _buildTeacherControls(ThemeData theme) {
    final firstGroup = _buildControlGroup([
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
    ]);

    final secondGroup = _buildControlGroup([
      ControlIconButton(
        icon: _isMicOn ? Icons.mic_none : Icons.mic_off,
        label: 'Mic',
        onPressed: () => setState(() => _isMicOn = !_isMicOn),
      ),
      ControlIconButton(
        icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
        label: 'Camera',
        onPressed: () => setState(() => _isCameraOn = !_isCameraOn),
        color: _isCameraOn ? Colors.blue : Colors.red,
      ),
      ControlIconButton(
        icon: _isSharingScreen
            ? Icons.stop_screen_share_outlined
            : Icons.screen_share_outlined,
        label: 'Share',
        onPressed: () => setState(() => _isSharingScreen = !_isSharingScreen),
      ),
      const SizedBox(width: 8),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.call_end, size: 18),
        label: const Text('Leave'),
      ),
    ]);

    return [firstGroup, _buildControlDivider(theme), secondGroup];
  }

  List<Widget> _buildStudentControls(ThemeData theme) {
    final firstGroup = _buildControlGroup([
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
      _buildSubtitleMenuButton(theme),
    ]);

    final secondGroup = _buildControlGroup([
      ControlIconButton(
        icon: _myReaction == MeetingReaction.handRaised
            ? Icons.back_hand
            : Icons.back_hand_outlined,
        label: 'Raise Hand',
        onPressed: () => _toggleMyReaction(MeetingReaction.handRaised),
        color: Colors.amber,
        isActive: _myReaction == MeetingReaction.handRaised,
      ),
      ControlIconButton(
        icon: Icons.slow_motion_video,
        label: 'request slow',
        onPressed: () {},
        color: Colors.orange.shade700,
      ),
      ControlIconButton(
        icon: Icons.replay_outlined,
        label: 'request repeat',
        onPressed: () {},
        color: Colors.blue.shade700,
      ),
      ControlIconButton(
        icon: Icons.check_circle_outline,
        label: 'understood',
        onPressed: () => _toggleMyReaction(MeetingReaction.understood),
        color: Colors.green.shade700,
        isActive: _myReaction == MeetingReaction.understood,
      ),
      ControlIconButton(
        icon: Icons.help_outline,
        label: 'not clear',
        onPressed: () => _toggleMyReaction(MeetingReaction.needHelp),
        color: Colors.red.shade700,
        isActive: _myReaction == MeetingReaction.needHelp,
      ),
    ]);

    final thirdGroup = _buildControlGroup([
      ControlIconButton(
        icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
        label: 'Camera',
        onPressed: () => setState(() => _isCameraOn = !_isCameraOn),
        color: _isCameraOn ? Colors.blue : Colors.red,
      ),
      ControlIconButton(
        icon: _isSharingScreen
            ? Icons.stop_screen_share_outlined
            : Icons.screen_share_outlined,
        label: 'Share',
        onPressed: () => setState(() => _isSharingScreen = !_isSharingScreen),
      ),
      const SizedBox(width: 8),
      FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.call_end, size: 18),
        label: const Text('Leave'),
      ),
    ]);

    return [
      firstGroup,
      _buildControlDivider(theme),
      secondGroup,
      _buildControlDivider(theme),
      thirdGroup,
    ];
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
              Row(
                children: [
                  ...widget.isTeacher
                      ? _buildTeacherControls(theme)
                      : _buildStudentControls(theme),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(ThemeData theme, bool isDark) {
    final String currentUserName = mockParticipants.first['name'];

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
          final participant = mockParticipants[index];
          final bool isCurrentUser = participant['name'] == currentUserName;

          return VideoBox(
            participant: participant,
            isDark: isDark,
            statusIcon: isCurrentUser ? _reactionIcon(_myReaction) : null,
            statusColor: isCurrentUser ? _reactionColor(_myReaction) : null,
          );
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
    final String currentUserName = mockParticipants.first['name'];

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
              final participant = mockParticipants[index];
              final bool isCurrentUser = participant['name'] == currentUserName;

              return ParticipantListTile(
                participant: participant,
                isDark: isDark,
                statusIcon: isCurrentUser ? _reactionIcon(_myReaction) : null,
                statusColor: isCurrentUser ? _reactionColor(_myReaction) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Khối Video hiển thị trong Grid chính (Mock bằng Avatar)
class VideoBox extends StatelessWidget {
  final Map<String, dynamic> participant;
  final bool isDark;
  final IconData? statusIcon;
  final Color? statusColor;

  const VideoBox({
    super.key,
    required this.participant,
    required this.isDark,
    this.statusIcon,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name = participant['name'];
    final bool isMuted = participant['isMuted'];
    final bool handRaised = participant['handRaised'] ?? false;
    final IconData? displayedStatusIcon = handRaised && statusIcon == null
        ? Icons.back_hand
        : statusIcon;
    final Color displayedStatusColor = handRaised && statusIcon == null
        ? Colors.amber
        : (statusColor ?? Colors.white);

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
                  if (displayedStatusIcon != null) ...[
                    Icon(
                      displayedStatusIcon,
                      color: displayedStatusColor,
                      size: 14,
                    ),
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

class ControlIconButton extends StatelessWidget {
  final IconData icon;

  final String label;

  final VoidCallback onPressed;

  final Color? color;
  final bool isActive;

  const ControlIconButton({
    super.key,

    required this.icon,

    required this.label,

    required this.onPressed,

    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color baseColor = color ?? theme.colorScheme.onSurfaceVariant;
    final Color iconColor = isActive
        ? baseColor
        : theme.colorScheme.onSurfaceVariant.withOpacity(0.7);

    return Tooltip(
      message: label,

      child: Material(
        color: isActive ? baseColor.withOpacity(0.18) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isActive
                ? baseColor.withOpacity(0.55)
                : theme.dividerColor.withOpacity(0.35),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: iconColor),

          onPressed: onPressed,

          splashRadius: 20,
        ),
      ),
    );
  }
}

/// Item danh sách người tham gia ở Right Sidebar
class ParticipantListTile extends StatelessWidget {
  final Map<String, dynamic> participant;
  final bool isDark;
  final IconData? statusIcon;
  final Color? statusColor;

  const ParticipantListTile({
    super.key,
    required this.participant,
    required this.isDark,
    this.statusIcon,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name = participant['name'];
    final bool isMuted = participant['isMuted'];
    final String? role = participant['role'];
    final bool handRaised = participant['handRaised'] ?? false;
    final IconData? displayedStatusIcon = handRaised && statusIcon == null
        ? Icons.back_hand
        : statusIcon;
    final Color displayedStatusColor = handRaised && statusIcon == null
        ? Colors.amber
        : (statusColor ?? theme.hintColor);

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
          if (displayedStatusIcon != null)
            Icon(displayedStatusIcon, color: displayedStatusColor, size: 16),
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
