class FileItem {
  final String id;
  final String name;
  final bool isFolder;
  final String modifiedDate;
  final String modifiedBy;
  final String path;
  final List<FileItem> children;

  FileItem({
    required this.id,
    required this.name,
    this.isFolder = false,
    this.modifiedDate = '',
    this.modifiedBy = '',
    this.path = '',
    this.children = const [],
  });
}
