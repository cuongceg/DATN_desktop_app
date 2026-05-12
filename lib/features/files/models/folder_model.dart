class FolderModel {
  final String id;
  final String name;
  final int fileCount;
  final DateTime createdAt;

  const FolderModel({
    required this.id,
    required this.name,
    required this.fileCount,
    required this.createdAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) => FolderModel(
    id: json['id'] as String,
    name: json['name'] as String,
    fileCount: (json['file_count'])?.toInt() ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
