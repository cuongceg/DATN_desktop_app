class CategoryModel {
  final String id;
  final String name;
  final int folderCount;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.folderCount,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    folderCount: (json['folder_count'] as num?)?.toInt() ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
