import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/fit_parser.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app/page/history.dart'; // 导入 RideHistoryCard
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final dataLoader = Provider.of<DataLoader>(context, listen: true);

    if (dataLoader.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(dataLoader.progressMessage ?? '数据加载中...'),
          ],
        ),
      );
    }
    if (!dataLoader.isLoading && !dataLoader.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(dataLoader.progressMessage ?? '未知错误...'),
          ],
        ),
      );
    }

    final bestScore = dataLoader.bestScore;
    // 取bestscore中key最大的值
    final bestScoreDisplay =
        (bestScore.entries.last.value ?? BestScore()).getBestData();

    final rideData = dataLoader.summaryList
        .map((e) => {
              'timestamp': DateTime.fromMillisecondsSinceEpoch(
                      timestampFromFitTimestamp(e['start_time'].toInt()))
                  .toLocal(),
              'total_distance': e['total_distance'],
              'total_ascent': e['total_ascent'],
              'total_moving_time': e['total_moving_time'],
            })
        .groupFoldBy<DateTime, Map<String, dynamic>>(
            (element) => DateTime(
                element['timestamp'].year,
                element['timestamp'].month,
                element['timestamp'].day), (previousValue, element) {
      previousValue ??= {
        'total_distance': 0,
        'total_ascent': 0,
        'total_moving_time': 0,
      };
      previousValue['total_distance'] += element['total_distance'];
      previousValue['total_ascent'] += element['total_ascent'];
      previousValue['total_moving_time'] += element['total_moving_time'];
      return previousValue;
    });
    final ValueNotifier<LineTouchResponse?> touchInteraction =
        ValueNotifier<LineTouchResponse?>(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('X-Nav'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '周骑行统计',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ValueListenableBuilder<LineTouchResponse?>(
                        valueListenable: touchInteraction,
                        builder: (context, touchInteraction, child) {
                          if (touchInteraction == null) {
                            return Column(
                              children: [
                                const Text(
                                  '时间范围: --月--日 - --月--日',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: const [
                                    Column(
                                      children: [
                                        Text('距离',
                                            style: TextStyle(fontSize: 12)),
                                        Text('-- km',
                                            style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text('爬升海拔',
                                            style: TextStyle(fontSize: 12)),
                                        Text('-- m',
                                            style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text('时间',
                                            style: TextStyle(fontSize: 12)),
                                        Text('-- h',
                                            style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }

                          final spot = touchInteraction.lineBarSpots
                              ?.firstWhereOrNull((spot) =>
                                  spot.x ==
                                  touchInteraction.lineBarSpots![0].x);
                          if (spot == null) {
                            return const SizedBox.shrink();
                          }
                          final index = spot.x.toInt();
                          final now = DateTime.now();
                          final weekStart = now.subtract(Duration(
                              days: now.weekday - 1 + (11 - index) * 7));
                          final weekEnd =
                              weekStart.add(const Duration(days: 6));
                          final weeklyDistance = rideData.entries
                              .where((entry) =>
                                  entry.key.isAfter(weekStart
                                      .subtract(const Duration(seconds: 1))) &&
                                  entry.key.isBefore(
                                      weekEnd.add(const Duration(seconds: 1))))
                              .fold(
                                  0.0,
                                  (sum, entry) =>
                                      sum + entry.value['total_distance']);
                          final weeklyElevation = rideData.entries
                              .where((entry) =>
                                  entry.key.isAfter(weekStart
                                      .subtract(const Duration(seconds: 1))) &&
                                  entry.key.isBefore(
                                      weekEnd.add(const Duration(seconds: 1))))
                              .fold(
                                  0.0,
                                  (sum, entry) =>
                                      sum + entry.value['total_ascent']);
                          final weeklyTime = rideData.entries
                              .where((entry) =>
                                  entry.key.isAfter(weekStart
                                      .subtract(const Duration(seconds: 1))) &&
                                  entry.key.isBefore(
                                      weekEnd.add(const Duration(seconds: 1))))
                              .fold(
                                  0.0,
                                  (sum, entry) =>
                                      sum + entry.value['total_moving_time']);
                          String parseTime(int seconds) {
                            final hours = (seconds / 3600).floor();
                            final minutes = ((seconds % 3600) / 60).floor();
                            return '${hours.toString().padLeft(2, '0')}h:${minutes.toString().padLeft(2, '0')}m';
                          }

                          return Column(
                            children: [
                              Text(
                                '时间范围: ${weekStart.month}月${weekStart.day}日 - ${weekEnd.month}月${weekEnd.day}日',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      const Text('距离',
                                          style: TextStyle(fontSize: 12)),
                                      Text(
                                        '${(weeklyDistance / 1000).toStringAsFixed(1)} km',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('爬升海拔',
                                          style: TextStyle(fontSize: 12)),
                                      Text(
                                        '$weeklyElevation m',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('时间',
                                          style: TextStyle(fontSize: 12)),
                                      Text(
                                        parseTime(weeklyTime.toInt()),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(),
                              handleBuiltInTouches: true,
                              touchCallback: (FlTouchEvent event,
                                  LineTouchResponse? touchResponse) {
                                if (touchResponse?.lineBarSpots == null ||
                                    touchResponse?.lineBarSpots == []) {
                                  return;
                                }
                                touchInteraction.value = touchResponse;
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) =>
                                      Text('${value.toInt()} km'),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0) {
                                      return const SizedBox.shrink();
                                    }
                                    final now = DateTime.now();
                                    final weekStart = now.subtract(Duration(
                                        days: now.weekday -
                                            1 +
                                            (11 - value.toInt()) * 7));
                                    return Text(
                                      '${weekStart.month}/${weekStart.day}',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(12, (index) {
                                  final now = DateTime.now();
                                  final weekStart = now.subtract(Duration(
                                      days:
                                          now.weekday - 1 + (11 - index) * 7));
                                  final weekEnd =
                                      weekStart.add(const Duration(days: 6));
                                  final weeklyDistance = rideData.entries
                                      .where((entry) =>
                                          entry.key.isAfter(weekStart.subtract(
                                              const Duration(seconds: 1))) &&
                                          entry.key.isBefore(weekEnd
                                              .add(const Duration(seconds: 1))))
                                      .fold(
                                          0.0,
                                          (sum, entry) =>
                                              sum +
                                              entry.value['total_distance']);
                                  return FlSpot(index.toDouble(),
                                      (weeklyDistance / 1000).toDouble());
                                }),
                                isCurved: false,
                                isStrokeCapRound: false,
                                color: Colors.deepOrange,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.deepOrange
                                      .withAlpha((0.3 * 255).toInt()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '月骑行记录',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(
                height: 400,
                child: rideData.isEmpty
                    ? const Center(child: Text("data loading"))
                    : TableCalendar(
                        firstDay: rideData.keys
                            .reduce((a, b) => a.isBefore(b) ? a : b)
                            .subtract(const Duration(days: 1)),
                        lastDay: DateTime.now(),
                        focusedDay: DateTime.now(),
                        calendarFormat: CalendarFormat.month,
                        daysOfWeekVisible: true,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          leftChevronVisible: false,
                          rightChevronVisible: false,
                          titleTextStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.deepOrange,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.deepOrange,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        weekendDays: const [DateTime.saturday, DateTime.sunday],
                        calendarBuilders: CalendarBuilders(
                          prioritizedBuilder: (context, day, focusedDay) {
                            final distance = rideData.entries
                                .firstWhere(
                                  (entry) =>
                                      entry.key.year == day.year &&
                                      entry.key.month == day.month &&
                                      entry.key.day == day.day,
                                  orElse: () => MapEntry(
                                    DateTime(0),
                                    {
                                      'total_distance': 0,
                                      'total_ascent': 0,
                                      'total_moving_time': 0,
                                    },
                                  ),
                                )
                                .value['total_distance'];
                            final size =
                                (20.0 + (distance / 5000).clamp(0.0, 30.0))
                                    .toDouble();
                            if (distance == 0) {
                              return Center(
                                child: GestureDetector(
                                  onTap: () => _showDailyRecords(context, day),
                                  child: Text('${day.day}'),
                                ),
                              );
                            }
                            return Center(
                              child: GestureDetector(
                                onTap: () => _showDailyRecords(context, day),
                                child: Container(
                                  width: size,
                                  height: size,
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const Text(
                '最佳成绩',
                style: TextStyle(fontSize: 20),
              ),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: bestScoreDisplay.entries.map((entry) {
                  final key = entry.key;
                  final value = entry.value;
                  return ListTile(
                    title: Text(key),
                    subtitle: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDailyRecords(BuildContext context, DateTime day) {
    // 筛选出当天的骑行记录
    final dailyRecords = DataLoader()
        .fitData
        .where((record) {
          final recordDate = DateTime.fromMillisecondsSinceEpoch(
              (parseFitDataToSummary(record)['start_time'] * 1000 +
                      631065600000)
                  .toInt());
          return recordDate.year == day.year &&
              recordDate.month == day.month &&
              recordDate.day == day.day;
        })
        .map((record) => MapEntry(
              DateTime.fromMillisecondsSinceEpoch(
                  (parseFitDataToSummary(record)['start_time'] * 1000 +
                          631065600000)
                      .toInt()),
              record,
            ))
        .sorted(
          (a, b) => a.key.compareTo(b.key),
        )
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.4,
          child: dailyRecords.isEmpty
              ? const Center(child: Text('当天没有骑行记录'))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: RideSummary(rideData: {
                          'totalDistance': dailyRecords.fold(
                              0.0,
                              (a, b) =>
                                  a +
                                  parseFitDataToSummary(
                                      b.value)['total_distance']),
                          'totalRides': dailyRecords.length,
                          'totalTime': dailyRecords.fold(
                              0.0,
                              (a, b) =>
                                  a +
                                  parseFitDataToSummary(
                                      b.value)['total_elapsed_time'])
                        }),
                      ),
                    ),
                    SliverList(
                        delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = dailyRecords[index];
                        return RideHistoryCard(
                          rideData: record.value,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    RideDetailPage(rideData: record.value),
                              ),
                            );
                          },
                        );
                      },
                      childCount: dailyRecords.length,
                    ))
                  ],
                ),
        );
      },
    );
  }
}
