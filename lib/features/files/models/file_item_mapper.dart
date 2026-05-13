import 'package:flutter_web_rtc/models/file_item.dart';
import 'package:intl/intl.dart';
import 'category_model.dart';
import 'class_file_model.dart';
import 'folder_model.dart';

final DateFormat _fullDateTimeFormat = DateFormat('dd/MM/yyyy - HH:mm:ss');

String _fullDateTime(DateTime dt) {
  return _fullDateTimeFormat.format(dt.toLocal());
}

/// Category → FileItem (isFolder: true, children = mapped folders).
FileItem categoryToFileItem(CategoryModel c, List<FolderModel> folders) {
  return FileItem(
    id: c.id,
    name: c.name,
    isFolder: true,
    modifiedDate: _fullDateTime(c.createdAt),
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
    modifiedDate: _fullDateTime(f.createdAt),
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
    modifiedDate: _fullDateTime(f.createdAt),
    modifiedBy: f.uploadedByName,
  );
}
