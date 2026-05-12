import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_rtc/features/posts/models/post_model.dart';
import 'package:flutter_web_rtc/features/session/providers/session_provider.dart';
import 'package:flutter_web_rtc/features/session/screens/join_screen.dart';
import 'package:flutter_web_rtc/widgets/app_react_button.dart';

enum PostMenuAction { modify, delete }

// ─── Entry point ─────────────────────────────────────────────────────────────

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.isTeacher,
    required this.onDeletePost,
    required this.onModifyPost,
  });

  final PostModel post;
  final String currentUserId;
  final bool isTeacher;
  final void Function(PostModel post) onDeletePost;
  final void Function(PostModel post) onModifyPost;

  @override
  Widget build(BuildContext context) {
    if (post.type == 'session') {
      return SessionPostCard(post: post, isTeacher: isTeacher);
    }
    return _NormalPostCard(
      post: post,
      currentUserId: currentUserId,
      onDeletePost: onDeletePost,
      onModifyPost: onModifyPost,
    );
  }
}

// ─── Normal post card ─────────────────────────────────────────────────────────

class _NormalPostCard extends StatelessWidget {
  const _NormalPostCard({
    required this.post,
    required this.currentUserId,
    required this.onDeletePost,
    required this.onModifyPost,
  });

  final PostModel post;
  final String currentUserId;
  final void Function(PostModel) onDeletePost;
  final void Function(PostModel) onModifyPost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final cardColor = isLight
        ? Color.alphaBlend(const Color(0x0A000000), colors.surface)
        : Color.alphaBlend(const Color(0x12FFFFFF), colors.surface);
    final isAuthor = post.authorId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: colors.secondary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    _initials(post.authorName),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (post.title != null && post.title!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          post.title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      _PostBodyView(post: post),
                    ],
                  ),
                ),
                if (isAuthor)
                  PopupMenuButton<PostMenuAction>(
                    tooltip: 'Post actions',
                    onSelected: (action) {
                      switch (action) {
                        case PostMenuAction.modify:
                          onModifyPost(post);
                        case PostMenuAction.delete:
                          onDeletePost(post);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: PostMenuAction.modify,
                        child: Text('Chỉnh sửa'),
                      ),
                      PopupMenuItem(
                        value: PostMenuAction.delete,
                        child: Text('Xóa'),
                      ),
                    ],
                    icon: Icon(
                      Icons.more_vert,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 58, bottom: 8),
            child: AppReactButton(
              tooltip: 'React to post',
              icon: Icons.add_reaction_outlined,
              iconColor: colors.onSurfaceVariant,
              itemSize: const Size(44, 44),
              boxColor: colors.surfaceContainerHigh,
              onReactionChanged: (_) {},
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.surfaceContainerHighest,
                  child: Text(
                    _initials(post.authorName),
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Reply',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Session post card ────────────────────────────────────────────────────────

class SessionPostCard extends StatefulWidget {
  const SessionPostCard({
    super.key,
    required this.post,
    required this.isTeacher,
  });

  final PostModel post;
  final bool isTeacher;

  @override
  State<SessionPostCard> createState() => _SessionPostCardState();
}

class _SessionPostCardState extends State<SessionPostCard> {
  bool _isLoading = false;

  Future<void> _handleStart() async {
    final sessionId = widget.post.sessionId;
    if (sessionId == null) return;
    setState(() => _isLoading = true);
    final provider = context.read<SessionProvider>();
    try {
      final started = await provider.startSession(sessionId);
      if (started == null) {
        if (mounted) _showError(provider.errorMessage ?? 'Không thể bắt đầu buổi học');
        return;
      }
      final joinData = await provider.joinSession(sessionId);
      if (joinData == null) {
        if (mounted) _showError(provider.errorMessage ?? 'Không lấy được token');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JoinScreen(
            sessionId: sessionId,
            livekitUrl: joinData.livekitUrl,
            token: joinData.token,
            sessionTitle: widget.post.sessionTitle ?? '',
            isTeacher: true,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoin() async {
    final sessionId = widget.post.sessionId;
    if (sessionId == null) return;
    setState(() => _isLoading = true);
    final provider = context.read<SessionProvider>();
    try {
      final joinData = await provider.joinSession(sessionId);
      if (joinData == null) {
        if (mounted) _showError(provider.errorMessage ?? 'Không lấy được token');
        return;
      }
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JoinScreen(
            sessionId: sessionId,
            livekitUrl: joinData.livekitUrl,
            token: joinData.token,
            sessionTitle: widget.post.sessionTitle ?? '',
            isTeacher: false,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final cardColor = isLight
        ? Color.alphaBlend(const Color(0x0A000000), colors.surface)
        : Color.alphaBlend(const Color(0x12FFFFFF), colors.surface);

    final status = widget.post.sessionStatus;
    final scheduledAt = widget.post.sessionScheduledAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: colors.primary, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.videocam_rounded,
                color: colors.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.post.sessionTitle ?? 'Buổi học trực tuyến',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: status),
                    ],
                  ),
                  if (scheduledAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatSessionTime(scheduledAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      else if (widget.isTeacher && status == 'scheduled')
                        FilledButton.icon(
                          onPressed: _handleStart,
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Bắt đầu'),
                        )
                      else if (!widget.isTeacher && status == 'ongoing')
                        FilledButton.icon(
                          onPressed: _handleJoin,
                          icon: const Icon(Icons.video_call, size: 18),
                          label: const Text('Tham gia'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final (label, bg, fg) = switch (status) {
      'scheduled' => (
          'Sắp diễn ra',
          colors.primaryContainer,
          colors.onPrimaryContainer,
        ),
      'ongoing' => (
          'Đang diễn ra',
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
        ),
      'completed' => (
          'Đã kết thúc',
          colors.surfaceContainerHighest,
          colors.onSurfaceVariant,
        ),
      _ => ('Không xác định', colors.surfaceContainerHighest, colors.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

// ─── Body view (Quill or plain text) ─────────────────────────────────────────

class _PostBodyView extends StatefulWidget {
  const _PostBodyView({required this.post});

  final PostModel post;

  @override
  State<_PostBodyView> createState() => _PostBodyViewState();
}

class _PostBodyViewState extends State<_PostBodyView> {
  late QuillController _controller;
  late bool _useQuill;

  @override
  void initState() {
    super.initState();
    _useQuill = widget.post.bodyDelta != null;
    _controller = _buildController();
  }

  @override
  void didUpdateWidget(covariant _PostBodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _controller.dispose();
      _useQuill = widget.post.bodyDelta != null;
      _controller = _buildController();
    }
  }

  QuillController _buildController() {
    final ops = widget.post.bodyDelta?['ops'];
    final document = (ops is List && ops.isNotEmpty)
        ? Document.fromJson(ops)
        : (Document()..insert(0, widget.post.bodyPlain ?? ''));
    return QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (!_useQuill) {
      return Text(
        widget.post.bodyPlain ?? '',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurface,
          height: 1.5,
        ),
      );
    }

    return QuillEditor.basic(
      controller: _controller,
      config: QuillEditorConfig(
        scrollable: false,
        expands: false,
        showCursor: false,
        padding: EdgeInsets.zero,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  height: 1.5,
                ) ??
                TextStyle(color: colors.onSurface, height: 1.5),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first.toUpperCase();
    return w.length >= 2 ? w.substring(0, 2) : w;
  }
  return '${words.first[0]}${words[1][0]}'.toUpperCase();
}

String _formatDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d/$m/${dt.year} $h:$min';
}

String _formatSessionTime(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$h:$min $d/$m/${dt.year}';
}
