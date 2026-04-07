class Classroom {
  const Classroom({
    required this.id,
    required this.name,
    this.studentCount,
    this.classCode,
    this.teacherName,
    this.progress,
  });

  final String id;
  final String name;
  final int? studentCount;
  final String? classCode;
  final String? teacherName;
  final double? progress;
}
