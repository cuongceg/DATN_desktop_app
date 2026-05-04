import 'package:flutter/material.dart';

import '../../domain/entities/classroom_entity.dart';
import 'classroom_card_widget.dart';

/// Classroom card for the teacher dashboard.
///
/// Extends [ClassroomCardWidget] by adding a ⋮ popup menu with
/// **Edit** and **Delete** actions. Both are teacher-only operations.
class TeacherClassroomCardWidget extends StatelessWidget {
  const TeacherClassroomCardWidget({
    super.key,
    required this.classroom,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  /// The classroom to display.
  final ClassroomEntity classroom;

  /// Called when the card body is tapped.
  final VoidCallback onTap;

  /// Called when the teacher selects "Edit".
  final VoidCallback onEdit;

  /// Called when the teacher selects "Delete".
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClassroomCardWidget(
      classroom: classroom,
      onTap: onTap,
      trailingActions: Semantics(
        label: 'Tùy chọn lớp ${classroom.name}',
        child: PopupMenuButton<_Action>(
          tooltip: 'Tùy chọn lớp học',
          onSelected: (action) {
            switch (action) {
              case _Action.edit:
                onEdit();
              case _Action.delete:
                onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<_Action>(
              value: _Action.edit,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined),
                title: Text('Chỉnh sửa'),
              ),
            ),
            PopupMenuItem<_Action>(
              value: _Action.delete,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline),
                title: Text('Xóa lớp'),
              ),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }
}

enum _Action { edit, delete }
