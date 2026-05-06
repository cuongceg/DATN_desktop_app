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
    required this.onArchive,
    required this.onActivate,
    required this.onDelete,
  });

  /// The classroom to display.
  final ClassroomEntity classroom;

  /// Called when the card body is tapped.
  final VoidCallback onTap;

  /// Called when the teacher selects "Edit".
  final VoidCallback onEdit;

  /// Called when the teacher selects "Archive".
  final VoidCallback onArchive;

  /// Called when the teacher selects "Activate".
  final VoidCallback onActivate;

  /// Called when the teacher selects "Delete".
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = (classroom.status ?? 'active').toLowerCase();
    final isArchived = status == 'archived';

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
              case _Action.archive:
                onArchive();
              case _Action.activate:
                onActivate();
              case _Action.delete:
                onDelete();
            }
          },
          itemBuilder: (context) {
            if (isArchived) {
              return const [
                PopupMenuItem<_Action>(
                  value: _Action.activate,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.play_circle_outline),
                    title: Text('Kích hoạt lớp'),
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
              ];
            }

            return const [
              PopupMenuItem<_Action>(
                value: _Action.edit,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Chỉnh sửa'),
                ),
              ),
              PopupMenuItem<_Action>(
                value: _Action.archive,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Lưu trữ lớp'),
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
            ];
          },
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }
}

enum _Action { edit, archive, activate, delete }
