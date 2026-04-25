import 'package:flutter/material.dart';
import 'package:flutter_web_rtc/widgets/create_classroom_dialog.dart';

import '../../models/class_details.dart';
import '../../models/class_member.dart';
import '../../models/class_model.dart';
import '../../models/class_notification.dart';
import '../../models/user.dart';
import 'edit_class_screen.dart';
import 'student_join_class_screen.dart';
import '../../widgets/class_card_student.dart';
import '../../widgets/class_card_teacher.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({
    super.key,
    required this.isTeacher,
    required this.classrooms,
    required this.notifications,
    required this.isLoading,
    required this.onRefresh,
    required this.onCreateClass,
    required this.onSearchUsers,
    required this.onAddMembersToClass,
    required this.onUpdateClass,
    required this.onFetchClassDetails,
    required this.onAddMember,
    required this.onUpdateMemberRole,
    required this.onRemoveMember,
    required this.onDeleteClass,
    required this.onJoinClass,
    required this.currentThemeMode,
    required this.onThemeToggle,
  });

  final bool isTeacher;
  final List<ClassModel> classrooms;
  final List<ClassNotification> notifications;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final Future<ClassModel> Function({required String name, String? description})
  onCreateClass;
  final Future<List<User>> Function(String keyword) onSearchUsers;
  final Future<void> Function({
    required String classId,
    required List<String> studentIds,
  })
  onAddMembersToClass;
  final Future<ClassModel> Function({
    required ClassModel classModel,
    required String name,
    String? description,
  })
  onUpdateClass;
  final Future<ClassDetails> Function(String classId) onFetchClassDetails;
  final Future<ClassMember> Function({
    required String classId,
    required String userId,
    String permission,
  })
  onAddMember;
  final Future<ClassMember> Function({
    required String classId,
    required String userId,
    required String role,
  })
  onUpdateMemberRole;
  final Future<void> Function({required String classId, required String userId})
  onRemoveMember;
  final Future<void> Function(ClassModel classModel) onDeleteClass;
  final Future<ClassModel?> Function(String classId) onJoinClass;
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeToggle;

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  Future<void> _openCreateClassDialog() async {
    final result = await showDialog<Map<String, Object?>>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          CreateClassDialog(onSearchUsers: widget.onSearchUsers),
    );

    if (result == null) return;

    final name = (result['name'] as String?)?.trim() ?? '';
    final description = (result['description'] as String?)?.trim() ?? '';
    final members = (result['members'] as List<dynamic>? ?? const [])
        .whereType<User>()
        .toList(growable: false);
    if (name.isEmpty) return;

    try {
      final createdClass = await widget.onCreateClass(
        name: name,
        description: description.isEmpty ? null : description,
      );

      if (members.isNotEmpty) {
        await widget.onAddMembersToClass(
          classId: createdClass.id,
          studentIds: members.map((user) => user.id).toList(growable: false),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _editClass(ClassModel classModel) async {
    final updated = await Navigator.of(context).push<ClassModel>(
      MaterialPageRoute(
        builder: (context) => EditClassScreen(
          initialClass: classModel,
          fetchClassDetails: widget.onFetchClassDetails,
          searchUsers: widget.onSearchUsers,
          addMember: widget.onAddMember,
          updateMemberRole: widget.onUpdateMemberRole,
          removeMember: widget.onRemoveMember,
          saveClassInfo: ({required name, description}) {
            return widget.onUpdateClass(
              classModel: classModel,
              name: name,
              description: description,
            );
          },
        ),
      ),
    );

    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updated.name} updated successfully.')),
      );
    }
  }

  Future<void> _deleteClass(ClassModel classModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
          'Delete ${classModel.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.onDeleteClass(classModel);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${classModel.name} deleted.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTeams = widget.classrooms
        .map((classroom) => classroom.name)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'My Classes',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: widget.isTeacher
                  ? _openCreateClassDialog
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentJoinClassScreen(
                            joinedClasses: widget.classrooms,
                            notifications: widget.notifications,
                            onJoin: widget.onJoinClass,
                          ),
                        ),
                      );
                    },
              icon: Icon(widget.isTeacher ? Icons.add : Icons.login),
              label: Text(widget.isTeacher ? 'Create New Class' : 'Join Class'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: widget.isLoading
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 240),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width > 1760
                          ? 6
                          : width > 1520
                          ? 5
                          : width > 1240
                          ? 4
                          : width > 960
                          ? 3
                          : width > 680
                          ? 2
                          : 1;

                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 2.05,
                        ),
                        itemCount: widget.classrooms.length,
                        itemBuilder: (context, index) {
                          final classroom = widget.classrooms[index];
                          if (widget.isTeacher) {
                            return ClassCardTeacher(
                              classroom: classroom,
                              availableTeams: availableTeams,
                              currentThemeMode: widget.currentThemeMode,
                              onThemeToggle: widget.onThemeToggle,
                              onEdit: () => _editClass(classroom),
                              onDelete: () => _deleteClass(classroom),
                            );
                          }
                          return ClassCardStudent(
                            classroom: classroom,
                            availableTeams: availableTeams,
                            currentThemeMode: widget.currentThemeMode,
                            onThemeToggle: widget.onThemeToggle,
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
