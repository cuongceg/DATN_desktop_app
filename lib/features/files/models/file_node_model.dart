class FileNodeModel {
  final String id;
  final String type; // "folder" | "file"
  final String name;
  final String path;
  final String? mimeType;
  final int? sizeBytes;
  final String createdAt;
  final String createdByName;

  const FileNodeModel({
    required this.id,
    required this.type,
    required this.name,
    required this.path,
    this.mimeType,
    this.sizeBytes,
    required this.createdAt,
    required this.createdByName,
  });

  bool get isFolder => type == 'folder';

  factory FileNodeModel.fromJson(Map<String, dynamic> json) => FileNodeModel(
    id: json['id'] as String,
    type: json['type'] as String,
    name: json['name'] as String,
    path: json['path'] as String,
    mimeType: json['mime_type'] as String?,
    sizeBytes:
        json['size_bytes'] == null
            ? null
            : int.tryParse(json['size_bytes'].toString()),
    createdAt: json['created_at'] as String,
    createdByName: json['created_by_name'] as String,
  );
}
