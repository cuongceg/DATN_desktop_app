import 'class_member.dart';
import 'class_model.dart';

class ClassDetails {
  const ClassDetails({
    required this.classroom,
    required this.members,
    required this.totalMembers,
  });

  final ClassModel classroom;
  final List<ClassMember> members;
  final int totalMembers;

  factory ClassDetails.fromJson(Map<String, dynamic> json) {
    final classJson = json['class'] as Map<String, dynamic>? ?? const {};
    final membersRaw = json['members'] as List<dynamic>? ?? const [];
    return ClassDetails(
      classroom: ClassModel.fromJson(classJson),
      members: membersRaw
          .whereType<Map<String, dynamic>>()
          .map(ClassMember.fromJson)
          .toList(growable: false),
      totalMembers: json['total_members'] as int? ?? (membersRaw.length),
    );
  }

  ClassDetails copyWith({
    ClassModel? classroom,
    List<ClassMember>? members,
    int? totalMembers,
  }) {
    return ClassDetails(
      classroom: classroom ?? this.classroom,
      members: members ?? this.members,
      totalMembers: totalMembers ?? this.totalMembers,
    );
  }
}
