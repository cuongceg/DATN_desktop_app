import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_rtc/screens/class_management/document_management_screen.dart';
import 'package:flutter_web_rtc/widgets/post_card.dart';
import 'package:flutter_web_rtc/widgets/message_composer.dart';
import '../../features/session/screens/join_screen.dart';
import '../../features/session/providers/session_provider.dart';

class TeamsChannelScreen extends StatefulWidget {
  const TeamsChannelScreen({
    super.key,
    required this.classId,
    required this.initialTeam,
    required this.isTeacher,
    required this.currentThemeMode,
    required this.onThemeToggle,
    this.availableTeams = const <String>[],
  });

  /// UUID của lớp học — dùng để gọi API tạo/join session.
  final String classId;
  final bool isTeacher;
  final String initialTeam;
  final List<String> availableTeams;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;

  @override
  State<TeamsChannelScreen> createState() => _TeamsChannelScreenState();
}

class _TeamsChannelScreenState extends State<TeamsChannelScreen> {
  late final List<String> _teams;
  late final List<PostCardData> _posts;
  final ScrollController _postsScrollController = ScrollController();
  late String _selectedTeam;
  bool _isComposerVisible = false;
  bool _showNewPostIndicator = false;
  bool _isMeetLoading = false;
  int? _editingPostIndex;
  String _composerInitialSubject = '';
  String _composerInitialBody = '';
  List<dynamic>? _composerInitialBodyDelta;

  @override
  void initState() {
    super.initState();
    _teams = _buildTeams(widget.initialTeam, widget.availableTeams);
    _posts = List<PostCardData>.of(PostCardSamples.posts, growable: true);
    _selectedTeam = widget.initialTeam;
  }

  @override
  void dispose() {
    _postsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final sidebarWidth = (constraints.maxWidth * 0.2).clamp(
              220.0,
              360.0,
            );

            return Row(
              children: [
                SizedBox(
                  width: sidebarWidth,
                  child: _buildTeamsSidebar(context),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, feedConstraints) {
                      final horizontalInset = (feedConstraints.maxWidth / 10)
                          .clamp(16.0, 140.0);

                      return TabBarView(
                        children: [
                          _buildPostsPane(horizontalInset),
                          DocumentManagementScreen(
                            currentThemeMode: widget.currentThemeMode,
                            onThemeToggle: widget.onThemeToggle,
                            embedded: true,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostsPane(double horizontalInset) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: horizontalInset,
            right: horizontalInset,
            top: 16,
            bottom: 16,
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _postsScrollController,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: _posts
                      .map(
                        (post) => PostCard(
                          post: post,
                          onModifyPost: _handleModifyPost,
                          onDeletePost: _handleDeletePost,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (_isComposerVisible)
                MessageComposer(
                  userName: 'Do Manh Cuong 20225172',
                  userInitials: 'DC',
                  initialSubject: _composerInitialSubject,
                  initialBody: _composerInitialBody,
                  initialBodyDelta: _composerInitialBodyDelta,
                  postButtonLabel: _editingPostIndex == null
                      ? 'Post'
                      : 'Update',
                  onClose: _closeComposer,
                  onPost: _handlePost,
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _openComposerForNewPost,
                    icon: const Icon(Icons.edit_sharp, size: 18),
                    label: const Text(
                      'Post in channel',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_showNewPostIndicator)
          Positioned(
            right: 20,
            bottom: 20,
            child: FilledButton.icon(
              onPressed: _scrollToLatestPost,
              icon: const Icon(Icons.keyboard_arrow_down),
              label: const Text('Have a new post in channel'),
            ),
          ),
      ],
    );
  }

  void _handlePost(String subject, String bodyPlain, List<dynamic> bodyDelta) {
    if (subject.isEmpty && bodyPlain.isEmpty) {
      return;
    }

    final postTitle = subject.isEmpty ? '(No subject)' : subject;
    final content = bodyPlain.isEmpty ? ' ' : bodyPlain;

    setState(() {
      if (_editingPostIndex != null && _editingPostIndex! < _posts.length) {
        final oldPost = _posts[_editingPostIndex!];
        _posts[_editingPostIndex!] = PostCardData(
          authorName: oldPost.authorName,
          authorInitials: oldPost.authorInitials,
          postedAt: oldPost.postedAt,
          title: postTitle,
          content: content,
          bodyDelta: bodyDelta,
          linkSummary: oldPost.linkSummary,
          linkDomain: oldPost.linkDomain,
          replyInitials: oldPost.replyInitials,
        );
      } else {
        _posts.insert(
          _posts.length,
          PostCardData(
            authorName: 'Do Manh Cuong 20225172',
            authorInitials: 'DC',
            postedAt: 'Now',
            title: postTitle,
            content: content,
            bodyDelta: bodyDelta,
            linkSummary: '',
            linkDomain: '',
            replyInitials: 'DC',
          ),
        );
        _showNewPostIndicator = true;
      }
      _isComposerVisible = false;
      _editingPostIndex = null;
      _composerInitialSubject = '';
      _composerInitialBody = '';
      _composerInitialBodyDelta = null;
    });
  }

  void _handleModifyPost(PostCardData post) {
    final index = _posts.indexOf(post);
    if (index == -1) {
      return;
    }
    setState(() {
      _editingPostIndex = index;
      _composerInitialSubject = post.title == '(No subject)' ? '' : post.title;
      _composerInitialBody = post.content.trim();
      _composerInitialBodyDelta = post.bodyDelta;
      _isComposerVisible = true;
      _showNewPostIndicator = false;
    });
  }

  void _handleDeletePost(PostCardData post) {
    final index = _posts.indexOf(post);
    if (index == -1) {
      return;
    }
    setState(() {
      _posts.removeAt(index);
      if (_editingPostIndex == index) {
        _isComposerVisible = false;
        _editingPostIndex = null;
        _composerInitialSubject = '';
        _composerInitialBody = '';
        _composerInitialBodyDelta = null;
      }
      if (_editingPostIndex != null && index < _editingPostIndex!) {
        _editingPostIndex = _editingPostIndex! - 1;
      }
    });
  }

  void _openComposerForNewPost() {
    setState(() {
      _editingPostIndex = null;
      _composerInitialSubject = '';
      _composerInitialBody = '';
      _composerInitialBodyDelta = null;
      _isComposerVisible = true;
    });
  }

  void _closeComposer() {
    setState(() {
      _isComposerVisible = false;
      _editingPostIndex = null;
      _composerInitialSubject = '';
      _composerInitialBody = '';
      _composerInitialBodyDelta = null;
    });
  }

  void _scrollToLatestPost() {
    if (!_postsScrollController.hasClients) {
      return;
    }

    _postsScrollController.animateTo(
      _postsScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );

    setState(() {
      _showNewPostIndicator = false;
    });
  }

  // ─── TASK-UI-20: classId hợp lệ từ widget (TASK-UI-20 đã done) ───────────────────────────

  /// Trả về classId UUID thật từ widget.classId.
  String _getCurrentClassId() => widget.classId;

  Future<void> _handleMeetNow(BuildContext context) async {
    setState(() => _isMeetLoading = true);
    final sessionProvider = context.read<SessionProvider>();
    final classId = _getCurrentClassId();

    try {
      // Bước 1: Tạo session mới
      final session = await sessionProvider.createSession(classId, 'Buổi học nhanh');
      if (session == null) {
        if (context.mounted) _showError(context, sessionProvider.errorMessage ?? 'Không thể tạo buổi học');
        return;
      }

      // Bước 2: Start session
      await sessionProvider.startSession(session.id);

      // Bước 3: Lấy token LiveKit
      final joinData = await sessionProvider.joinSession(session.id);
      if (joinData == null) {
        if (context.mounted) _showError(context, sessionProvider.errorMessage ?? 'Không lấy được token');
        return;
      }

      if (!context.mounted) return;

      // Bước 4: Navigate vào JoinScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JoinScreen(
            sessionId: session.id,
            livekitUrl: joinData.livekitUrl,
            token: joinData.token,
            sessionTitle: session.title,
            isTeacher: widget.isTeacher,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isMeetLoading = false);
    }
  }

  // ─── TASK-UI-16: Tạo cuộc họp sau ──────────────────────────────────────────

  Future<void> _handleScheduleMeeting(BuildContext context) async {
    final titleController = TextEditingController();
    DateTime? selectedDateTime;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Tạo cuộc họp sau'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề buổi học',
                    hintText: 'VD: Buổi học toán lớp 10A',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    selectedDateTime == null
                        ? 'Chọn ngày và giờ'
                        : '${selectedDateTime!.day.toString().padLeft(2, '0')}/${selectedDateTime!.month.toString().padLeft(2, '0')}/${selectedDateTime!.year}  ${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(hours: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null) return;
                    if (!ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time == null) return;
                    setStateDialog(() {
                      selectedDateTime = DateTime(
                        date.year, date.month, date.day,
                        time.hour, time.minute,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: titleController.text.isEmpty || selectedDateTime == null
                  ? null
                  : () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Tạo lịch'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    if (titleController.text.isEmpty || selectedDateTime == null) return;

    setState(() => _isMeetLoading = true);
    final sessionProvider = context.read<SessionProvider>();
    try {
      final session = await sessionProvider.createSession(
        _getCurrentClassId(),
        titleController.text.trim(),
      );
      if (!context.mounted) return;
      if (session == null) {
        _showError(context, sessionProvider.errorMessage ?? 'Không thể tạo lịch');
        return;
      }
      final dt = selectedDateTime!;
      final formatted =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lên lịch buổi học lúc $formatted'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMeetLoading = false);
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: true,
      backgroundColor: colors.surface,
      elevation: 1,
      shadowColor: Colors.black,
      title: Row(
        children: [
          Text(
            _selectedTeam,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(width: 16),
          _buildChannelTabs(context),
        ],
      ),
      actions: [
        // ── Meet now dropdown (TASK-UI-16) ──
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          enabled: !_isMeetLoading,
          onSelected: (value) {
            if (value == 'now') _handleMeetNow(context);
            if (value == 'schedule') _handleScheduleMeeting(context);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'now',
              child: ListTile(
                leading: Icon(Icons.videocam_outlined),
                title: Text('Meet now'),
                subtitle: Text('Bắt đầu ngay lập tức'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'schedule',
              child: ListTile(
                leading: Icon(Icons.calendar_today_outlined),
                title: Text('Tạo cuộc họp sau'),
                subtitle: Text('Đặt lịch buổi học'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          child: _isMeetLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  // PopupMenuButton sẽ tự xử lý tap, onPressed = null
                  onPressed: null,
                  icon: const Icon(Icons.videocam_outlined, size: 20),
                  label: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Meet now'),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.outlineVariant),
                    // Disable visual agar nút nhìn vẫn enabled
                    disabledForegroundColor: colors.primary.withOpacity(0.9),
                    disabledIconColor: colors.primary.withOpacity(0.9),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.call_to_action_outlined),
          onPressed: () {},
        ),
        IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildChannelTabs(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 40,
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorPadding: const EdgeInsets.only(bottom: 2),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: colors.primary, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 10),
        ),
        labelColor: colors.onSurface,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Shared'),
        ],
      ),
    );
  }

  Widget _buildTeamsSidebar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surfaceContainerLow,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Teams',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  tooltip: 'Join or create team',
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _teams.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final team = _teams[index];
                final isSelected = team == _selectedTeam;

                return ListTile(
                  dense: true,
                  selected: isSelected,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    child: Text(
                      _buildTeamInitials(team),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  title: Text(
                    team,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  selectedTileColor: colors.primaryContainer.withValues(
                    alpha: 0.45,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTeam = team;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildTeams(String initialTeam, List<String> availableTeams) {
    final teams = availableTeams
        .where((team) => team.trim().isNotEmpty)
        .toSet()
        .toList(growable: true);

    if (!teams.contains(initialTeam)) {
      teams.insert(0, initialTeam);
    }
    if (teams.isEmpty) {
      teams.add(initialTeam);
    }
    return teams.toSet().toList(growable: false);
  }

  String _buildTeamInitials(String value) {
    final words = value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) {
      return 'TM';
    }
    final items = words.toList(growable: false);
    if (items.length == 1) {
      final single = items.first.toUpperCase();
      return single.length >= 2 ? single.substring(0, 2) : single;
    }
    return '${items.first[0]}${items[1][0]}'.toUpperCase();
  }
}
