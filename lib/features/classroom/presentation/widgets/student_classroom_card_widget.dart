import 'package:flutter/material.dart';

import '../../domain/entities/classroom_entity.dart';
import 'classroom_card_widget.dart';

/// Classroom card for the student dashboard.
///
/// Uses [ClassroomCardWidget] without any trailing action menu.
/// Tapping the card opens the classroom channel.
class StudentClassroomCardWidget extends StatelessWidget {
  const StudentClassroomCardWidget({
    super.key,
    required this.classroom,
    required this.onTap,
  });

  /// The classroom to display.
  final ClassroomEntity classroom;

  /// Called when the card is tapped to enter the classroom.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClassroomCardWidget(classroom: classroom, onTap: onTap);
  }
}
