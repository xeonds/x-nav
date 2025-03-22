import 'package:app/utils/fit_parser.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/utils/storage.dart';

class RideHistory extends StatefulWidget {
  const RideHistory({super.key});

  @override
  State<RideHistory> createState() => _RideHistoryState();
}

class _RideHistoryState extends State<RideHistory> {
  List<dynamic> histories = [];

  @override
  void initState() {
    super.initState();
    _loadFitFiles();
  }

  // TODO: 修复fit文件解析错误
  Future<void> _loadFitFiles() async {
    final files = await Storage().getFitFiles();
    setState(() {
      histories = files.map((file) {
        try {
          return {"path": file.path, ...parseFitFile(file.path)};
        } catch (e) {
          // 记录错误并返回一个空的 Map 以避免异常
          if (kDebugMode) {
            print('Error parsing file ${file.path}: $e');
          }
          return {"path": file.path};
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('骑行记录')),
      body: Column(
        children: [
          const RideSummary(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadFitFiles,
              child: RideHistoryList(history: histories),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final file = await FilePicker.platform.pickFiles(
            type: FileType.any,
          );
          if (file != null) {
            final path = File(file.files.single.path!);
            final fitFile = await path.readAsBytes();
            await Storage().saveFitFile(
              path.path.split('/').last,
              fitFile,
            );
            _loadFitFiles();
          }
        },
        child: const Icon(Icons.file_upload),
      ),
    );
  }

  Future<void> updateRideData(Map<String, dynamic> fitData) async {
    final prefs = await SharedPreferences.getInstance();
    final totalDistance = prefs.getDouble('totalDistance') ?? 0.0;
    final totalRides = prefs.getInt('totalRides') ?? 0;
    final totalTime = prefs.getInt('totalTime') ?? 0;

    await prefs.setDouble('totalDistance', totalDistance + fitData['distance']);
    await prefs.setInt('totalRides', totalRides + 1);
    await prefs.setInt('totalTime', totalTime + (fitData['time'] as int));
  }
}

class RideSummary extends StatelessWidget {
  const RideSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadRideData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('加载数据出错');
        } else {
          final data = snapshot.data as Map<String, dynamic>;
          final totalDistance = data['totalDistance'];
          final totalRides = data['totalRides'];
          final totalTime = data['totalTime'];

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text('总里程: $totalDistance km'),
                Text('总次数: $totalRides 次'),
                Text('总时间: $totalTime 分钟'),
              ],
            ),
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> _loadRideData() async {
    final prefs = await SharedPreferences.getInstance();
    final totalDistance = prefs.getDouble('totalDistance') ?? 0.0;
    final totalRides = prefs.getInt('totalRides') ?? 0;
    final totalTime = prefs.getInt('totalTime') ?? 0;

    return {
      'totalDistance': totalDistance,
      'totalRides': totalRides,
      'totalTime': totalTime,
    };
  }
}

class RideHistoryList extends StatefulWidget {
  final List<dynamic> history;
  const RideHistoryList({super.key, required this.history});

  @override
  State<RideHistoryList> createState() => RideHistoryListState();
}

class RideHistoryListState extends State<RideHistoryList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.history.isEmpty
        ? const Center(child: Text('没有骑行记录'))
        : ListView.builder(
            itemCount: widget.history.length,
            itemBuilder: (context, index) {
              final ride = widget.history[index];
              return Card(
                child: ListTile(
                  leading: Image.asset('path/to/thumbnail'), // 替换为实际路径
                  title: Text('骑行标题: ${ride['title']}'), // 替换为实际数据
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('日期时间: ${ride['date']}'), // 替换为实际数据
                      Text(
                        '里程: ${ride['distance']} km 耗时: ${ride['time']} 分钟 均速: ${ride['speed']} km/h',
                      ), // 替换为实际数据
                    ],
                  ),
                  onLongPress: () {
                    showMenu(
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: [
                        PopupMenuItem(
                          child: const Text('删除'),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('确认删除'),
                                  content: const Text('确定要删除这条骑行记录吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('删除'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirm == true) {
                              // delete file by path
                              final file = File(ride['path']);
                              await file.delete();
                              setState(() {
                                widget.history.removeAt(index);
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          );
  }
}
