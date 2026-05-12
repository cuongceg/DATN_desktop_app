import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_rtc/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:flutter_web_rtc/features/posts/models/post_model.dart';
import 'package:flutter_web_rtc/features/posts/providers/posts_provider.dart';
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
  final ScrollController _postsScrollController = ScrollController();
  late String _selectedTeam;
  bool _isComposerVisible = false;
  bool _showNewPostIndicator = false;
  bool _isMeetLoading = false;
  String? _editingPostId;
  String _composerInitialSubject = '';
  String _composerInitialBody = '';
  List<dynamic>? _composerInitialBodyDelta;

  @override
  void initState() {
    super.initState();
    _teams = _buildTeams(widget.initialTeam, widget.availableTeams);
    _selectedTeam = widget.initialTeam;
    _postsScrollController.addListener(_onPostsScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PostsProvider>().fetchPosts(widget.classId);
      }
    });
  }

  @override
  void dispose() {
    _postsScrollController.removeListener(_onPostsScroll);
    _postsScrollController.dispose();
    super.dispose();
  }

  void _onPostsScroll() {
    if (!_postsScrollController.hasClients) return;
    final pos = _postsScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.9) {
      final provider = context.read<PostsProvider>();
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.loadMorePosts(widget.classId);
      }
    }
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
                            classId: widget.classId,
                            isTeacher: widget.isTeacher,
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
    final currentUserId =
        context.read<AuthNotifier>().currentUser?.id ?? '';

    return Consumer<PostsProvider>(
      builder: (context, provider, _) {
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
                    child: _buildPostsList(provider, currentUserId),
                  ),
                  if (_isComposerVisible)
                    MessageComposer(
                      initialSubject: _composerInitialSubject,
                      initialBody: _composerInitialBody,
                      initialBodyDelta: _composerInitialBodyDelta,
                      postButtonLabel: _editingPostId == null ? 'Post' : 'Update',
                      onClose: _closeComposer,
                      onPost: (s, b, d) {
                        _handlePost(s, b, d);
                      },
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
                  label: const Text('Có bài đăng mới'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPostsList(PostsProvider provider, String currentUserId) {
    final colors = Theme.of(context).colorScheme;

    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.errorMessage!,
              style: TextStyle(color: colors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context
                  .read<PostsProvider>()
                  .fetchPosts(widget.classId, refresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (provider.posts.isEmpty) {
      return Center(
        child: Text(
          'Chưa có bài đăng nào',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }

    return ListView.builder(
      controller: _postsScrollController,
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: provider.posts.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.posts.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          );
        }
        final post = provider.posts[index];
        return PostCard(
          post: post,
          currentUserId: currentUserId,
          isTeacher: widget.isTeacher,
          onModifyPost: _handleModifyPost,
          onDeletePost: (p) {
            _handleDeletePost(p);
          },
        );
      },
    );
  }

  Future<void> _handlePost(
    String subject,
    String bodyPlain,
    List<dynamic> bodyDelta,
  ) async {
    if (subject.isEmpty && bodyPlain.isEmpty) return;
    final provider = context.read<PostsProvider>();
    final deltaMap = {'ops': bodyDelta};

    if (_editingPostId != null) {
      await provider.updatePost(
        postId: _editingPostId!,
        title: subject.isEmpty ? null : subject,
        bodyDelta: deltaMap,
        bodyPlain: bodyPlain,
      );
    } else {
      final newPost = await provider.createPost(
        classId: widget.classId,
        title: subject.isEmpty ? null : subject,
        bodyDelta: deltaMap,
        bodyPlain: bodyPlain,
      );
      if (newPost != null && mounted) {
        setState(() => _showNewPostIndicator = true);
      }
    }

    if (mounted) {
      setState(() {
        _isComposerVisible = false;
        _editingPostId = null;
        _composerInitialSubject = '';
        _composerInitialBody = '';
        _composerInitialBodyDelta = null;
      });
    }
  }

  void _handleModifyPost(PostModel post) {
    setState(() {
      _editingPostId = post.id;
      _composerInitialSubject = post.title ?? '';
      _composerInitialBody = post.bodyPlain ?? '';
      _composerInitialBodyDelta = post.bodyDelta?['ops'] as List<dynamic>?;
      _isComposerVisible = true;
      _showNewPostIndicator = false;
    });
  }

  Future<void> _handleDeletePost(PostModel post) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài đăng'),
        content: const Text('Bạn có chắc muốn xóa bài đăng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<PostsProvider>().deletePost(post.id);
  }

  void _openComposerForNewPost() {
    setState(() {
      _editingPostId = null;
      _composerInitialSubject = '';
      _composerInitialBody = '';
      _composerInitialBodyDelta = null;
      _isComposerVisible = true;
    });
  }

  void _closeComposer() {
    setState(() {
      _isComposerVisible = false;
      _editingPostId = null;
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
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isMeetLoading = false);
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AppBar(
      automaticallyImplyLeading: true,
      backgroundColor: colors.surface,
      elevation: 1,
      shadowColor: colors.shadow,
      title: Row(
        children: [
          Text(
            _selectedTeam,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                    disabledForegroundColor: colors.primary.withValues(alpha: 0.9),
                    disabledIconColor: colors.primary.withValues(alpha: 0.9),
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
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
