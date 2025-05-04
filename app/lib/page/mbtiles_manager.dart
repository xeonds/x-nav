import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MbtilesManagerPage extends StatefulWidget {
  const MbtilesManagerPage({Key? key}) : super(key: key);

  @override
  State<MbtilesManagerPage> createState() => _MbtilesManagerPageState();
}

class _MbtilesManagerPageState extends State<MbtilesManagerPage> {
  List<String> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<Directory> _mbtilesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'mbtiles'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _loadFiles() async {
    final dir = await _mbtilesDir();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mbtiles'))
        .map((f) => f.path)
        .toList();
    setState(() {
      _files = files;
    });
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      // allowedExtensions: ['mbtiles'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final src = File(result.files.single.path!);
      final dir = await _mbtilesDir();
      final destPath = p.join(dir.path, p.basename(src.path));
      await src.copy(destPath);
      await _loadFiles();
    }
  }

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      await _loadFiles();
    }
  }

  Future<void> _shareFile(String path) async {
    await Share.shareXFiles([XFile(path)], text: 'MBTiles 文件');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('离线地图管理')),
      body: _files.isEmpty
          ? const Center(child: Text('暂无 MBTiles 文件，请导入'))
          : ListView.separated(
              itemCount: _files.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final path = _files[index];
                final name = p.basename(path);
                return ListTile(
                  title: Text(name),
                  subtitle: Text(path),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => _shareFile(path),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('删除确认'),
                              content: Text('确定删除 $name 吗？'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('取消')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('删除')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _deleteFile(path);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importFile,
        child: const Icon(Icons.add),
        tooltip: '导入 MBTiles',
      ),
    );
  }
}
