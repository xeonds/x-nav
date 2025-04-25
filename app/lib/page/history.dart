import 'dart:io';

import 'package:app/component/data.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/path_utils.dart'
    show RideScore, SegmentScore, initCenter, initZoom, parseSegmentToScore;
import 'package:app/utils/storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart'; // 用于图表
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // 用于地图
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
            child: RideHistoryList(history: dataLoader.fitData),
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
          Text('总时间: ${secondToFormatTime(totalTime ?? 0.0)}'),
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

    bool isMultiSelectMode = false;
    Set<int> selectedIndices = {};

    return sortedHistory.isEmpty
        ? const Center(child: Text('没有骑行记录'))
        : StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  if (isMultiSelectMode)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '已选择 ${selectedIndices.length} 项',
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认删除'),
                                  content: const Text('确定要删除选中的骑行记录吗？'),
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
                                ),
                              );
                              if (confirm == true) {
                                for (var index in selectedIndices) {
                                  final rideData = sortedHistory[index];
                                  await File(rideData['path']).delete();
                                }
                                await DataLoader().loadHistoryData();
                                setState(() {
                                  selectedIndices.clear();
                                  isMultiSelectMode = false;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: sortedHistory.length,
                      itemBuilder: (context, index) {
                        final isSelected = selectedIndices.contains(index);
                        return GestureDetector(
                          onLongPress: () {
                            setState(() {
                              isMultiSelectMode = true;
                              selectedIndices.add(index);
                            });
                          },
                          onTap: () {
                            if (isMultiSelectMode) {
                              setState(() {
                                if (isSelected) {
                                  selectedIndices.remove(index);
                                  if (selectedIndices.isEmpty) {
                                    isMultiSelectMode = false;
                                  }
                                } else {
                                  selectedIndices.add(index);
                                }
                              });
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RideDetailPage(
                                    rideData: sortedHistory[index],
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            color: isSelected
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.transparent,
                            child: RideHistoryCard(
                              rideData: sortedHistory[index],
                              onTap: () {
                                if (!isMultiSelectMode) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => RideDetailPage(
                                        rideData: sortedHistory[index],
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
  const RideDetailPage({super.key, required this.rideData});

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
    final timestamp = getTimestampFromDataMessage(rideData['sessions'][0]);
    final bestScore = dataLoader.bestScoreAt[timestamp]!;
    final bestScoreDisplay = bestScore.getBestData();
    final bestScoreTillNow = dataLoader.bestScore[timestamp]!;
    // 计算最佳成绩
    final newBest = bestScoreTillNow.getBetterDataDiff(bestScore);
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
              onPressed: () async {
                final file = File(rideData['path']);
                try {
                  await Share.shareXFiles(
                      [XFile(file.path, mimeType: 'application/fit')],
                      text: 'Sharing FIT file');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to share FIT file: $e'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.file_upload)),
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
                    tileProvider: dataLoader.tileProvider,
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
                          parseFitTimestampToDateTimeString(
                              rideScore.summary['start_time']),
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
                                              segment.segment.segmentIndex]!
                                          .getPositionTillCurrentIndex(
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
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SegmentDetailPage(
                                      segment: segment,
                                      rideScore: rideScore,
                                      dataLoader: dataLoader,
                                    ),
                                  ),
                                );
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
                              subtitle: Text(value),
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
                        const SizedBox(height: 20),
                        const Text(
                          '查看自定义区间',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // TODO
                        // 滑动条，选择区间开始结束
                        // 固定地图，跟随滑动而缩放和重绘路线
                        // 点击地图打开SegmentDetailPage的子页面展示区间成绩信息
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

class SegmentDetailPage extends StatelessWidget {
  final SegmentScore segment;
  final RideScore rideScore;
  final DataLoader dataLoader;

  const SegmentDetailPage({
    super.key,
    required this.segment,
    required this.rideScore,
    required this.dataLoader,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final segmentIndex = segment.segment.segmentIndex;
    final bestSegment = dataLoader.bestSegment[segmentIndex];
    final segmentRecords = bestSegment?.dataList ?? [];
    final userRecordIndex =
        bestSegment?.getPositionTillCurrentIndex(segment.startTime.toInt()) ??
            -1;

    return Scaffold(
      appBar: AppBar(
        title: Text('赛段 ${segmentIndex + 1} 详情'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 赛段地图
          SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initCenter(segment.route),
                initialZoom: initZoom(segment.route) - 0.5,
                // interactiveFlags: InteractiveFlag.all,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  tileProvider: dataLoader.tileProvider,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: segment.route,
                      strokeWidth: 5.0,
                      color: Colors.orange,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: segment.route.first,
                      child: const Icon(Icons.circle,
                          color: Colors.green, size: 14),
                    ),
                    Marker(
                      point: segment.route.last,
                      child:
                          const Icon(Icons.circle, color: Colors.red, size: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 赛段基本信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    '赛段 ${segmentIndex + 1}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2, // 每行显示3个元素
                    shrinkWrap: true, // 适配内容高度
                    physics: const NeverScrollableScrollPhysics(), // 禁止滚动
                    childAspectRatio: 3,
                    children: [
                      Statistic(
                        data: segment.distance.toStringAsFixed(2),
                        label: 'km',
                        subtitle: '距离',
                      ),
                      Statistic(
                        data: secondToFormatTime(segment.duration),
                        label: '',
                        subtitle: '耗时',
                      ),
                      Statistic(
                        data: segment.avgSpeed.toStringAsFixed(2),
                        label: 'km/h',
                        subtitle: '均速',
                      ),
                      Statistic(
                        data: segment.avgSpeed.toStringAsFixed(2),
                        label: 'km/h',
                        subtitle: '平均速度',
                      ),
                      Statistic(
                        data: parseFitTimestampToDateTimeString(
                            segment.startTime),
                        subtitle: '开始时间',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // const SizedBox(height: 16),
          // // 速度图表
          // Text(
          //   '速度分布',
          //   style: TextStyle(
          //       fontWeight: FontWeight.bold,
          //       fontSize: 16,
          //       color: isDarkMode ? Colors.white : Colors.black),
          // ),
          // SizedBox(
          //   height: 180,
          //   child: LineChart(
          //     LineChartData(
          //       lineBarsData: [
          //         LineChartBarData(
          //           spots: List.generate(
          //             segment.route.length,
          //             (i) => FlSpot(
          //               segment.route[i].latitude,
          //               segment.route[i].latitude,
          //             ),
          //           ),
          //           isCurved: false,
          //           color: Colors.deepOrange,
          //           belowBarData: BarAreaData(
          //             show: true,
          //             color: Colors.deepOrange.withOpacity(0.3),
          //           ),
          //           dotData: FlDotData(show: false),
          //         ),
          //       ],
          //       titlesData: FlTitlesData(
          //         leftTitles: AxisTitles(
          //           sideTitles: SideTitles(
          //             showTitles: true,
          //             reservedSize: 40,
          //             getTitlesWidget: (value, meta) =>
          //                 Text('${value.toInt()} km/h'),
          //             interval: 10,
          //           ),
          //         ),
          //         bottomTitles: AxisTitles(
          //           sideTitles: SideTitles(
          //             showTitles: true,
          //             reservedSize: 20,
          //             interval: segment.distance / 5,
          //             getTitlesWidget: (value, meta) =>
          //                 Text('${value.toStringAsFixed(1)} km'),
          //           ),
          //         ),
          //         topTitles: AxisTitles(),
          //         rightTitles: AxisTitles(),
          //       ),
          //       borderData: FlBorderData(show: false),
          //       gridData: FlGridData(
          //         show: true,
          //         drawVerticalLine: true,
          //         drawHorizontalLine: true,
          //         horizontalInterval: 10,
          //         verticalInterval: 1,
          //         getDrawingHorizontalLine: (value) => FlLine(
          //           color: Colors.grey.withOpacity(0.5),
          //           strokeWidth: 0.5,
          //         ),
          //         getDrawingVerticalLine: (value) => FlLine(
          //           color: Colors.grey.withOpacity(0.5),
          //           strokeWidth: 0.5,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 16),
          // 排行榜
          Text(
            '排行榜',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black),
          ),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: segmentRecords.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final record = segmentRecords[idx];
                final isUser = idx == userRecordIndex;
                final position = bestSegment?.getPositionOfFullList(
                        record.item.startTime.toInt()) ??
                    0;
                return ListTile(
                  leading: Text(
                    '${position + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUser ? Colors.orange : null,
                    ),
                  ),
                  title: Text(
                    parseFitTimestampToDateTimeString(record.item.startTime),
                    style: TextStyle(
                      color: isUser ? Colors.orange : null,
                    ),
                  ),
                  subtitle: Text(
                    '耗时: ${secondToFormatTime(record.item.duration)}  均速: ${(record.item.avgSpeed).toStringAsFixed(2)} km/h',
                  ),
                  trailing: position == 0
                      ? const Icon(Icons.emoji_events, color: Colors.amber)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // 分享按钮
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('分享赛段成绩'),
              onPressed: () async {
                final text =
                    '我在赛段${segmentIndex + 1}骑行了${segment.distance.toStringAsFixed(2)}km，用时${secondToFormatTime(segment.duration)}，均速${segment.avgSpeed.toStringAsFixed(2)}km/h！';
                await Share.share(text);
              },
            ),
          ),
        ],
      ),
    );
  }
}
