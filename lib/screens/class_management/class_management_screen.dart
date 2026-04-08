import 'package:flutter/material.dart';

import '../../models/classroom.dart';
import '../../widgets/class_card_student.dart';
import '../../widgets/class_card_teacher.dart';

class ClassManagementScreen extends StatelessWidget {
  const ClassManagementScreen({
    super.key,
    required this.isTeacher,
    required this.classrooms,
  });

  final bool isTeacher;
  final List<Classroom> classrooms;

  @override
  Widget build(BuildContext context) {
    final availableTeams = classrooms
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
              onPressed: () {},
              icon: Icon(isTeacher ? Icons.add : Icons.login),
              label: Text(isTeacher ? 'Create New Class' : 'Join Class'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
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
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 2.05,
                ),
                itemCount: classrooms.length,
                itemBuilder: (context, index) {
                  final classroom = classrooms[index];
                  if (isTeacher) {
                    return ClassCardTeacher(
                      classroom: classroom,
                      availableTeams: availableTeams,
                    );
                  }
                  return ClassCardStudent(
                    classroom: classroom,
                    availableTeams: availableTeams,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
