import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../auth/presentation/controllers/auth_notifier.dart';
import '../../classroom/domain/entities/classroom_entity.dart';
import '../../classroom/presentation/controllers/classroom_notifier.dart';
import '../../session/models/session_model.dart';
import '../../session/providers/session_provider.dart';
import '../../session/screens/join_screen.dart';
import '../../session/screens/widgets/create_session_dialog.dart';
import '../../session/screens/widgets/session_data_source.dart';
import '../../session/screens/widgets/session_detail_popup.dart';

class CalendarDesktopScreen extends StatefulWidget {
  const CalendarDesktopScreen({super.key});

  @override
  State<CalendarDesktopScreen> createState() => _CalendarDesktopScreenState();
}

class _CalendarDesktopScreenState extends State<CalendarDesktopScreen> {
  final CalendarController _calendarController = CalendarController();
  DateTime _focusedDate = DateTime.now();
  String? _filteredClassId;

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
    final DateTime friday = monday.add(const Duration(days: 6));
    context.read<SessionProvider>().loadSessionsForRange(monday, friday);
  }

  // ── Meet now ──────────────────────────────────────────────────────────────

  void _showMeetNowClassPicker(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => _MeetNowClassPickerDialog(
        onClassSelected: (ClassroomEntity cls) => _startMeetNow(cls),
      ),
    );
  }

  /// Tạo session tức thì cho [cls] (create → start → join) rồi navigate vào phòng.
  Future<void> _startMeetNow(ClassroomEntity cls) async {
    final SessionModel? created = await context
        .read<SessionProvider>()
        .createSession(cls.id, 'Buổi học nhanh');
    if (!mounted) return;

    if (created == null) {
      final String? err = context.read<SessionProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Không thể tạo buổi học.')),
      );
      return;
    }

    final SessionModel? started = await context
        .read<SessionProvider>()
        .startSession(created.id);
    if (!mounted) return;

    if (started == null) {
      final String? err = context.read<SessionProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Không thể bắt đầu buổi học.')),
      );
      return;
    }

    await _handleStart(started);
  }

  // ── Session detail & create ───────────────────────────────────────────────

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

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _handleStart(SessionModel session) async {
    final result =
        await context.read<SessionProvider>().joinSession(session.id);
    if (!mounted) return;
    if (result == null) {
      final String? err = context.read<SessionProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Không thể vào buổi học.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JoinScreen(
          sessionId: session.id,
          livekitUrl: result.livekitUrl,
          token: result.token,
          sessionTitle: session.title,
          isTeacher: true,
        ),
      ),
    );
  }

  Future<void> _handleJoin(SessionModel session) async {
    final result =
        await context.read<SessionProvider>().joinSession(session.id);
    if (!mounted) return;
    if (result == null) {
      final String? err = context.read<SessionProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Không thể tham gia buổi học.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JoinScreen(
          sessionId: session.id,
          livekitUrl: result.livekitUrl,
          token: result.token,
          sessionTitle: session.title,
          isTeacher: false,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  String _buildDateRangeLabel() {
    final DateTime start = _focusedDate.subtract(
      Duration(days: _focusedDate.weekday - 1),
    );
    final DateTime end = start.add(const Duration(days: 6));
    const List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.day} - ${end.day}, ${end.year}';
    }
    return '${months[start.month - 1]} ${start.day}'
        ' - ${months[end.month - 1]} ${end.day}, ${end.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final SessionProvider sessionProvider = context.watch<SessionProvider>();
    final bool isTeacher =
        context.read<AuthNotifier>().currentUser?.role == 'teacher';

    final List<SessionModel> visibleSessions = _filteredClassId == null
        ? sessionProvider.sessions
        : sessionProvider.sessions
            .where((SessionModel s) => s.classId == _filteredClassId)
            .toList();

    return Column(
      children: [
        CalendarTopBar(
          dateRangeText: _buildDateRangeLabel(),
          onTodayPressed: _goToToday,
          onPreviousPressed: () => _navigateByWeek(-1),
          onNextPressed: () => _navigateByWeek(1),
          onMeetNowPressed:
              isTeacher ? () => _showMeetNowClassPicker(context) : null,
          showNewButton: isTeacher,
          onNewPressed: () => _showCreateDialog(context),
          filteredClassId: _filteredClassId,
          onFilterChanged: (String? id) =>
              setState(() => _filteredClassId = id),
        ),
        Expanded(
          child: Stack(
            children: [
              MainCalendarGrid(
                controller: _calendarController,
                focusedDate: _focusedDate,
                dataSource: SessionDataSource(visibleSessions, scheme),
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
                    details.targetElement == CalendarElement.calendarCell &&
                    isTeacher
                  ) {
                    _showCreateDialog(context, prefilledDate: details.date);
                  }
                },
              ),
              if (sessionProvider.isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x22000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

/// Top bar với navigation, filter lớp, Meet now, và New (2 nút cuối teacher-only).
class CalendarTopBar extends StatelessWidget {
  const CalendarTopBar({
    super.key,
    required this.dateRangeText,
    required this.onTodayPressed,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.showNewButton,
    required this.onNewPressed,
    required this.filteredClassId,
    required this.onFilterChanged,
    this.onMeetNowPressed,
  });

  final String dateRangeText;
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final bool showNewButton;
  final VoidCallback onNewPressed;
  final String? filteredClassId;
  final ValueChanged<String?> onFilterChanged;

  /// Callback khi teacher bấm "Meet now". `null` ẩn nút (student).
  final VoidCallback? onMeetNowPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outline.withOpacity(0.16)),
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool collapseMeetToIcon = width < 900;
          final bool collapseFilterToIcon = width < 780;
          final bool collapseNewToIcon = width < 660;

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
              const SizedBox(width: 8),
              _ClassFilterPopup(
                filteredClassId: filteredClassId,
                onFilterChanged: onFilterChanged,
                collapseToIcon: collapseFilterToIcon,
              ),
              if (onMeetNowPressed != null) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: 'Bắt đầu cuộc họp ngay',
                  child: collapseMeetToIcon
                      ? IconButton(
                          onPressed: onMeetNowPressed,
                          tooltip: 'Meet now',
                          icon: const Icon(Icons.videocam_outlined),
                        )
                      : OutlinedButton.icon(
                          onPressed: onMeetNowPressed,
                          icon: const Icon(Icons.videocam_outlined),
                          label: const Text('Meet now'),
                        ),
                ),
              ],
              if (showNewButton) ...[
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

// ---------------------------------------------------------------------------

class _ClassFilterPopup extends StatelessWidget {
  const _ClassFilterPopup({
    required this.filteredClassId,
    required this.onFilterChanged,
    required this.collapseToIcon,
  });

  final String? filteredClassId;
  final ValueChanged<String?> onFilterChanged;
  final bool collapseToIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<ClassroomEntity> classrooms =
        context.watch<ClassroomNotifier>().classrooms;

    return PopupMenuButton<String?>(
      tooltip: 'Lọc theo lớp',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onFilterChanged,
      itemBuilder: (BuildContext ctx) {
        final List<PopupMenuEntry<String?>> items = [
          // value: null is silently dropped by PopupMenuButton — use onTap instead
          // so selecting "Tất cả lớp" always fires even when filter is already null.
          PopupMenuItem<String?>(
            onTap: () => onFilterChanged(null),
            child: Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 18,
                  color: filteredClassId == null
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Text(
                  'Tất cả lớp',
                  style: TextStyle(
                    color: filteredClassId == null ? scheme.primary : null,
                    fontWeight: filteredClassId == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (filteredClassId == null) ...[
                  const Spacer(),
                  Icon(Icons.check, size: 16, color: scheme.primary),
                ],
              ],
            ),
          ),
        ];
        if (classrooms.isNotEmpty) {
          items.add(const PopupMenuDivider());
          items.addAll(
            classrooms.map(
              (ClassroomEntity c) => PopupMenuItem<String?>(
                value: c.id,
                child: _FilterMenuItem(
                  icon: Icons.class_outlined,
                  label: c.name,
                  isSelected: filteredClassId == c.id,
                ),
              ),
            ),
          );
        }
        return items;
      },
      child: Semantics(
        label: filteredClassId == null ? 'Lọc theo lớp' : 'Filter đang bật',
        child: _ClassFilterButton(
          isActive: filteredClassId != null,
          collapseToIcon: collapseToIcon,
        ),
      ),
    );
  }
}

class _FilterMenuItem extends StatelessWidget {
  const _FilterMenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        if (isSelected) Icon(Icons.check, size: 18, color: scheme.primary),
      ],
    );
  }
}

class _ClassFilterButton extends StatelessWidget {
  const _ClassFilterButton({
    required this.isActive,
    required this.collapseToIcon,
  });

  final bool isActive;
  final bool collapseToIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color =
        isActive ? scheme.primary : scheme.onSurfaceVariant;
    final IconData icon =
        isActive ? Icons.filter_alt : Icons.filter_alt_outlined;

    if (collapseToIcon) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 24, color: color),
          ),
          if (isActive)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Filter active' : 'Filter',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Glassmorphism dialog cho Teacher chọn lớp để bắt đầu Meet now.
class _MeetNowClassPickerDialog extends StatelessWidget {
  const _MeetNowClassPickerDialog({required this.onClassSelected});

  final ValueChanged<ClassroomEntity> onClassSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<ClassroomEntity> activeClasses = context
        .watch<ClassroomNotifier>()
        .classrooms
        .where((ClassroomEntity c) => c.status == 'active')
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, scheme),
                const Divider(height: 1),
                _buildClassList(context, scheme, activeClasses),
                const Divider(height: 1),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam_outlined,
              color: scheme.onPrimaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bắt đầu buổi học ngay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chọn lớp để bắt đầu',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList(
    BuildContext context,
    ColorScheme scheme,
    List<ClassroomEntity> classes,
  ) {
    if (classes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Text(
          'Không có lớp active nào.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: classes.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (BuildContext ctx, int i) => _ClassPickerTile(
          classroom: classes[i],
          onTap: () {
            Navigator.of(ctx).pop();
            onClassSelected(classes[i]);
          },
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
      ),
    );
  }
}

class _ClassPickerTile extends StatelessWidget {
  const _ClassPickerTile({
    required this.classroom,
    required this.onTap,
  });

  final ClassroomEntity classroom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String initial =
        classroom.name.isNotEmpty ? classroom.name[0].toUpperCase() : '?';

    return Semantics(
      label: 'Chọn lớp ${classroom.name}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classroom.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                    ),
                    if (classroom.description != null &&
                        classroom.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        classroom.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

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
      view: CalendarView.week,
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
