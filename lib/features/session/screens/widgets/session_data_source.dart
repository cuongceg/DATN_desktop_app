import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../models/session_model.dart';

/// Maps a list of [SessionModel] to a Syncfusion [CalendarDataSource].
///
/// Each session becomes one [Appointment] anchored at [SessionModel.displayTime]
/// (scheduledAt → startTime fallback). Sessions without a [displayTime] are skipped.
/// [Appointment.id] stores [SessionModel.id] so the widget layer can look up the
/// full model on tap without keeping a parallel list.
class SessionDataSource extends CalendarDataSource {
  /// Creates a [SessionDataSource] from [sessions] styled with [scheme].
  SessionDataSource(List<SessionModel> sessions, ColorScheme scheme) {
    appointments = sessions
        .where((SessionModel s) => s.displayTime != null)
        .map(
          (SessionModel s) => Appointment(
            startTime: s.displayTime!,
            endTime: s.displayEndTime ?? s.displayTime!.add(const Duration(hours: 1)),
            subject: s.title,
            notes: s.className ?? '',
            color: _colorForStatus(s.status, scheme),
            id: s.id,
          ),
        )
        .toList();
  }

  Color _colorForStatus(SessionStatus status, ColorScheme scheme) =>
      switch (status) {
        SessionStatus.scheduled => scheme.primary,
        SessionStatus.ongoing => scheme.secondary,
        SessionStatus.completed => scheme.outline,
      };
}
