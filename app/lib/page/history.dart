import 'package:app/utils/fit_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart' show LatLng;
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

  Future<void> _loadFitFiles() async {
    final files = await Storage().getFitFiles();
    setState(() {
      histories = files
          .map((file) =>
              {"path": file.path, ...parseFitFile(file.readAsBytesSync())})
          .toList();
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
            child: Row(
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
    final files = await Storage().getFitFiles();
    final res = files
        .map((file) =>
            {"path": file.path, ...parseFitFile(file.readAsBytesSync())})
        .map((e) => parseFitDataToSummary(e))
        .reduce((value, element) => {
              'totalDistance':
                  value['totalDistance'] + element['total_distance'],
              'totalRides': value['totalRides'] + 1,
              'totalTime': value['totalTime'] + element['total_elapsed_time'],
            })
        .cast<String, dynamic>();
    if (kDebugMode) {
      print(res);
    }
    return res;
  }
}

class RidePathPainter extends CustomPainter {
  final List<LatLng> points;

  RidePathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (points.isNotEmpty) {
      final path = Path();

      // 获取经纬度的最小值和最大值
      final minLat =
          points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      final maxLat =
          points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      final minLng =
          points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      final maxLng =
          points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

      // 计算缩放比例
      final scaleX = size.width / (maxLng - minLng);
      final scaleY = size.height / (maxLat - minLat);
      final scale = scaleX < scaleY ? scaleX : scaleY;

      // 计算偏移量
      final offsetX = (size.width - (maxLng - minLng) * scale) / 2;
      final offsetY = (size.height - (maxLat - minLat) * scale) / 2;

      // 移动到起点
      path.moveTo(
        (points[0].longitude - minLng) * scale + offsetX,
        (maxLat - points[0].latitude) * scale + offsetY,
      );

      // 绘制路径
      for (var point in points) {
        path.lineTo(
          (point.longitude - minLng) * scale + offsetX,
          (maxLat - point.latitude) * scale + offsetY,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 数据变化时触发重绘
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

  // 实现RidePathPainter

  @override
  Widget build(BuildContext context) {
    return widget.history.isEmpty
        ? const Center(child: Text('没有骑行记录'))
        : ListView.builder(
            itemCount: widget.history.length,
            itemBuilder: (context, index) {
              final summary = parseFitDataToSummary(widget.history[index]);
              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: CustomPaint(
                      painter: RidePathPainter(
                          parseFitDataToRoute(widget.history[index])),
                    ),
                  ),
                  title: Text('骑行标题: ${summary['title']}'), // 替换为实际数据
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '日期时间: ${DateTime.fromMillisecondsSinceEpoch((summary['start_time'] * 1000).toInt()).toLocal().toString().replaceFirst('T', ' ')}',
                      ), // 替换为实际数据
                      Text(
                        '里程: ${summary['total_distance'] / 1000.0} km 耗时: ${summary['total_elapsed_time'] / 60} 分钟 均速: ${summary['avg_speed'] * 3.6} km/h',
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
                              final file = File(summary['path']);
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
