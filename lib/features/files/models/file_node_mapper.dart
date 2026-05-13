import 'package:flutter_web_rtc/models/file_item.dart';
import 'package:intl/intl.dart';
import 'file_node_model.dart';

final DateFormat _fmt = DateFormat('dd/MM/yyyy - HH:mm:ss');

/// Maps a [FileNodeModel] from the API to a [FileItem] used by the UI.
FileItem fileNodeToFileItem(FileNodeModel node) {
  final dt = DateTime.tryParse(node.createdAt)?.toLocal();
  return FileItem(
    id: node.id,
    name: node.name,
    isFolder: node.isFolder,
    modifiedDate: dt != null ? _fmt.format(dt) : node.createdAt,
    modifiedBy: node.createdByName,
    path: node.path,
  );
}
