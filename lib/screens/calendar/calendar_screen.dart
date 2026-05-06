import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../features/auth/presentation/controllers/auth_notifier.dart';
import '../../features/session/models/session_model.dart';
import '../../features/session/providers/meeting_room_provider.dart';
import '../../features/session/providers/session_provider.dart';
import '../../features/session/screens/meeting_room_screen.dart';
import '../../features/session/screens/widgets/create_session_dialog.dart';
import '../../features/session/screens/widgets/session_data_source.dart';
import '../../features/session/screens/widgets/session_detail_popup.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessionsForCurrentView();
    });
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
    _loadSessionsForCurrentView();
  }

  void _navigateByWeek(int direction) {
    setState(() {
      _focusedDate = _focusedDate.add(Duration(days: 7 * direction));
      _calendarController.displayDate = _focusedDate;
    });
    _loadSessionsForCurrentView();
  }

  void _loadSessionsForCurrentView() {
    final DateTime monday = _focusedDate.subtract(
      Duration(days: _focusedDate.weekday - 1),
    );
    final DateTime friday = monday.add(const Duration(days: 4));
    context.read<SessionProvider>().loadSessionsForRange(monday, friday);
  }

  void _showSessionDetail(BuildContext ctx, SessionModel session) {
    showDialog<void>(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => SessionDetailPopup(
        session: session,
        onJoin: () => _handleJoin(session),
        onStart: (SessionModel started) => _handleStart(started),
      ),
    );
  }

  void _showCreateDialog(BuildContext ctx, {DateTime? prefilledDate}) {
    showDialog<void>(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => CreateSessionDialog(prefilledDate: prefilledDate),
    );
  }

  Future<void> _handleStart(SessionModel session) async {
    final result =
        await context.read<SessionProvider>().joinSession(session.id);
    if (!mounted) return;

    if (result == null) {
      final String? error = context.read<SessionProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Không thể vào buổi học.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MeetingRoomProvider(),
          child: MeetingRoomScreen(
            sessionId: session.id,
            livekitUrl: result.livekitUrl,
            token: result.token,
            sessionTitle: session.title,
            isTeacher: true,
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoin(SessionModel session) async {
    final result =
        await context.read<SessionProvider>().joinSession(session.id);
    if (!mounted) return;

    if (result == null) {
      final String? error = context.read<SessionProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Không thể tham gia buổi học.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => MeetingRoomProvider(),
          child: MeetingRoomScreen(
            sessionId: session.id,
            livekitUrl: result.livekitUrl,
            token: result.token,
            sessionTitle: session.title,
            isTeacher: false,
          ),
        ),
      ),
    );
  }

  String _buildDateRangeLabel() {
    final DateTime start = _focusedDate.subtract(
      Duration(days: _focusedDate.weekday - 1),
    );
    final DateTime end = start.add(const Duration(days: 4));
    const List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    final String startMonth = monthNames[start.month - 1];
    final String endMonth = monthNames[end.month - 1];

    if (start.month == end.month) {
      return '$startMonth ${start.day} - ${end.day}, ${end.year}';
    }
    return '$startMonth ${start.day} - $endMonth ${end.day}, ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final SessionProvider sessionProvider = context.watch<SessionProvider>();
    final bool isTeacher =
        context.read<AuthNotifier>().currentUser?.role == 'teacher';

    final DateTime today = DateTime.now();
    final int highlightedDay =
        (today.year == _miniMonth.year && today.month == _miniMonth.month)
            ? today.day
            : 2;

    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final bool hideSidebar =
            constraints.maxWidth < _hideSidebarThreshold;

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
                    onToggleExpanded: () => setState(
                      () => _isMyCalendarsExpanded = !_isMyCalendarsExpanded,
                    ),
                    onCalendarChanged: (bool checked) =>
                        setState(() => _isMainCalendarChecked = checked),
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
                        onViewChanged: (String view) =>
                            setState(() => _selectedView = view),
                        showNewButton: isTeacher,
                        onNewPressed: () => _showCreateDialog(context),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            MainCalendarGrid(
                              controller: _calendarController,
                              focusedDate: _focusedDate,
                              dataSource: SessionDataSource(
                                sessionProvider.sessions,
                                scheme,
                              ),
                              onTap: (CalendarTapDetails details) {
                                if (details.appointments?.isNotEmpty == true) {
                                  final String id =
                                      details.appointments!.first.id as String;
                                  final SessionModel session =
                                      sessionProvider.sessions.firstWhere(
                                    (SessionModel s) => s.id == id,
                                  );
                                  _showSessionDetail(context, session);
                                } else if (
                                  details.targetElement ==
                                      CalendarElement.calendarCell &&
                                  isTeacher
                                ) {
                                  _showCreateDialog(
                                    context,
                                    prefilledDate: details.date,
                                  );
                                }
                              },
                            ),
                            if (sessionProvider.isLoading)
                              const Positioned.fill(
                                child: ColoredBox(
                                  color: Color(0x22000000),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
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

// ---------------------------------------------------------------------------

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
    final ColorScheme scheme = Theme.of(context).colorScheme;

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
              onChanged: (bool? value) => onCalendarChanged(value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: const EdgeInsets.only(left: 2),
              title: Text(
                'Calendar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _MiniMonthCalendar extends StatelessWidget {
  const _MiniMonthCalendar({
    required this.month,
    required this.highlightedDay,
  });

  final DateTime month;
  final int highlightedDay;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int firstDayOffset =
        DateTime(month.year, month.month, 1).weekday - 1;
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    const List<String> weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    final List<int?> cells = <int?>[
      ...List<int?>.filled(firstDayOffset, null),
      ...List<int?>.generate(daysInMonth, (int i) => i + 1),
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
              Icon(Icons.chevron_left, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
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
            itemBuilder: (BuildContext context, int index) => Center(
              child: Text(
                weekDays[index],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withOpacity(0.8),
                    ),
              ),
            ),
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
            ),
            itemBuilder: (BuildContext context, int index) {
              final int? day = cells[index];
              if (day == null) return const SizedBox.shrink();
              final bool isHighlighted = day == highlightedDay;
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isHighlighted ? scheme.primary : Colors.transparent,
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

// ---------------------------------------------------------------------------

/// Top bar của calendar — navigation, view picker, và nút "New" (teacher-only).
class CalendarTopBar extends StatelessWidget {
  const CalendarTopBar({
    super.key,
    required this.dateRangeText,
    required this.selectedView,
    required this.onTodayPressed,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.onViewChanged,
    required this.showNewButton,
    required this.onNewPressed,
  });

  final String dateRangeText;
  final String selectedView;
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final ValueChanged<String> onViewChanged;

  /// Ẩn/hiện nút "New" — chỉ hiển thị với role `teacher`.
  final bool showNewButton;

  /// Callback khi teacher bấm "New".
  final VoidCallback onNewPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withOpacity(0.16)),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool collapseFilterToIcon = width < 1180;
          final bool collapseMeetToIcon = width < 1080;
          final bool collapseNewToIcon = width < 980;
          final bool moveWorkWeekAndFilterToMore = width < 920;

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
              if (!moveWorkWeekAndFilterToMore) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: scheme.outline.withOpacity(0.2)),
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
                      onChanged: (String? value) {
                        if (value != null) onViewChanged(value);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                collapseFilterToIcon
                    ? IconButton(
                        onPressed: () {},
                        tooltip: 'Filter applied',
                        icon: const Icon(Icons.filter_alt_outlined),
                      )
                    : TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: const Text('Filter applied'),
                      ),
                const SizedBox(width: 8),
              ],
              PopupMenuButton<_CalendarMoreAction>(
                tooltip: 'More actions',
                onSelected: (_CalendarMoreAction action) {
                  if (action == _CalendarMoreAction.workWeek) {
                    onViewChanged('Work week');
                  }
                },
                itemBuilder: (BuildContext context) => moreItems,
                icon: const Icon(Icons.more_horiz),
              ),
              if (showNewButton) ...[
                const SizedBox(width: 8),
                collapseMeetToIcon
                  ? IconButton(
                      onPressed: () {},
                      tooltip: 'Meet now',
                      icon: const Icon(Icons.videocam_outlined),
                    )
                  : OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Meet now'),
                    ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Tạo buổi học mới',
                  child: collapseNewToIcon
                      ? IconButton(
                          onPressed: onNewPressed,
                          tooltip: 'Tạo mới',
                          icon: const Icon(Icons.calendar_today_outlined),
                        )
                      : FilledButton.icon(
                          onPressed: onNewPressed,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: const Text('New'),
                        ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

enum _CalendarMoreAction { workWeek, filterApplied, share, print }

// ---------------------------------------------------------------------------

/// Wrapper quanh [SfCalendar] với các defaults của ứng dụng.
class MainCalendarGrid extends StatelessWidget {
  const MainCalendarGrid({
    super.key,
    required this.controller,
    required this.focusedDate,
    this.dataSource,
    this.onTap,
  });

  final CalendarController controller;
  final DateTime focusedDate;

  /// Data source cung cấp các appointment session cho calendar.
  final CalendarDataSource? dataSource;

  /// Callback khi tap vào cell hoặc appointment.
  final CalendarTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

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
        dayTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
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
      dataSource: dataSource,
      onTap: onTap,
    );
  }
}
