import 'dart:io';

import 'package:app/component/data.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/model.dart';
import 'package:app/utils/path_utils.dart'
    show RideScore, SegmentScore, initCenter, initZoom;
import 'package:app/utils/storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fit_tool/fit_tool.dart'
    show Message, RecordMessage, SessionMessage;
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
            // await DataLoader().loadHistoryData();
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
  final Map<String, List<Message>> history;
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
    // 将 Map<String, List<Message>> 转为 List<MapEntry<String, List<Message>>> 并按 startTime 降序排序
    final sortedHistory = widget.history.entries.toList()
      ..sort(
        (a, b) => (parseFitDataToSummary(b.value).startTime!)
            .compareTo(parseFitDataToSummary(a.value).startTime!),
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
                                  await File(sortedHistory[index].key).delete();
                                }
                                // await DataLoader().loadHistoryData();
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
                                        rideData: sortedHistory[index])),
                              );
                            }
                          },
                          child: Container(
                            color: isSelected
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.transparent,
                            child: RideHistoryCard(
                              rideData: sortedHistory[index].value,
                              onTap: () {
                                if (!isMultiSelectMode) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => RideDetailPage(
                                          rideData: sortedHistory[index]),
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
  final List<Message> rideData;
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
        title: Text(
            '${DateTime.fromMillisecondsSinceEpoch((summary.startTime! * 1000 + 631065600000).toInt()).toLocal().toString().replaceFirst('T', ' ')} 的骑行'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '里程: ${(summary.totalDistance! / 1000.0).toStringAsFixed(2)} km 耗时: ${(summary.totalElapsedTime! / 60).toStringAsFixed(2)} 分钟 均速: ${(summary.avgSpeed! * 3.6).toStringAsFixed(2)} km/h',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class RideDetailPage extends StatefulWidget {
  final MapEntry<String, List<Message>> rideData;
  const RideDetailPage({super.key, required this.rideData});

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  late final MapEntry<String, List<Message>> rideData;
  late final RideScore rideScore;
  late final DataLoader dataLoader;
  late int highlightRouteIndex;
  late RangeValues chartRange;

  @override
  void initState() {
    super.initState();
    dataLoader = DataLoader(); // 监听 DataLoader 的状态
    rideData = widget.rideData;
    highlightRouteIndex = -1;
    rideScore = RideScore(rideData: rideData.value, routes: dataLoader.routes);
    chartMaxX = rideScore.distance.isNotEmpty ? rideScore.distance.last : 0;
    chartRange = RangeValues(
      rideScore.distance.isNotEmpty ? rideScore.distance.first : 0,
      rideScore.distance.isNotEmpty ? rideScore.distance.last : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionMsg = rideData.value.whereType<SessionMessage>().first;
    final timestamp = timestampWithOffset(sessionMsg.timestamp!);
    late final BestScore bestScore, bestScoreTillNow;
    late final List<SegmentScore> analysisOfSubRoutes;
    if (!dataLoader.bestScoreLoaded) {
      bestScore = BestScore();
      bestScoreTillNow = BestScore();
      analysisOfSubRoutes = [];
    } else {
      bestScore = dataLoader.bestScoreAt[timestamp]!;
      bestScoreTillNow = dataLoader.bestScore[timestamp]!;
      analysisOfSubRoutes = dataLoader.subRoutesOfRoutes[timestamp]!;
    }
    final bestScoreDisplay = bestScore.getBestData();
    final newBest = bestScoreTillNow.getBetterDataDiff(bestScore);

    // right, dataanalysis page state
    final idx = selectedIndex.clamp(0, rideScore.distance.length - 1);
    final chartY = chartType == 0 ? rideScore.speed : rideScore.altitude;
    final chartX = rideScore.distance;
    // final chartX = xType == 0 ? rideScore.distance : rideScore.elapsedTime;
    final chartLabelY = chartType == 0 ? '速度 (km/h)' : '海拔 (m)';
    final chartLabelX = xType == 0 ? '里程 (km)' : '时间 (s)';
    final chartSpots = List.generate(
      chartX.length,
      (i) => FlSpot(chartX[i], chartY[i]),
    );

    // 只显示chartRange内的数据
    List<int> filteredIndices = [];
    for (int i = 0; i < chartX.length; i++) {
      if (chartX[i] >= chartRange.start && chartX[i] <= chartRange.end) {
        filteredIndices.add(i);
      }
    }
    final filteredChartSpots =
        filteredIndices.map((i) => FlSpot(chartX[i], chartY[i])).toList();
    final filteredRoutePoints = rideScore.routePoints.sublist(
      filteredIndices.isNotEmpty ? filteredIndices.first : 0,
      filteredIndices.isNotEmpty ? filteredIndices.last + 1 : 1,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('骑行详情'),
            if (!dataLoader.bestScoreLoaded) CircularProgressIndicator()
          ],
        ),
        actions: [
          IconButton(
              onPressed: () async {
                final file = File(widget.rideData.key);
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
                await File(widget.rideData.key).delete();
                // await DataLoader().loadHistoryData();
                // await Future.wait([
                //   DataLoader().loadRideData(),
                //   DataLoader().loadSummaryData(),
                // ]);
                Navigator.of(context).pop(); // 返回上一页
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 地图始终在上方
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initCenter(rideScore.routePoints),
                initialZoom: initZoom(rideScore.routePoints),
              ),
              children: [
                // GestureDetector(
                //   onTap: () {
                //     setState(() {
                //       highlightRouteIndex = -1;
                //     });
                //   },
                //   child:
                // ),
                TileLayer(
                  urlTemplate:
                      'https://map.iris.al/styles/basic-preview/512/{z}/{x}/{y}.png',
                  tileProvider: dataLoader.tileProvider,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: filteredRoutePoints.isNotEmpty
                          ? filteredRoutePoints
                          : rideScore.routePoints,
                      strokeWidth: 3.0,
                      color: Colors.deepOrange,
                    ),
                    ...analysisOfSubRoutes.map(
                      (segment) => Polyline(
                        points: segment.route,
                        strokeWidth: 4.0,
                        color:
                            (highlightRouteIndex == segment.segment.startIndex)
                                ? Colors.amberAccent
                                : Colors.transparent,
                      ),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    ...analysisOfSubRoutes.map(
                      (segment) {
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
                      },
                    ),
                    Marker(
                      point: rideScore.routePoints[idx],
                      child: NavPoint(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [0.2, 0.4, 0.5, 0.6, 1.0],
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
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: '成绩'),
                          Tab(text: '数据分析'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            // 左tab：原有内容
                            SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Text(
                                    //   '骑行标题: ${rideScore.summary['title'] ?? '未知'}',
                                    //   style: TextStyle(
                                    //     fontSize: 18,
                                    //     fontWeight: FontWeight.bold,
                                    //     color: isDarkMode
                                    //         ? Colors.white
                                    //         : Colors.black,
                                    //   ),
                                    // ),
                                    const SizedBox(height: 10),
                                    Text(
                                      parseFitTimestampToDateTimeString(
                                          DateTime(
                                              rideScore.summary.startTime!)),
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    GridView.count(
                                      crossAxisCount: 3, // 每行显示3个元素
                                      shrinkWrap: true, // 适配内容高度
                                      physics:
                                          const NeverScrollableScrollPhysics(), // 禁止滚动
                                      childAspectRatio: 1.8,
                                      children: [
                                        Statistic(
                                          data:
                                              '${(rideScore.summary.totalDistance! / 1000.0).toStringAsFixed(2)}',
                                          label: 'km',
                                          subtitle: '总里程',
                                        ),
                                        Statistic(
                                          data:
                                              '${(rideScore.summary.totalElapsedTime! / 60).toStringAsFixed(2)}',
                                          label: '分钟',
                                          subtitle: '总耗时',
                                        ),
                                        Statistic(
                                          data:
                                              '${(rideScore.summary.avgSpeed! * 3.6).toStringAsFixed(2)}',
                                          label: 'km/h',
                                          subtitle: '均速',
                                        ),
                                        Statistic(
                                          data:
                                              '${(rideScore.summary.maxSpeed! * 3.6).toStringAsFixed(2)}',
                                          label: 'km/h',
                                          subtitle: '最大速度',
                                        ),
                                        Statistic(
                                          data:
                                              '${rideScore.summary.totalAscent}',
                                          label: 'm',
                                          subtitle: '总爬升',
                                        ),
                                        Statistic(
                                          data:
                                              '${rideScore.summary.totalDescent}',
                                          label: 'm',
                                          subtitle: '总下降',
                                        ),
                                        Statistic(
                                          data:
                                              '${rideScore.summary.avgHeartRate ?? '未知'}',
                                          label: 'bpm',
                                          subtitle: '平均心率',
                                        ),
                                        Statistic(
                                          data:
                                              '${rideScore.summary.maxHeartRate ?? '未知'}',
                                          label: 'bpm',
                                          subtitle: '最大心率',
                                        ),
                                        Statistic(
                                          data:
                                              '${rideScore.summary.avgPower ?? '未知'}',
                                          label: 'W',
                                          subtitle: '平均功率',
                                        ),
                                        Statistic(
                                          data:
                                              '${rideScore.summary.maxPower ?? '未知'}',
                                          label: 'W',
                                          subtitle: '最大功率',
                                        ),
                                        Statistic(
                                          data:
                                              '${rideScore.summary.totalCalories ?? '未知'}',
                                          label: 'kcal',
                                          subtitle: '总卡路里',
                                        ),
                                      ],
                                    ),
                                    if (dataLoader.bestScoreLoaded) ...[
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Statistic(
                                            subtitle: "最佳成绩",
                                            data: bestScoreDisplay.length
                                                .toString(),
                                          ),
                                          Statistic(
                                            subtitle: "路段",
                                            data: analysisOfSubRoutes.length
                                                .toString(),
                                          ),
                                          Statistic(
                                              subtitle: "成就",
                                              data: (newBest.length +
                                                      analysisOfSubRoutes
                                                          .map((e) =>
                                                              dataLoader
                                                                  .bestSegment[e
                                                                      .segment
                                                                      .segmentIndex]!
                                                                  .getPositionTillCurrentIndex(e
                                                                      .startTime
                                                                      .toInt()) ==
                                                              0)
                                                          .toList()
                                                          .fold(
                                                              0,
                                                              (a, b) =>
                                                                  a +
                                                                  (b ? 1 : 0)))
                                                  .toString()),
                                        ],
                                      ),
                                      const Text('路段'),
                                      if (analysisOfSubRoutes.isEmpty)
                                        Center(
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text('No sub routes'),
                                          ),
                                        )
                                      else
                                        ListView(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: analysisOfSubRoutes
                                              .map((segment) {
                                            return ListTile(
                                              title: Row(
                                                children: [
                                                  Text(
                                                    '路段 ${segment.segment.segmentIndex + 1}',
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                  ),
                                                  if (dataLoader
                                                          .bestSegment[segment
                                                              .segment
                                                              .segmentIndex]!
                                                          .getPositionTillCurrentIndex(
                                                              segment.startTime
                                                                  .toInt()) ==
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
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  highlightRouteIndex = segment
                                                      .segment.segmentIndex;
                                                });
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        SegmentDetailPage(
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
                                      if (bestScoreDisplay.isEmpty)
                                        Center(
                                          child: const Padding(
                                            padding: EdgeInsets.all(8),
                                            child: Text('No best score'),
                                          ),
                                        )
                                      else
                                        ListView(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          children: bestScoreDisplay.entries
                                              .map((entry) {
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
                                    ],
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
                                                  (rideScore.speed.length /
                                                          reductionFactor)
                                                      .ceil(),
                                                  (index) => FlSpot(
                                                    rideScore.distance[index *
                                                        reductionFactor],
                                                    rideScore.speed[index *
                                                        reductionFactor],
                                                  ),
                                                );
                                              }(),
                                              isCurved: false,
                                              color: Colors.deepOrange,
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: Colors.deepOrange
                                                    .withOpacity(0.3),
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
                                                getTitlesWidget:
                                                    (value, meta) => Text(
                                                        '${value.toInt()} km/h'),
                                                interval: 10,
                                              ),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 20,
                                                interval: rideScore.summary
                                                        .totalDistance! /
                                                    5 /
                                                    1000,
                                                getTitlesWidget:
                                                    (value, meta) => Text(
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
                                            getDrawingHorizontalLine: (value) =>
                                                FlLine(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              strokeWidth: 0.5,
                                            ),
                                            getDrawingVerticalLine: (value) =>
                                                FlLine(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
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
                                                    rideScore.distance[index *
                                                        reductionFactor],
                                                    rideScore.altitude[index *
                                                        reductionFactor],
                                                  ),
                                                );
                                              }(),
                                              isCurved: false,
                                              color: Colors.blueAccent,
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: Colors.blueAccent
                                                    .withOpacity(0.3),
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
                                                getTitlesWidget: (value,
                                                        meta) =>
                                                    Text('${value.toInt()} m'),
                                                interval: 50,
                                              ),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 20,
                                                interval: rideScore.summary
                                                        .totalDistance! /
                                                    5 /
                                                    1000,
                                                getTitlesWidget:
                                                    (value, meta) => Text(
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
                                            getDrawingHorizontalLine: (value) =>
                                                FlLine(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
                                              strokeWidth: 0.5,
                                            ),
                                            getDrawingVerticalLine: (value) =>
                                                FlLine(
                                              color:
                                                  Colors.grey.withOpacity(0.5),
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
                            // 右tab：数据分析
                            SingleChildScrollView(
                              controller: scrollController,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Builder(
                                        builder: (context) {
                                          // 获取区间内的起止索引
                                          final startIdx =
                                              filteredIndices.isNotEmpty
                                                  ? filteredIndices.first
                                                  : 0;
                                          final endIdx =
                                              filteredIndices.isNotEmpty
                                                  ? filteredIndices.last
                                                  : 0;

                                          // 区间均速
                                          final avgSpeed = startIdx < endIdx
                                              ? rideScore.speed
                                                      .sublist(
                                                          startIdx, endIdx + 1)
                                                      .reduce((a, b) => a + b) /
                                                  (endIdx - startIdx + 1)
                                              : 0.0;
                                          // 区间里程
                                          final distance = (rideScore
                                                      .distance[endIdx] -
                                                  rideScore.distance[startIdx])
                                              .abs();

                                          // 区间平均心率和功率
                                          final records = rideData.value
                                              .whereType<RecordMessage>()
                                              .toList();
                                          final startTime =
                                              records[startIdx].timestamp!;
                                          final endTime =
                                              records[endIdx].timestamp!;
                                          final rangeMsg = records.where((e) =>
                                              e.timestamp! > startTime &&
                                              e.timestamp! > endTime);
                                          final heartRateList =
                                              rangeMsg.map((e) => e.heartRate!);
                                          final powerList =
                                              rangeMsg.map((e) => e.power!);
                                          final avgHeartRate = heartRateList
                                                  .isNotEmpty
                                              ? heartRateList
                                                      .reduce((a, b) => a + b) /
                                                  heartRateList.length
                                              : 0.0;
                                          final avgPower = powerList.isNotEmpty
                                              ? powerList
                                                      .reduce((a, b) => a + b) /
                                                  powerList.length
                                              : 0.0;

                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Column(
                                                children: [
                                                  const Text('区间均速',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey)),
                                                  Text(
                                                      avgSpeed
                                                          .toStringAsFixed(1),
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  const Text('区间里程',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey)),
                                                  Text(
                                                      distance
                                                          .toStringAsFixed(2),
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  const Text('平均心率',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey)),
                                                  Text(
                                                      avgHeartRate > 0
                                                          ? avgHeartRate
                                                              .toStringAsFixed(
                                                                  0)
                                                          : '--',
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  const Text('平均功率',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey)),
                                                  Text(
                                                      avgPower > 0
                                                          ? avgPower
                                                              .toStringAsFixed(
                                                                  2)
                                                          : '--',
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // 切换按钮
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SegmentedButton<int>(
                                          segments: const [
                                            ButtonSegment(
                                              value: 0,
                                              label: Text('速度'),
                                            ),
                                            ButtonSegment(
                                              value: 1,
                                              label: Text('海拔'),
                                            ),
                                          ],
                                          selected: {chartType},
                                          onSelectionChanged: (selected) =>
                                              setState(() =>
                                                  chartType = selected.first),
                                        ),
                                        const SizedBox(width: 16),
                                        SegmentedButton<int>(
                                          segments: const [
                                            ButtonSegment(
                                              value: 0,
                                              label: Text('里程'),
                                            ),
                                            ButtonSegment(
                                              value: 1,
                                              label: Text('时间'),
                                            ),
                                          ],
                                          selected: {xType},
                                          onSelectionChanged: (selected) =>
                                              setState(
                                                  () => xType = selected.first),
                                        ),
                                      ],
                                    ),
                                    // 图表
                                    SizedBox(
                                      height: 200,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: LineChart(
                                          LineChartData(
                                            minX: chartRange.start,
                                            maxX: chartRange.end,
                                            minY: filteredChartSpots.isNotEmpty
                                                ? filteredChartSpots
                                                    .map((e) => e.y)
                                                    .reduce(
                                                        (a, b) => a < b ? a : b)
                                                : chartY.reduce(
                                                    (a, b) => a < b ? a : b),
                                            maxY: filteredChartSpots.isNotEmpty
                                                ? filteredChartSpots
                                                    .map((e) => e.y)
                                                    .reduce(
                                                        (a, b) => a > b ? a : b)
                                                : chartY.reduce(
                                                    (a, b) => a > b ? a : b),
                                            lineBarsData: [
                                              LineChartBarData(
                                                spots: filteredChartSpots
                                                        .isNotEmpty
                                                    ? filteredChartSpots
                                                    : chartSpots,
                                                isCurved: false,
                                                color: chartType == 0
                                                    ? Colors.deepOrange
                                                    : Colors.blueAccent,
                                                belowBarData: BarAreaData(
                                                  show: true,
                                                  color: (chartType == 0
                                                          ? Colors.deepOrange
                                                          : Colors.blueAccent)
                                                      .withOpacity(0.2),
                                                ),
                                                dotData: FlDotData(show: false),
                                              ),
                                            ],
                                            titlesData: FlTitlesData(
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: true,
                                                    reservedSize: 40),
                                              ),
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                    showTitles: true,
                                                    reservedSize: 24),
                                              ),
                                              topTitles: AxisTitles(),
                                              rightTitles: AxisTitles(),
                                            ),
                                            borderData:
                                                FlBorderData(show: false),
                                            gridData: FlGridData(show: true),
                                            lineTouchData: LineTouchData(
                                              touchCallback: (event, res) {
                                                if (res != null &&
                                                    res.lineBarSpots != null &&
                                                    res.lineBarSpots!
                                                        .isNotEmpty) {
                                                  _onChartTap(res
                                                      .lineBarSpots!.first.x);
                                                }
                                              },
                                              handleBuiltInTouches: true,
                                              touchTooltipData:
                                                  LineTouchTooltipData(
                                                // tooltipBgColor: Colors.black54,
                                                getTooltipItems: (spots) =>
                                                    spots
                                                        .map((s) =>
                                                            LineTooltipItem(
                                                              '$chartLabelX: ${s.x.toStringAsFixed(1)}\n$chartLabelY: ${s.y.toStringAsFixed(1)}',
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            ))
                                                        .toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: RangeSlider(
                                        min: chartX.first,
                                        max: chartX.last,
                                        divisions: 100,
                                        values: chartRange,
                                        labels: RangeLabels(
                                          chartRange.start.toStringAsFixed(1),
                                          chartRange.end.toStringAsFixed(1),
                                        ),
                                        onChanged: (range) {
                                          setState(() {
                                            chartRange = range;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int selectedIndex = 0;
  int chartType = 0; // 0: 速度, 1: 海拔
  int xType = 0; // 0: 里程, 1: 时间
  double chartMinX = 0;
  double chartMaxX = 0;

  void _onChartTap(double x) {
    // x为横轴值，找到最近的点
    int idx = 0;
    if (xType == 0) {
      idx = rideScore.distance.indexWhere((d) => d >= x);
    } else {
      idx = rideScore.distance.indexWhere((d) => d >= x);
      // idx = widget.rideScore.elapsedTime.indexWhere((t) => t >= x);
    }
    if (idx < 0) idx = 0;
    setState(() {
      selectedIndex = idx;
    });
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
                  urlTemplate:
                      'https://map.iris.al/styles/basic-preview/512/{z}/{x}/{y}.png',
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
                      child: NavPoint(color: Colors.green),
                    ),
                    Marker(
                      point: segment.route.last,
                      child: const NavPoint(color: Colors.red),
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
                        data: parseFitTimestampToDateTimeString(
                            DateTime(timestampWithOffset(segment.startTime))),
                        subtitle: '开始时间',
                      ),
                      Statistic(
                        data: segmentRecords.length.toString(),
                        subtitle: '挑战次数',
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
                // 逆序索引，最新到最旧排序
                final reverseIdx = segmentRecords.length - 1 - idx;
                final record = segmentRecords[reverseIdx];
                final isUser = record.item.startTime == segment.startTime;
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
                    parseFitTimestampToDateTimeString(
                        DateTime(timestampWithOffset(record.item.startTime))),
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
