import 'dart:io';

import 'package:app/component/data.dart';
import 'package:app/database.dart';
import 'package:app/page/history/segment_detail.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/path_utils.dart';
import 'package:app/utils/provider.dart'
    show buildStreamProvider, tileProvider, historyProvider;
import 'package:drift/drift.dart' show Variable;
import 'package:fit_tool/fit_tool.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:share_plus/share_plus.dart';

class RideDetailPage extends ConsumerStatefulWidget {
  final History history;
  const RideDetailPage({super.key, required this.history});

  @override
  ConsumerState<RideDetailPage> createState() => RideDetailPageState();
}

class RideDetailPageState extends ConsumerState<RideDetailPage> {
  late final History history;
  late int highlightRouteIndex;
  late RangeValues chartRange;

  @override
  void initState() {
    super.initState();
    history = widget.history;
    highlightRouteIndex = -1;
    chartMaxX = 0;
    chartRange = RangeValues(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(buildStreamProvider((db) =>
        (db.select(db.summarys)..where((s) => s.historyId.equals(history.id)))
            .watch()));
    final bestScore = ref.watch(buildStreamProvider((db) =>
        (db.select(db.bestScores)..where((s) => s.historyId.equals(history.id)))
            .watch()));
    final segments = ref.watch(buildStreamProvider((db) =>
        (db.select(db.segments)
              ..where((tbl) => tbl.historyId.equals(history.id)))
            .watch()));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('骑行详情'),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () async {
                final file = File(history.filePath);
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
                await File(history.filePath).delete();
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
                initialCenter: initCenter(history.route),
                initialZoom: initZoom(history.route),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://map.iris.al/styles/basic-preview/512/{z}/{x}/{y}.png',
                  tileProvider: tileProvider,
                ),
                Consumer(builder: (builder, ref, child) {
                  List<Polyline> lines = [];
                  final segments = ref.watch(buildStreamProvider((db) =>
                      (db.select(db.segments)
                            ..where((tbl) => tbl.historyId.equals(history.id)))
                          .watch()));
                  lines.add(
                    Polyline(
                      // TODO
                      points: history.route,
                      strokeWidth: 3.0,
                      color: Colors.deepOrange,
                    ),
                  );
                  lines.addAll(segments.when(
                      data: (data) => data.map((e) => Polyline(
                            points: history.route
                                .sublist(e.startIndex, e.endIndex + 1),
                            strokeWidth: 4.0,
                            color: (highlightRouteIndex == e.id)
                                ? Colors.amberAccent
                                : Colors.transparent,
                          )),
                      error: (s, e) => [],
                      loading: () => []));
                  return PolylineLayer(polylines: lines);
                }),
                Consumer(builder: (_, ref, child) {
                  final markers = segments.when(
                      data: (data) => data
                          .map((e) => Marker(
                                point: LatLng(
                                  history.route[e.startIndex].latitude,
                                  history.route[e.startIndex].longitude,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      highlightRouteIndex = e.id;
                                    });
                                  },
                                  child: Icon(
                                    Icons.emoji_events,
                                    color: (highlightRouteIndex == e.id)
                                        ? Colors.transparent
                                        : Colors.amber,
                                    size: 30,
                                  ),
                                ),
                              ))
                          .toList(),
                      error: (s, e) => [],
                      loading: () => []);
                  return MarkerLayer(markers: [
                    ...markers,
                    // TODO
                    // Marker(
                    //   point: history.route[idx],
                    //   child: NavPoint(),
                    // ),
                  ]);
                }),
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
                                      parseFitTimestampToDateTimeString(summary
                                          .maybeWhen(
                                              orElse: () => [
                                                    Summary(id: 0, historyId: 0)
                                                  ])
                                          .first
                                          .startTime!),
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Consumer(builder: (_, __, ___) {
                                      return summary.when(
                                        data: (summary) => GridView.count(
                                          crossAxisCount: 3, // 每行显示3个元素
                                          shrinkWrap: true, // 适配内容高度
                                          physics:
                                              const NeverScrollableScrollPhysics(), // 禁止滚动
                                          childAspectRatio: 1.8,
                                          children: [
                                            Statistic(
                                              data: (summary.first
                                                          .totalDistance! /
                                                      1000.0)
                                                  .toStringAsFixed(2),
                                              label: 'km',
                                              subtitle: '总里程',
                                            ),
                                            Statistic(
                                              data: (summary.first
                                                          .totalElapsedTime! /
                                                      60)
                                                  .toStringAsFixed(2),
                                              label: '分钟',
                                              subtitle: '总耗时',
                                            ),
                                            Statistic(
                                              data: (summary.first.avgSpeed! *
                                                      3.6)
                                                  .toStringAsFixed(2),
                                              label: 'km/h',
                                              subtitle: '均速',
                                            ),
                                            Statistic(
                                              data: (summary.first.maxSpeed! *
                                                      3.6)
                                                  .toStringAsFixed(2),
                                              label: 'km/h',
                                              subtitle: '最大速度',
                                            ),
                                            Statistic(
                                              data:
                                                  '${summary.first.totalAscent}',
                                              label: 'm',
                                              subtitle: '总爬升',
                                            ),
                                            Statistic(
                                              data:
                                                  '${summary.first.totalDescent}',
                                              label: 'm',
                                              subtitle: '总下降',
                                            ),
                                            Statistic(
                                              data:
                                                  '${summary.first.avgHeartRate ?? '未知'}',
                                              label: 'bpm',
                                              subtitle: '平均心率',
                                            ),
                                            Statistic(
                                              data:
                                                  '${summary.first.maxHeartRate ?? '未知'}',
                                              label: 'bpm',
                                              subtitle: '最大心率',
                                            ),
                                            Statistic(
                                              data:
                                                  '${summary.first.avgPower ?? '未知'}',
                                              label: 'W',
                                              subtitle: '平均功率',
                                            ),
                                            Statistic(
                                              data:
                                                  '${summary.first.maxPower ?? '未知'}',
                                              label: 'W',
                                              subtitle: '最大功率',
                                            ),
                                            Statistic(
                                              data:
                                                  '${summary.first.totalCalories ?? '未知'}',
                                              label: 'kcal',
                                              subtitle: '总卡路里',
                                            ),
                                          ],
                                        ),
                                        loading: () => const Center(
                                            child: CircularProgressIndicator()),
                                        error: (err, stack) =>
                                            Center(child: Text('加载失败: $err')),
                                      );
                                    }),
                                    const SizedBox(height: 20),
                                    const Text(
                                      '成绩',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    bestScore.when(
                                        data: (bestScore) {
                                          return buildScoreCount(0, 0, 0);
                                        },
                                        loading: () =>
                                            const CircularProgressIndicator(),
                                        error: (err, stack) =>
                                            Center(child: Text('加载失败: $err'))),
                                    const Text('路段'),
                                    segments.when(
                                        data: (segments) {
                                          if (segments.isEmpty) {
                                            return Center(
                                              child: const Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text('No sub routes'),
                                              ),
                                            );
                                          } else {
                                            return buildSegmentList(
                                                segments, context);
                                          }
                                        },
                                        error: (s, e) => Text('加载失败: $e'),
                                        loading: () =>
                                            const CircularProgressIndicator()),
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
                                                  rideScore.distance[
                                                      index * reductionFactor],
                                                  rideScore.speed[
                                                      index * reductionFactor],
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
                                              getTitlesWidget: (value, meta) =>
                                                  Text('${value.toInt()} km/h'),
                                              interval: 10,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 20,
                                              interval: rideScore
                                                      .summary.totalDistance! /
                                                  5 /
                                                  1000,
                                              getTitlesWidget: (value, meta) =>
                                                  Text(
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
                                            color: Colors.grey.withOpacity(0.5),
                                            strokeWidth: 0.5,
                                          ),
                                          getDrawingVerticalLine: (value) =>
                                              FlLine(
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
                                                  rideScore.distance[
                                                      index * reductionFactor],
                                                  rideScore.altitude[
                                                      index * reductionFactor],
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
                                              getTitlesWidget: (value, meta) =>
                                                  Text('${value.toInt()} m'),
                                              interval: 50,
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 20,
                                              interval: rideScore
                                                      .summary.totalDistance! /
                                                  5 /
                                                  1000,
                                              getTitlesWidget: (value, meta) =>
                                                  Text(
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
                                            color: Colors.grey.withOpacity(0.5),
                                            strokeWidth: 0.5,
                                          ),
                                          getDrawingVerticalLine: (value) =>
                                              FlLine(
                                            color: Colors.grey.withOpacity(0.5),
                                            strokeWidth: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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

Widget buildScoreCount(int scoreCnt, int subRouteCount, int achieveCnt) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Statistic(
          subtitle: "最佳成绩",
          data: scoreCnt.toString(),
        ),
        Statistic(
          subtitle: "路段",
          data: subRouteCount.toString(),
        ),
        Statistic(subtitle: "成就", data: achieveCnt.toString()),
      ],
    );

Widget buildSegmentList(List<Segment> segments, BuildContext context) =>
    Consumer(builder: (b, r, c) {
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: segments.map((segment) {
          final summary = r.watch(buildStreamProvider((db) =>
              (db.select(db.summarys)
                    ..where((t) => t.id.equals(segment.summaryId)))
                  .watch()));
          return ListTile(
              title: Row(
                children: [
                  Text(
                    '路段 ${segment.id + 1}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (true)
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 18,
                    ),
                ],
              ),
              subtitle: summary.when(
                data: (summary) => Text(
                  '里程 ${summary.first.totalDistance?.toStringAsFixed(2)} km'
                  ' 耗时 ${secondToFormatTime(summary.first.totalElapsedTime ?? 0)}'
                  ' 均速 ${summary.first.avgSpeed?.toStringAsFixed(2)} km/h',
                  style: const TextStyle(fontSize: 14),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text(e.toString()),
              ),
              onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SegmentDetailPage(
                        segment: segment,
                        rideScore: history,
                      ),
                    ),
                  ));
        }).toList(),
      );
    });

// get entries that refresh the before's records
Future<Map<String, int>> getBestScoreRankings(int historyId) async {
  final db=Database();
  final current = await (db.select(db.bestScores)
    ..where((tbl) => tbl.historyId.equals(historyId)))
    .getSingle();

  // 需要排名的字段及类型
  final fields = <String, dynamic>{
    'maxSpeed': current.maxSpeed,
    'maxPower': current.maxPower,
    'maxClimb': current.maxClimb,
    'maxDistance': current.maxDistance,
    'maxTime': current.maxTime,
    // ...其他字段
  };

  // 字段类型映射（用于 SQL 变量类型）
  final fieldTypes = <String, String>{
    'maxSpeed': 'REAL',
    'avgSpeed': 'REAL',
    'maxPower': 'INTEGER',
    'avgPower': 'INTEGER',
    'maxHeartRate': 'INTEGER',
    // ...其他字段类型
  };

  // 比较符映射（如大于、等于等，通常用 '>'）
  final comparators = <String, String>{
    'maxSpeed': '>',
    'maxPower': '>',
    'maxHeartRate': '>',
    'avgSpeed': '>',
    'avgPower': '>',
    // ...其他字段
  };

  Map<String, int> result = {};

  for (final entry in fields.entries) {
    final field = entry.key;
    final value = entry.value;
    final comparator = comparators[field] ?? '>';
    final type = fieldTypes[field] ?? 'INTEGER';

    // 构造 SQL
    final sql =
        'SELECT COUNT(*) + 1 AS rank FROM best_scores WHERE $field $comparator ? AND timestamp <= ?';

    final variables = type == 'REAL'
        ? [Variable.withReal(value), Variable.withInt(current.timestamp)]
        : [Variable.withInt(value), Variable.withInt(current.timestamp)];

    final query = db.customSelect(
      sql,
      variables: variables,
      readsFrom: {db.bestScores},
    );

    final row = await query.getSingle();
    result[field] = row.read<int>('rank');
  }

  return result;
}