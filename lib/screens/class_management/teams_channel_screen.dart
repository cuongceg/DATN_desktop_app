import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/widgets/post_card.dart';

class TeamsChannelScreen extends StatefulWidget {
  const TeamsChannelScreen({
    super.key,
    required this.initialTeam,
    this.availableTeams = const <String>[],
  });

  final String initialTeam;
  final List<String> availableTeams;

  @override
  State<TeamsChannelScreen> createState() => _TeamsChannelScreenState();
}

class _TeamsChannelScreenState extends State<TeamsChannelScreen> {
  late final List<String> _teams;
  late String _selectedTeam;

  @override
  void initState() {
    super.initState();
    _teams = _buildTeams(widget.initialTeam, widget.availableTeams);
    _selectedTeam = widget.initialTeam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidebarWidth = (constraints.maxWidth * 0.2).clamp(220.0, 360.0);

          return Row(
            children: [
              SizedBox(width: sidebarWidth, child: _buildTeamsSidebar(context)),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, feedConstraints) {
                        final horizontalInset = (feedConstraints.maxWidth / 10)
                            .clamp(16.0, 140.0);

                        return ListView(
                          padding: EdgeInsets.only(
                            left: horizontalInset,
                            right: horizontalInset,
                            top: 16,
                            bottom: 88,
                          ),
                          children: PostCardSamples.posts
                              .map((post) => PostCard(post: post))
                              .toList(),
                        );
                      },
                    ),
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_square, size: 18),
                        label: const Text(
                          'Post in channel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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
          const SizedBox(width: 24),
          _buildTab(context, 'Posts', isSelected: true),
          const SizedBox(width: 16),
          _buildTab(context, 'Shared'),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () {},
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

  Widget _buildTab(
    BuildContext context,
    String title, {
    bool isSelected = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
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
              separatorBuilder: (_, __) => const SizedBox(height: 4),
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
                  selectedTileColor: colors.primaryContainer.withOpacity(0.45),
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
