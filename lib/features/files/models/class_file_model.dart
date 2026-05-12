class ClassFileModel {
  final String id;
  final String originalName;
  final String? mimeType;
  final int? sizeBytes;
  final String uploadedByName;
  final DateTime createdAt;

  const ClassFileModel({
    required this.id,
    required this.originalName,
    this.mimeType,
    this.sizeBytes,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory ClassFileModel.fromJson(Map<String, dynamic> json) => ClassFileModel(
    id: json['id'] as String,
    originalName: json['original_name'] as String,
    mimeType: json['mime_type'] as String?,
    sizeBytes: json['size_bytes'] == null ? 0 : int.tryParse(json['size_bytes'].toString()) ?? 0,
    uploadedByName: json['uploaded_by_name'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
