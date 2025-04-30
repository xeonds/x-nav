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
              ListTile(
                title: const Text('About'),
                subtitle: const Text('Version 1.0.0'),
                onTap: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("About"),
                      content: Text("Fish touching <` ><"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('man'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('whatcanisay'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(title: const Text('Man!ual')),
                                  body: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        '''
## (开发文档 || 日志).contains(画饼 | 幽默bug | 拟人算法)

匹配目前对于同一个骑行记录只能匹配一个赛段一次，也就是说绕圈的话只能匹配到第一圈，后续解决（咕
> 刚修了下算法现在应该好了不过顺带的影响是为了保证匹配到所以匹配准确度可能会稍微降低一点

地图有缓存机制，会下载地图到应用存储中，后续启动应用时已加载的地图无网络也可以随时使用

地图显示若出现错误了则可以考虑使用清除地图缓存功能然后重启app

另外地图目前使用的是openstreetmap的tile api所以需要挂梯子而且对于国内的路段情况更新也不是很及时后面有机会了整几个离线地图包

热力图功能现在暂时别用会卡死主要是用的叠加层库没有考虑到这种数据量特别大的情况后面有时间了我自己写一个热力图叠加层算法（咕咕

路径规划功能用了在线的OSRM提供的免费公益api但是它用的路网数据也是openstreetmap的所以也存在国内路段更新不及时的问题导致有时候自动规划会给一些很神金的结果而且我设置的是骑行规划但是算法好像觉得国内的自行车能上高速导致有时候会给一些幽默结果

关于GPX路线数据的问题因为用的库疑似有点bug所以暂时不支持路段命名功能等后面自己写个实现给这功能修好再说（咕

每一个路段都是默认作为赛段参与骑行历史记录分析所以想创建赛段直接画个路线就好缺点就是容易和正经路线混成依托后面想个法子搓个分类整理系统吧（咕咕咕

爬升计算目前使用遍历骑行记录对大于0的爬升段进行累计求和的算法但是和码表给出的骑行总结的信息似乎有些许差异后续研究研究别的像人点的算法（咕咕

数据备份和恢复目前不可用，实现有丶问题我后面再修复

UI有点丑因为我完全没设计纯在堆功能而且我审美也就到这了（不是

FIT和GPX导入随时可用不需要等加载完成因为原理上是将原始文件导入app内置存储但是需要手动触发重新加载才能把它们也纳入本次计算

最大速度和最大功率的计算使用滑动区间法，也就是按照区间长度遍历每一个骑行记录的每一个子段，也就导致了非常大的计算量所以加载才这么慢而且为了避免一致性的问题所以目前还没有设计缓存系统等后面大体架构确认了再说（咕咕咕

xeonds.timestamp() == 20250425170741
                                  ''',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text('manual out'),
                        ),
                      ],
                    );
                  },
                ),
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
