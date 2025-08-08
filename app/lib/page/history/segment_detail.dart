import 'package:app/component/data.dart' show NavPoint, Statistic;
import 'package:app/database.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/path_utils.dart' show initCenter, initZoom;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:share_plus/share_plus.dart' show Share;

class SegmentDetailPage extends StatelessWidget {
  final Segment segment;
  final History history;
  final BestScore bestScore;

  const SegmentDetailPage({
    super.key,
    required this.segment,
    required this.history,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final segmentIndex = segment.id;
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