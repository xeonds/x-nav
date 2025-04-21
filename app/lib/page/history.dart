import 'dart:io';
import 'package:app/component/data.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/path_utils.dart'
    show
        RideScore,
        SegmentMatcher,
        initCenter,
        initZoom,
        latlngToDistance,
        parseSegmentToScore;
import 'package:app/utils/storage.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart'; // 用于图表
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // 用于地图
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';

class RideHistory extends StatefulWidget {
  const RideHistory({super.key});

  @override
  State<RideHistory> createState() => RideHistoryState();
}

class RideHistoryState extends State<RideHistory> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final dataloader = Provider.of<DataLoader>(context, listen: false);
    while (!dataloader.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataLoader = context.watch<DataLoader>(); // 监听 DataLoader 的状态

    return Scaffold(
      appBar: AppBar(title: const Text('骑行记录')),
      body: Column(
        children: [
          RideSummary(rideData: dataLoader.rideData),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await dataLoader.loadHistoryData();
                await dataLoader.loadRideData();
              },
              child: RideHistoryList(history: dataLoader.fitData),
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
              await Storage().saveFitFile(path.path.split('/').last, fitFile);
            }
            await DataLoader().loadHistoryData();
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
            '总里程: ${((totalDistance ?? 0.0) / 1000.0).toStringAsFixed(2)} km',
          ),
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
      ..sort(
        (a, b) => (parseFitDataToSummary(b)['start_time'] ?? 0).compareTo(
          parseFitDataToSummary(a)['start_time'] ?? 0,
        ),
      );

    return sortedHistory.isEmpty
        ? const Center(child: Text('没有骑行记录'))
        : ListView.builder(
            itemCount: sortedHistory.length,
            itemBuilder: (context, index) {
              return RideHistoryCard(
                rideData: sortedHistory[index],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          RideDetailPage(rideData: sortedHistory[index]),
                    ),
                  );
                },
              );
            },
          );
  }
}

class RideHistoryCard extends StatelessWidget {
  final Map<String, dynamic> rideData;
  final VoidCallback onTap;

  const RideHistoryCard({
    super.key,
    required this.rideData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final summary = parseFitDataToSummary(rideData);

    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(
            painter: RidePathPainter(parseFitDataToRoute(rideData)),
          ),
        ),
        title: Text('骑行标题: ${summary['title']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '日期时间: ${DateTime.fromMillisecondsSinceEpoch((summary['start_time'] * 1000 + 631065600000).toInt()).toLocal().toString().replaceFirst('T', ' ')}',
            ),
            Text(
              '里程: ${(summary['total_distance'] / 1000.0).toStringAsFixed(2)} km 耗时: ${(summary['total_elapsed_time'] / 60).toStringAsFixed(2)} 分钟 均速: ${(summary['avg_speed'] * 3.6).toStringAsFixed(2)} km/h',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class RideDetailPage extends StatefulWidget {
  final Map<String, dynamic> rideData;
  RideDetailPage({super.key, required this.rideData});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  late final Map<String, dynamic> rideData;
  late int highlightRouteIndex;

  @override
  void initState() {
    super.initState();
    rideData = widget.rideData;
    highlightRouteIndex = -1;
  }

  @override
  Widget build(BuildContext context) {
    final dataLoader = context.watch<DataLoader>(); // 监听 DataLoader 的状态
    List<List<LatLng>> routes = dataLoader.routes;

    final rideScore = RideScore(
      rideData: rideData,
      routes: routes,
    );
    final bestScoreDisplay = rideScore.bestScore.getBestData();
    final bestScoreTillNow =
        dataLoader.bestScore[rideData['sessions'][0].get('timestamp')]!;
    // 计算最佳成绩
    final newBest = bestScoreTillNow.getBetterDataDiff(rideScore.bestScore);
    final analysisOfSubRoutes = rideScore.segments
        .map((segment) => parseSegmentToScore(
              segment,
              rideData,
              rideScore.routePoints,
            ))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('骑行详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认删除'),
                  content: const Text('确定要删除这条骑行记录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await File(rideData['path']).delete();
                await DataLoader().loadHistoryData();
                await Future.wait([
                  DataLoader().loadRideData(),
                  DataLoader().loadSummaryData(),
                ]);
                Navigator.of(context).pop(); // 返回上一页
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 地图展示
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initCenter(rideScore.routePoints),
                initialZoom: initZoom(rideScore.routePoints),
              ),
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      highlightRouteIndex = -1;
                    });
                  },
                  child: TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: rideScore.routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                    ...analysisOfSubRoutes.map(
                      (segment) => Polyline(
                        points: segment.route,
                        strokeWidth: 4.0,
                        color: (highlightRouteIndex ==
                                segment.segment.startIndex) //fix
                            ? Colors.orange
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    ...analysisOfSubRoutes.map((segment) {
                      final index = segment.segment.startIndex;
                      return Marker(
                        point: LatLng(
                          segment.route[0].latitude,
                          segment.route[0].longitude,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              highlightRouteIndex = index;
                            });
                          },
                          child: Icon(
                            Icons.emoji_events,
                            color: (highlightRouteIndex == index)
                                ? Colors.transparent
                                : Colors.amber,
                            size: 30,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          // BottomSheet
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [0.2, 0.5, 1.0],
            builder: (context, scrollController) {
              final isDarkMode =
                  MediaQuery.of(context).platformBrightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 下拉把柄
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Text(
                          '骑行标题: ${rideScore.summary['title'] ?? '未知'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          () {
                            final dateTime =
                                DateTime.fromMillisecondsSinceEpoch(
                              (rideScore.summary['start_time'] * 1000 +
                                      631065600000)
                                  .toInt(),
                            ).toLocal();
                            final now = DateTime.now();
                            final difference = now.difference(dateTime).inDays;
                            if (difference == 0) {
                              return '今天 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                            } else if (difference == 1) {
                              return '昨天 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                            } else {
                              return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
                            }
                          }(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 3, // 每行显示3个元素
                          shrinkWrap: true, // 适配内容高度
                          physics: const NeverScrollableScrollPhysics(), // 禁止滚动
                          childAspectRatio: 1.8,
                          children: [
                            Statistic(
                              data:
                                  '${(rideScore.summary['total_distance'] / 1000.0).toStringAsFixed(2)}',
                              label: 'km',
                              subtitle: '总里程',
                            ),
                            Statistic(
                              data:
                                  '${(rideScore.summary['total_elapsed_time'] / 60).toStringAsFixed(2)}',
                              label: '分钟',
                              subtitle: '总耗时',
                            ),
                            Statistic(
                              data:
                                  '${(rideScore.summary['avg_speed'] * 3.6).toStringAsFixed(2)}',
                              label: 'km/h',
                              subtitle: '均速',
                            ),
                            Statistic(
                              data:
                                  '${(rideScore.summary['max_speed'] * 3.6).toStringAsFixed(2)}',
                              label: 'km/h',
                              subtitle: '最大速度',
                            ),
                            Statistic(
                              data: '${rideScore.summary['total_ascent']}',
                              label: 'm',
                              subtitle: '总爬升',
                            ),
                            Statistic(
                              data: '${rideScore.summary['total_descent']}',
                              label: 'm',
                              subtitle: '总下降',
                            ),
                            Statistic(
                              data:
                                  '${rideScore.summary['avg_heart_rate'] ?? '未知'}',
                              label: 'bpm',
                              subtitle: '平均心率',
                            ),
                            Statistic(
                              data:
                                  '${rideScore.summary['max_heart_rate'] ?? '未知'}',
                              label: 'bpm',
                              subtitle: '最大心率',
                            ),
                            Statistic(
                              data: '${rideScore.summary['avg_power'] ?? '未知'}',
                              label: 'W',
                              subtitle: '平均功率',
                            ),
                            Statistic(
                              data: '${rideScore.summary['max_power'] ?? '未知'}',
                              label: 'W',
                              subtitle: '最大功率',
                            ),
                            Statistic(
                              data:
                                  '${rideScore.summary['total_calories'] ?? '未知'}',
                              label: 'kcal',
                              subtitle: '总卡路里',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '成绩',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Statistic(
                              subtitle: "最佳成绩",
                              data: bestScoreDisplay.length.toString(),
                            ),
                            Statistic(
                              subtitle: "路段",
                              data: rideScore.segments.length.toString(),
                            ),
                            Statistic(
                                subtitle: "成就",
                                data: newBest.length.toString()),
                          ],
                        ),
                        const Text('路段'),
                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: analysisOfSubRoutes.map((segment) {
                            return ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    '路段 ${rideScore.segments.indexOf(segment.segment) + 1}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (dataLoader.bestSegment[
                                              segment.segment.segmentIndex]
                                          ?.getPosition(
                                              segment.startTime.toInt()) ==
                                      0)
                                    const Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '里程 ${segment.distance.toStringAsFixed(2)} km'
                                ' 耗时 ${secondToFormatTime(segment.duration)}'
                                ' 均速 ${segment.avgSpeed.toStringAsFixed(2)} km/h',
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () {
                                setState(() {
                                  highlightRouteIndex = rideScore.segments
                                      .indexOf(segment.segment);
                                });
                                // TODO: 赛段详情页面
                                // Navigator.of(context).push(
                                //   MaterialPageRoute(
                                //     builder: (context) => Scaffold(
                                //       body: FlutterMap(
                                //         options: MapOptions(
                                //           initialCenter: initCenter(
                                //             routePoints,
                                //           ),
                                //           initialZoom: initZoom(
                                //             routePoints,
                                //           ),
                                //         ),
                                //         children: [
                                //           TileLayer(
                                //             urlTemplate:
                                //                 "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                //           ),
                                //           PolylineLayer(
                                //             polylines: [
                                //               Polyline(
                                //                 points: routePoints,
                                //                 strokeWidth: 4.0,
                                //                 color: Colors.blue,
                                //               ),
                                //               Polyline(
                                //                 points: route,
                                //                 strokeWidth: 4.0,
                                //                 color: Colors.orange,
                                //               ),
                                //             ],
                                //           ),
                                //         ],
                                //       ),
                                //     ),
                                //   ),
                                // );
                              },
                            );
                          }).toList(),
                        ),
                        const Text('最佳成绩'),
                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: bestScoreDisplay.entries.map((entry) {
                            final key = entry.key;
                            final value = entry.value;
                            return ListTile(
                              title: Row(
                                children: [
                                  Text(key),
                                  if (newBest.containsKey(key))
                                    const Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                value is double
                                    ? value.toStringAsFixed(2)
                                    : value?.toString() ?? '未知',
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '速度',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 240,
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: () {
                                    const reductionFactor = 10;
                                    return List.generate(
                                      (rideScore.speed.length / reductionFactor)
                                          .ceil(),
                                      (index) => FlSpot(
                                        rideScore
                                            .distance[index * reductionFactor],
                                        rideScore
                                            .speed[index * reductionFactor],
                                      ),
                                    );
                                  }(),
                                  isCurved: false,
                                  color: Colors.deepOrange,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.deepOrange.withOpacity(0.3),
                                  ),
                                  dotData: FlDotData(show: false),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(),
                                leftTitles: AxisTitles(),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) =>
                                        Text('${value.toInt()} km/h'),
                                    interval: 10,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 20,
                                    interval:
                                        rideScore.summary['total_distance'] /
                                            5 /
                                            1000,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${value.toStringAsFixed(1)} km',
                                    ),
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                drawHorizontalLine: true,
                                horizontalInterval: 10,
                                verticalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.5),
                                  strokeWidth: 0.5,
                                ),
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.5),
                                  strokeWidth: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '海拔',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 240,
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: () {
                                    const reductionFactor = 10;
                                    return List.generate(
                                      (rideScore.altitude.length /
                                              reductionFactor)
                                          .ceil(),
                                      (index) => FlSpot(
                                        rideScore
                                            .distance[index * reductionFactor],
                                        rideScore
                                            .altitude[index * reductionFactor],
                                      ),
                                    );
                                  }(),
                                  isCurved: false,
                                  color: Colors.blueAccent,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.blueAccent.withOpacity(0.3),
                                  ),
                                  dotData: FlDotData(show: false),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                topTitles: AxisTitles(),
                                leftTitles: AxisTitles(),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) =>
                                        Text('${value.toInt()} m'),
                                    interval: 50,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 20,
                                    interval:
                                        rideScore.summary['total_distance'] /
                                            5 /
                                            1000,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${value.toStringAsFixed(1)} km',
                                    ),
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                drawHorizontalLine: true,
                                horizontalInterval: 50,
                                verticalInterval: 10,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.5),
                                  strokeWidth: 0.5,
                                ),
                                getDrawingVerticalLine: (value) => FlLine(
                                  color: Colors.grey.withOpacity(0.5),
                                  strokeWidth: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
