import 'package:app/utils/fit_parser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart'; // 添加此行以使用SharedPreferences

class RideHistory extends StatelessWidget {
  const RideHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('骑行记录'),
      ),
      body: const Column(
        children: [
          // 顶部骑行数据
          RideSummary(),
          // 骑行记录列表
          Expanded(
            child: RideHistoryList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 导入fit文件并存储在./history/下的逻辑
          final result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            // allowedExtensions: ['fit'], // Ensure no dot in the extension
          );

          if (result != null) {
            final file = File(result.files.single.path!);
            final appDir = await getApplicationDocumentsDirectory();
            final directory = Directory('${appDir.path}/history');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            final newFile = await file
                .copy('${directory.path}/${result.files.single.name}');

            // 解析fit文件并更新数据
            final fitData = FitParser.parseFitFile(newFile.path);
            await updateRideData(fitData);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('文件已导入: ${newFile.path}')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('未选择文件')),
            );
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
  const RideHistoryList({super.key});

  @override
  _RideHistoryListState createState() => _RideHistoryListState();
}

class _RideHistoryListState extends State<RideHistoryList> {
  List<Map<String, dynamic>> _rideHistory = [];

  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    final directory = await getApplicationDocumentsDirectory();
    final historyDir = Directory('${directory.path}/history');
    if (await historyDir.exists()) {
      final files = historyDir
          .listSync()
          .where((file) => file.path.endsWith('.fit'))
          .map((file) => file.path)
          .toList();
      final List<Map<String, dynamic>> history = [];
      for (var path in files) {
        final fitData = FitParser.parseFitFile(path);
        history.add(fitData);
      }
      setState(() {
        _rideHistory = history;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _rideHistory.isEmpty
        ? const Center(child: Text('没有骑行记录'))
        : ListView.builder(
            itemCount: _rideHistory.length,
            itemBuilder: (context, index) {
              final ride = _rideHistory[index];
              return Card(
                child: ListTile(
                  leading: Image.asset('path/to/thumbnail'), // 替换为实际路径
                  title: Text('骑行标题: ${ride['title']}'), // 替换为实际数据
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('日期时间: ${ride['date']}'), // 替换为实际数据
                      Text(
                          '里程: ${ride['distance']} km 耗时: ${ride['time']} 分钟 均速: ${ride['speed']} km/h'), // 替换为实际数据
                    ],
                  ),
                ),
              );
            },
          );
  }
}
