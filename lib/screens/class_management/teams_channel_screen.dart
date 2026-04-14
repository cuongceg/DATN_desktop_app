import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/screens/class_management/document_management_screen.dart';
import 'package:flutter_web_rtc/screens/meeting/meeting_screen.dart';
import 'package:flutter_web_rtc/widgets/post_card.dart';
import 'package:flutter_web_rtc/widgets/message_composer.dart';

class TeamsChannelScreen extends StatefulWidget {
  const TeamsChannelScreen({
    super.key,
    required this.initialTeam,
    required this.isTeacher,
    required this.currentThemeMode,
    required this.onThemeToggle,
    this.availableTeams = const <String>[],
  });

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
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MeetingScreen(isTeacher: widget.isTeacher),
              ),
            );
          },
          icon: const Icon(Icons.videocam_outlined, size: 20),
          label: const Text('Meet now'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.outlineVariant),
          ),
        ),
        Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: 16),
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
