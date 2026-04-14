import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/screens/class_management/teams_channel_screen.dart';

import '../models/classroom.dart';

class ClassCardStudent extends StatelessWidget {
  const ClassCardStudent({
    super.key,
    required this.classroom,
    required this.availableTeams,
    required this.currentThemeMode,
    required this.onThemeToggle,
  });

  final Classroom classroom;
  final List<String> availableTeams;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = isLight
        ? Colors.white
        : Color.alphaBlend(const Color(0x14FFFFFF), const Color(0xFF171A22));
    final logoColor = _logoColor(classroom.name);
    final initials = _buildInitials(classroom.name);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamsChannelScreen(
              initialTeam: classroom.name,
              availableTeams: availableTeams,
              isTeacher: false,
              currentThemeMode: currentThemeMode,
              onThemeToggle: onThemeToggle,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shadowColor: scheme.shadow,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoWidth = constraints.maxWidth / 3;
            final logoHeight = constraints.maxHeight / 2;

            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: logoWidth,
                        height: logoHeight,
                        decoration: BoxDecoration(
                          color: logoColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          classroom.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Tùy chọn lớp học',
                        onSelected: (_) {},
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'hide',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.visibility_off_outlined),
                              title: Text('Hide'),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'add_member',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.person_add_alt_1_outlined),
                              title: Text('Add member'),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'manage_teams',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.groups_2_outlined),
                              title: Text('Manage teams'),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'manage_tags',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.sell_outlined),
                              title: Text('Manage tags'),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'copy_link',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.link_outlined),
                              title: Text('Copy link'),
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      _QuickAction(
                        icon: Icons.campaign_outlined,
                        tooltip: 'Announcements',
                      ),
                      SizedBox(width: 4),
                      _QuickAction(
                        icon: Icons.assignment_outlined,
                        tooltip: 'Assignment',
                      ),
                      SizedBox(width: 4),
                      _QuickAction(
                        icon: Icons.menu_book_outlined,
                        tooltip: 'Classwork',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _buildInitials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length >= 2) {
      final list = words.toList(growable: false);
      return '${list[0][0]}${list[1][0]}'.toUpperCase();
    }
    final compact = name.replaceAll(' ', '').toUpperCase();
    return compact.length >= 2 ? compact.substring(0, 2) : compact;
  }

  Color _logoColor(String seed) {
    const palette = <Color>[
      Color(0xFF0F4C81),
      Color(0xFF2B579A),
      Color(0xFF1F7A8C),
      Color(0xFFB45309),
      Color(0xFF8B5CF6),
      Color(0xFF0E7490),
      Color(0xFFBE185D),
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        onPressed: () {},
        icon: Icon(icon, size: 18),
      ),
    );
  }
}
