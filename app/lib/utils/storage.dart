import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class Storage {
  static final Storage _instance = Storage._internal();
  static String? appDocPath;
  static Directory? appDocDir;

  factory Storage() {
    return _instance;
  }

  Storage._internal();

  static Future<void> initialize() async {
    if (appDocPath == null) {
      appDocDir = await getApplicationDocumentsDirectory();
      appDocPath = appDocDir!.path;
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
    // extension filter for .fit files
    return historyDir.existsSync()
        ? historyDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.fit'))
            .toList()
        : [];
  }

  List<File> getGpxFilesSync() {
    if (appDocPath == null) {
      throw Exception("Storage未初始化，请先 await Storage.initialize()");
    }
    final routeDir = Directory('$appDocPath/route');
    // extension filter for .gpx files
    return routeDir.existsSync()
        ? routeDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.gpx'))
            .toList()
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
    //final archive = Archive();
    //await _addDirToArchive(archive, appDocDir!, appDocPath!);
    //final zipData = ZipEncoder.encode(archive)!;
    final tmpDir = await getTemporaryDirectory();
    final zipFile = File(path.join(
        tmpDir.path, "backup_${DateTime.now().millisecondsSinceEpoch}.zip"));
    //await zipFile.writeAsBytes(zipData);
    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);
    await encoder.addDirectory(appDocDir!, includeDirName: false);
    encoder.close();
    try {
      await Share.shareXFiles(
          [XFile(zipFile.path, mimeType: 'application/zip')],
          text: 'Sharing backup file');
    } catch (e) {}
  }

  static Future<void> _addDirToArchive(
      Archive archive, Directory dir, String rootPath) async {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final data = await entity.readAsBytes();
        final relativePath = path.relative(entity.path, from: rootPath);
        archive.addFile(ArchiveFile(relativePath, data.length, data));
      }
    }
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
