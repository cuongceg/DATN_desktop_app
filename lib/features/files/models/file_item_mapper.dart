import 'package:flutter_web_rtc/models/file_item.dart';
import 'category_model.dart';
import 'class_file_model.dart';
import 'folder_model.dart';

const _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _shortDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  return '$d ${_monthAbbr[dt.month - 1]}';
}

/// Category → FileItem (isFolder: true, children = mapped folders).
FileItem categoryToFileItem(CategoryModel c, List<FolderModel> folders) {
  return FileItem(
    id: c.id,
    name: c.name,
    isFolder: true,
    modifiedDate: _shortDate(c.createdAt),
    modifiedBy: '',
    children: folders.map((f) => folderToFileItem(f, const [])).toList(),
  );
}

/// Folder → FileItem (isFolder: true, children = mapped files).
FileItem folderToFileItem(FolderModel f, List<ClassFileModel> files) {
  return FileItem(
    id: f.id,
    name: f.name,
    isFolder: true,
    modifiedDate: _shortDate(f.createdAt),
    modifiedBy: '',
    children: files.map(classFileToFileItem).toList(),
  );
}

/// ClassFile → FileItem (isFolder: false).
FileItem classFileToFileItem(ClassFileModel f) {
  return FileItem(
    id: f.id,
    name: f.originalName,
    isFolder: false,
    modifiedDate: _shortDate(f.createdAt),
    modifiedBy: f.uploadedByName,
  );
}
