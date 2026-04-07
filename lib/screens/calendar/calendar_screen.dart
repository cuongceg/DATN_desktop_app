import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarDesktopScreen extends StatefulWidget {
  const CalendarDesktopScreen({super.key});

  @override
  State<CalendarDesktopScreen> createState() => _CalendarDesktopScreenState();
}

class _CalendarDesktopScreenState extends State<CalendarDesktopScreen> {
  static final DateTime _miniMonth = DateTime(2026, 4, 1);
  static const double _hideSidebarThreshold = 1320;

  final CalendarController _calendarController = CalendarController();

  DateTime _focusedDate = DateTime.now();
  String _selectedView = 'Work week';
  bool _isMyCalendarsExpanded = true;
  bool _isMainCalendarChecked = true;

  @override
  void initState() {
    super.initState();
    _calendarController.displayDate = _focusedDate;
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  void _goToToday() {
    setState(() {
      _focusedDate = DateTime.now();
      _calendarController.displayDate = _focusedDate;
    });
  }

  void _navigateByWeek(int direction) {
    setState(() {
      _focusedDate = _focusedDate.add(Duration(days: 7 * direction));
      _calendarController.displayDate = _focusedDate;
    });
  }

  String _buildDateRangeLabel() {
    final start = _focusedDate.subtract(
      Duration(days: _focusedDate.weekday - 1),
    );
    final end = start.add(const Duration(days: 4));
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final startMonth = monthNames[start.month - 1];
    final endMonth = monthNames[end.month - 1];

    if (start.month == end.month) {
      return '$startMonth ${start.day} - ${end.day}, ${end.year}';
    }

    return '$startMonth ${start.day} - $endMonth ${end.day}, ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final highlightedDay =
        (today.year == _miniMonth.year && today.month == _miniMonth.month)
        ? today.day
        : 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hideSidebar = constraints.maxWidth < _hideSidebarThreshold;

        return Container(
          color: scheme.surface,
          child: Row(
            children: [
              if (!hideSidebar)
                SizedBox(
                  width: 260,
                  child: CalendarSidebar(
                    month: _miniMonth,
                    highlightedDay: highlightedDay,
                    isExpanded: _isMyCalendarsExpanded,
                    isCalendarChecked: _isMainCalendarChecked,
                    onToggleExpanded: () {
                      setState(() {
                        _isMyCalendarsExpanded = !_isMyCalendarsExpanded;
                      });
                    },
                    onCalendarChanged: (checked) {
                      setState(() {
                        _isMainCalendarChecked = checked;
                      });
                    },
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: hideSidebar
                        ? null
                        : Border(
                            left: BorderSide(
                              color: scheme.outline.withOpacity(0.18),
                            ),
                          ),
                  ),
                  child: Column(
                    children: [
                      CalendarTopBar(
                        dateRangeText: _buildDateRangeLabel(),
                        selectedView: _selectedView,
                        onTodayPressed: _goToToday,
                        onPreviousPressed: () => _navigateByWeek(-1),
                        onNextPressed: () => _navigateByWeek(1),
                        onViewChanged: (view) {
                          setState(() {
                            _selectedView = view;
                          });
                        },
                      ),
                      Expanded(
                        child: MainCalendarGrid(
                          controller: _calendarController,
                          focusedDate: _focusedDate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CalendarSidebar extends StatelessWidget {
  const CalendarSidebar({
    super.key,
    required this.month,
    required this.highlightedDay,
    required this.isExpanded,
    required this.isCalendarChecked,
    required this.onToggleExpanded,
    required this.onCalendarChanged,
  });

  final DateTime month;
  final int highlightedDay;
  final bool isExpanded;
  final bool isCalendarChecked;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onCalendarChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calendar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          _MiniMonthCalendar(month: month, highlightedDay: highlightedDay),
          const SizedBox(height: 18),
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'My calendars',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            CheckboxListTile(
              value: isCalendarChecked,
              onChanged: (value) => onCalendarChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: const EdgeInsets.only(left: 2),
              title: Text(
                'Calendar',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniMonthCalendar extends StatelessWidget {
  const _MiniMonthCalendar({required this.month, required this.highlightedDay});

  final DateTime month;
  final int highlightedDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final firstDayOffset = DateTime(month.year, month.month, 1).weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    const weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    final cells = <int?>[
      ...List<int?>.filled(firstDayOffset, null),
      ...List<int?>.generate(daysInMonth, (index) => index + 1),
    ];

    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'April 2026',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_left,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: weekDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  weekDays[index],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final day = cells[index];
              if (day == null) {
                return const SizedBox.shrink();
              }

              final isHighlighted = day == highlightedDay;
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHighlighted ? scheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isHighlighted
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant.withOpacity(0.85),
                    fontWeight: isHighlighted
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class CalendarTopBar extends StatelessWidget {
  const CalendarTopBar({
    super.key,
    required this.dateRangeText,
    required this.selectedView,
    required this.onTodayPressed,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.onViewChanged,
  });

  final String dateRangeText;
  final String selectedView;
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final ValueChanged<String> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withOpacity(0.16)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final collapseFilterToIcon = width < 1180;
          final collapseMeetToIcon = width < 1080;
          final collapseNewToIcon = width < 980;
          final moveWorkWeekAndFilterToMore = width < 920;

          final moreItems = <PopupMenuEntry<_CalendarMoreAction>>[
            if (moveWorkWeekAndFilterToMore)
              const PopupMenuItem<_CalendarMoreAction>(
                value: _CalendarMoreAction.workWeek,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.view_week_outlined),
                  title: Text('Work week'),
                ),
              ),
            if (moveWorkWeekAndFilterToMore)
              const PopupMenuItem<_CalendarMoreAction>(
                value: _CalendarMoreAction.filterApplied,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.filter_alt_outlined),
                  title: Text('Filter applied'),
                ),
              ),
            if (moveWorkWeekAndFilterToMore) const PopupMenuDivider(),
            const PopupMenuItem<_CalendarMoreAction>(
              value: _CalendarMoreAction.share,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.ios_share_outlined),
                title: Text('Share'),
              ),
            ),
            const PopupMenuItem<_CalendarMoreAction>(
              value: _CalendarMoreAction.print,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.print_outlined),
                title: Text('Print'),
              ),
            ),
          ];

          return Row(
            children: [
              OutlinedButton(
                onPressed: onTodayPressed,
                child: const Text('Today'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onPreviousPressed,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous week',
              ),
              IconButton(
                onPressed: onNextPressed,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next week',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  dateRangeText,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (!moveWorkWeekAndFilterToMore)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outline.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedView,
                      dropdownColor: scheme.surfaceContainerHighest,
                      items: const [
                        DropdownMenuItem(
                          value: 'Work week',
                          child: Text('Work week'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          onViewChanged(value);
                        }
                      },
                    ),
                  ),
                ),
              if (!moveWorkWeekAndFilterToMore) const SizedBox(width: 8),
              if (!moveWorkWeekAndFilterToMore)
                (collapseFilterToIcon
                    ? IconButton(
                        onPressed: () {},
                        tooltip: 'Filter applied',
                        icon: const Icon(Icons.filter_alt_outlined),
                      )
                    : TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: const Text('Filter applied'),
                      )),
              if (!moveWorkWeekAndFilterToMore) const SizedBox(width: 8),
              PopupMenuButton<_CalendarMoreAction>(
                tooltip: 'More actions',
                onSelected: (action) {
                  if (action == _CalendarMoreAction.workWeek) {
                    onViewChanged('Work week');
                  }
                },
                itemBuilder: (context) => moreItems,
                icon: const Icon(Icons.more_horiz),
              ),
              const SizedBox(width: 8),
              (collapseMeetToIcon
                  ? IconButton(
                      onPressed: () {},
                      tooltip: 'Meet now',
                      icon: const Icon(Icons.videocam_outlined),
                    )
                  : OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Meet now'),
                    )),
              const SizedBox(width: 8),
              (collapseNewToIcon
                  ? IconButton(
                      onPressed: () {},
                      tooltip: 'New',
                      icon: const Icon(Icons.calendar_today_outlined),
                    )
                  : FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('New'),
                    )),
            ],
          );
        },
      ),
    );
  }
}

enum _CalendarMoreAction { workWeek, filterApplied, share, print }

class MainCalendarGrid extends StatelessWidget {
  const MainCalendarGrid({
    super.key,
    required this.controller,
    required this.focusedDate,
  });

  final CalendarController controller;
  final DateTime focusedDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SfCalendar(
      key: ValueKey(focusedDate.toIso8601String()),
      controller: controller,
      view: CalendarView.workWeek,
      firstDayOfWeek: 1,
      showDatePickerButton: false,
      showNavigationArrow: false,
      initialDisplayDate: focusedDate,
      headerHeight: 0,
      backgroundColor: scheme.surface,
      cellBorderColor: scheme.outline.withOpacity(0.14),
      showCurrentTimeIndicator: true,
      todayHighlightColor: scheme.primary,
      viewHeaderHeight: 74,
      viewHeaderStyle: ViewHeaderStyle(
        backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.16),
        dateTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        dayTextStyle: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      timeSlotViewSettings: TimeSlotViewSettings(
        dayFormat: 'EEEE',
        dateFormat: 'd',
        timeFormat: 'h a',
        timeIntervalHeight: 62,
        timeTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant.withOpacity(0.85),
        ),
      ),
    );
  }
}
