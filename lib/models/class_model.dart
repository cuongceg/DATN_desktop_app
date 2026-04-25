class ClassModel {
  const ClassModel({
    required this.id,
    required this.teacherId,
    this.classCode,
    required this.name,
    this.description,
    this.createdAt,
    this.studentCount,
  });

  final String id;
  final String teacherId;
  final String? classCode;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final int? studentCount;

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      classCode: json['class_code'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      studentCount: json['student_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_id': teacherId,
      'class_code': classCode,
      'name': name,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'student_count': studentCount,
    };
  }

  ClassModel copyWith({
    String? id,
    String? teacherId,
    String? classCode,
    String? name,
    String? description,
    DateTime? createdAt,
    int? studentCount,
  }) {
    return ClassModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      classCode: classCode ?? this.classCode,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      studentCount: studentCount ?? this.studentCount,
    );
  }
}
