import 'package:app/utils/fit_parser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'dart:io';
import 'package:app/utils/storage.dart';
import 'package:fl_chart/fl_chart.dart'; // 用于图表
import 'package:flutter_map/flutter_map.dart'; // 用于地图

class RideHistory extends StatefulWidget {
  const RideHistory({super.key});

  @override
  State<RideHistory> createState() => _RideHistoryState();
}

class _RideHistoryState extends State<RideHistory> {
  List<dynamic> histories = [];
  Map<String, dynamic> rideData = {};

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
      rideData = histories
          .map((e) => parseFitDataToSummary(e))
          .fold<Map<String, dynamic>>(
        {'totalDistance': 0.0, 'totalRides': 0, 'totalTime': 0},
        (value, element) {
          return {
            'totalDistance':
                value['totalDistance'] + (element['total_distance'] ?? 0.0),
            'totalRides': value['totalRides'] + 1,
            'totalTime':
                value['totalTime'] + (element['total_elapsed_time'] ?? 0),
          };
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('骑行记录')),
      body: Column(
        children: [
          RideSummary(rideData: rideData),
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
          final result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: true,
          );
          if (result != null) {
            for (var file in result.files) {
              final path = File(file.path!);
              final fitFile = await path.readAsBytes();
              await Storage().saveFitFile(
                path.path.split('/').last,
                fitFile,
              );
            }
            _loadFitFiles();
          }
        },
        child: const Icon(Icons.file_upload),
      ),
    );
  }
}

class RideSummary extends StatefulWidget {
  final Map<String, dynamic> rideData;
  const RideSummary({super.key, required this.rideData});

  @override
  State<RideSummary> createState() => RideSummaryState();
}

class RideSummaryState extends State<RideSummary> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.rideData;
    final totalDistance = data['totalDistance'];
    final totalRides = data['totalRides'];
    final totalTime = data['totalTime'];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
              '总里程: ${((totalDistance ?? 0.0) / 1000.0).toStringAsFixed(2)} km'),
          Text('总次数: $totalRides 次'),
          Text('总时间: ${((totalTime ?? 0) / 60.0).toStringAsFixed(2)} 分钟'),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final sortedHistory = List.from(widget.history)
      ..sort((a, b) => (parseFitDataToSummary(b)['start_time'] ?? 0)
          .compareTo(parseFitDataToSummary(a)['start_time'] ?? 0));

    return sortedHistory.isEmpty
        ? const Center(child: Text('没有骑行记录'))
        : ListView.builder(
            itemCount: sortedHistory.length,
            itemBuilder: (context, index) {
              final summary = parseFitDataToSummary(sortedHistory[index]);
              return Card(
                child: ListTile(
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: CustomPaint(
                      painter: RidePathPainter(
                          parseFitDataToRoute(sortedHistory[index])),
                    ),
                  ),
                  title: Text('骑行标题: ${summary['title']}'), // 替换为实际数据
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '日期时间: ${DateTime.fromMillisecondsSinceEpoch((summary['start_time'] * 1000 + 631065600000).toInt()).toLocal().toString().replaceFirst('T', ' ')}',
                      ), // 替换为实际数据
                      Text(
                        '里程: ${(summary['total_distance'] / 1000.0).toStringAsFixed(2)} km 耗时: ${(summary['total_elapsed_time'] / 60).toStringAsFixed(2)} 分钟 均速: ${(summary['avg_speed'] * 3.6).toStringAsFixed(2)} km/h',
                      ), // 替换为实际数据
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RideDetailPage(
                          rideData: sortedHistory[index],
                        ),
                      ),
                    );
                  },
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
                              final file = File(sortedHistory[index]['path']);
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

class RideDetailPage extends StatelessWidget {
  final Map<String, dynamic> rideData;

  const RideDetailPage({super.key, required this.rideData});

  @override
  Widget build(BuildContext context) {
    final routePoints = parseFitDataToRoute(rideData);
    final summary = parseFitDataToSummary(rideData);

    return Scaffold(
      appBar: AppBar(title: const Text('骑行详情')),
      body: Column(
        children: [
          // 地图展示
          Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: routePoints.isNotEmpty
                    ? LatLng(routePoints[0].latitude, routePoints[0].longitude)
                    : const LatLng(0, 0),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 数据展示
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '骑行标题: ${summary['title'] ?? '未知'}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '日期时间: ${DateTime.fromMillisecondsSinceEpoch((summary['start_time'] * 1000 + 631065600000).toInt()).toLocal()}',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '总里程: ${(summary['total_distance'] / 1000.0).toStringAsFixed(2)} km\n'
                      '总耗时: ${(summary['total_elapsed_time'] / 60).toStringAsFixed(2)} 分钟\n'
                      '均速: ${(summary['avg_speed'] * 3.6).toStringAsFixed(2)} km/h\n'
                      '最大速度: ${(summary['max_speed'] * 3.6).toStringAsFixed(2)} km/h\n'
                      '总爬升: ${summary['total_ascent']} m\n'
                      '总下降: ${summary['total_descent']} m\n'
                      '平均心率: ${summary['avg_heart_rate'] ?? '未知'} bpm\n'
                      '最大心率: ${summary['max_heart_rate'] ?? '未知'} bpm\n'
                      '平均功率: ${summary['avg_power'] ?? '未知'} W\n'
                      '最大功率: ${summary['max_power'] ?? '未知'} W\n'
                      '总卡路里: ${summary['total_calories'] ?? '未知'} kcal',
                    ),
                    const SizedBox(height: 20),
                    // 图表展示
                    const Text(
                      '速度变化图',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: routePoints
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(e.key.toDouble(),
                                      summary['avg_speed'] * 3.6))
                                  .toList(),
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 4,
                            ),
                          ],
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '海拔变化图',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: routePoints
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(e.key.toDouble(),
                                      summary['avg_altitude'] ?? 0.0))
                                  .toList(),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 4,
                            ),
                          ],
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
