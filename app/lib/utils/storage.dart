import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class Storage {
  static final Storage _instance = Storage._internal();
  static String? appDocPath;

  factory Storage() {
    return _instance;
  }

  Storage._internal();

  static Future<void> initialize() async {
    if (appDocPath == null) {
      final dir = await getApplicationDocumentsDirectory();
      appDocPath = dir.path;
    }
  }

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

  List<File> getFitFilesSync() {
    if (appDocPath == null) {
      throw Exception("Storage未初始化，请先 await Storage.initialize()");
    }
    final historyDir = Directory('$appDocPath/history');
    return historyDir.existsSync()
        ? historyDir.listSync().whereType<File>().toList()
        : [];
  }

  List<File> getGpxFilesSync() {
    if (appDocPath == null) {
      throw Exception("Storage未初始化，请先 await Storage.initialize()");
    }
    final routeDir = Directory('$appDocPath/route');
    return routeDir.existsSync()
        ? routeDir.listSync().whereType<File>().toList()
        : [];
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

  Future<void> createBackup() async {
    // create backup for gpx and fit files
    final gpxFiles = await getGpxFiles();
    final fitFiles = await getFitFiles();
    final docDir = await getApplicationDocumentsDirectory();
    final backupFile = File(path.join(docDir.path, 'backup.zip'));
    final encoder = ZipFileEncoder();
    encoder.create(backupFile.path);
    for (final file in fitFiles) {
      encoder.addFile(
        file,
        path.join('history', path.basename(file.path)),
      );
    }
    for (final file in gpxFiles) {
      encoder.addFile(
        file,
        path.join('route', path.basename(file.path)),
      );
    }
    encoder.close();
  }

  Future<void> restoreBackup(File backupFile) async {
    // restore gpx and fit files to appDocDir from zip
    final historyDir = await _getHistoryDirectory();
    final routeDir = await _getRouteDirectory();
    final archive = ZipDecoder().decodeBytes(backupFile.readAsBytesSync());
    for (final file in archive) {
      if (file.isFile) {
        final outFile = File(
          path.join(
            file.name.startsWith('history/') ? historyDir.path : routeDir.path,
            path.basename(file.name),
          ),
        );
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }
  }
}
