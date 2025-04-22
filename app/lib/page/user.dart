import 'dart:io';

import 'package:app/utils/data_loader.dart';
import 'package:app/utils/storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> loadPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
}

T getPreference<T>(String key, T defaultValue, SharedPreferences prefs) {
  if (prefs.containsKey(key)) {
    try {
      final value = prefs.get(key);
      if (value is T) {
        return value;
      } else {
        // If the type doesn't match, reset to default value
        setPreference(key, defaultValue, prefs);
        return defaultValue;
      }
    } catch (e) {
      // In case of any unexpected error, reset to default value
      setPreference(key, defaultValue, prefs);
      return defaultValue;
    }
  } else {
    return defaultValue;
  }
}

Future<void> setPreference<T>(
    String key, T value, SharedPreferences prefs) async {
  if (value is String) {
    await prefs.setString(key, value);
  } else if (value is int) {
    await prefs.setInt(key, value);
  } else if (value is double) {
    await prefs.setDouble(key, value);
  } else if (value is bool) {
    await prefs.setBool(key, value);
  } else if (value is List<String>) {
    await prefs.setStringList(key, value);
  }
}

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'X-Nav',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('Nav for enthusiasts'),
          // 功能1
          const SizedBox(height: 20),
          _buildSection(
            title: "Miscellaneous",
            children: [
              ListTile(
                title: const Text('重新加载分析所有数据'),
                subtitle: Text("点完了等会吧"),
                onTap: () async {
                  final dataLoader =
                      Provider.of<DataLoader>(context, listen: false);
                  dataLoader.initialize(); // 重新加载数据
                },
              ),
              ListTile(
                title: const Text('清除地图缓存'),
                subtitle: const Text("一般不需要使用"),
                onTap: () async {
                  final dir = Directory(
                    path.join(
                      (await getApplicationDocumentsDirectory()).absolute.path,
                      'fmtc',
                    ),
                  );
                  await dir.delete(recursive: true);
                },
              ),
              ListTile(
                title: const Text("数据备份"),
                subtitle: const Text("备份gpx和fit文件为一个压缩包"),
                onTap: () async {
                  await Storage().createBackup();
                  Share.shareXFiles(
                    [
                      XFile(
                        path.join(
                          (await getApplicationDocumentsDirectory())
                              .absolute
                              .path,
                          'backup.zip',
                        ),
                      )
                    ],
                    text: "备份文件",
                  );
                },
              ),
              ListTile(
                title: const Text("数据恢复"),
                subtitle: const Text("从备份压缩包中恢复gpx和fit文件"),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    allowMultiple: false,
                  );
                  if (result != null) {
                    final path = result.files.single.path!;
                    final file = File(path);
                    await Storage().restoreBackup(file);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("恢复完成"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              )
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: "MISC",
            children: [
              // ListTile(
              //   title: const Text('Notification'),
              //   onTap: () {},
              //   trailing: IconButton(
              //     icon: const Icon(Icons.arrow_forward),
              //     onPressed: () {},
              //   ),
              // ),
              // ListTile(
              //   title: const Text('Safety'),
              //   onTap: () {},
              //   trailing: IconButton(
              //     icon: const Icon(Icons.arrow_forward),
              //     onPressed: () {},
              //   ),
              // ),
              ListTile(
                title: const Text('About'),
                subtitle: const Text('Version 1.0.0'),
                onTap: () => showMessageDialog(
                    context, "About", "Fish touching <` >-<="),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Copyright 2025 xeonds'),
              Text('All rights reserved')
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Widget _buildListSubtitle(String text) => Row(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      )
    ]);

Widget _buildSection({String title = '', required List<Widget> children}) =>
    Card(
        child: Column(
            children: title != ''
                ? [
                    const SizedBox(height: 10),
                    _buildListSubtitle(title),
                    ...children
                  ]
                : [const SizedBox(height: 10), ...children]));

void showMessageDialog(BuildContext context, String title, String content) =>
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
void showTextInputDialog(BuildContext context, String title, String content,
        Function(String) ok) =>
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: content),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ok(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

void showRadioDialog(BuildContext context, String title, List<String> options,
        String selected, Function(String) ok) =>
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((e) => RadioListTile(
                      title: Text(e),
                      value: e,
                      groupValue: selected,
                      onChanged: (String? value) {
                        ok(value!);
                        Navigator.of(context).pop();
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
