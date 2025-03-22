import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Storage {
  static final Storage _instance = Storage._internal();

  factory Storage() {
    return _instance;
  }

  Storage._internal();

  Future<Directory> _getHistoryDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final historyDir = Directory('${directory.path}/history');
    if (!await historyDir.exists()) {
      await historyDir.create(recursive: true);
    }
    return historyDir;
  }

  Future<Directory> _getRouteDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final routeDir = Directory('${directory.path}/route');
    if (!await routeDir.exists()) {
      await routeDir.create(recursive: true);
    }
    return routeDir;
  }

  Future<List<File>> getFitFiles() async {
    final historyDir = await _getHistoryDirectory();
    return historyDir.listSync().whereType<File>().toList();
  }

  Future<List<File>> getGpxFiles() async {
    final routeDir = await _getRouteDirectory();
    return routeDir.listSync().whereType<File>().toList();
  }

  Future<void> saveFitFile(String fileName, List<int> bytes) async {
    final historyDir = await _getHistoryDirectory();
    final file = File('${historyDir.path}/$fileName');
    await file.writeAsBytes(bytes);
  }

  Future<void> saveGpxFile(String fileName, List<int> bytes) async {
    final routeDir = await _getRouteDirectory();
    final file = File('${routeDir.path}/$fileName');
    await file.writeAsBytes(bytes);
  }
}
