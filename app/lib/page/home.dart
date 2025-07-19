import 'package:app/component/data.dart';
import 'package:app/page/routes.dart';
import 'package:app/page/tachometer.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/fit.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app/page/history.dart'; // 导入 RideHistoryCard
import 'package:provider/provider.dart';

enum StatsRangeType { all, month, year, custom }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final dataLoader = Provider.of<DataLoader>(context, listen: true);

    late final Map<int, BestScore> bestScore;
    if (dataLoader.isInitialized && dataLoader.fitData.isEmpty) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('X-Nav'),
          ),
          body: const Center(
            child: Text('没有骑行记录，请先导入'),
          ));
    }
    if (dataLoader.bestScore.isNotEmpty) {
      bestScore = dataLoader.bestScore;
    } else {
      bestScore = {0: BestScore()};
    }
    // 取bestscore中key最大的值
    final bestScoreDisplay = bestScore.entries.last.value.getBestData();
    late final Map<DateTime, Map<String, dynamic>> rideData;
    // 骑行数据按日分组
    if (dataLoader.summaryLoaded) {
      rideData = dataLoader.summaryList
          .map((e) => {
                'timestamp': DateTime.fromMillisecondsSinceEpoch(
                        timestampWithOffset(e['start_time'].toInt()))
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
          'count': 0,
        };
        previousValue['total_distance'] += element['total_distance'];
        previousValue['total_ascent'] += element['total_ascent'];
        previousValue['total_moving_time'] += element['total_moving_time'];
        previousValue['count'] += 1;
        return previousValue;
      });
    } else {
      rideData = {};
    }
    final ValueNotifier<LineTouchResponse?> touchInteraction =
        ValueNotifier<LineTouchResponse?>(null);
    ValueNotifier<DateTime> currentMonth =
        ValueNotifier<DateTime>(DateTime.now());

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
              // 快捷磁贴按钮区
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    QuickTile(
                      icon: Icons.navigation,
                      label: '快速导航',
                      onTap: () {
                        Navigator.of(context).pushNamed('/quick_nav');
                      },
                    ),
                    QuickTile(
                      icon: Icons.timer,
                      label: '码表模式',
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const TachometerPage()));
                      },
                    ),
                    QuickTile(
                      icon: Icons.map,
                      label: '路书创建',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const RouteEditPage(route: 'new_route')),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
                      weeklySummaryInfo(touchInteraction, rideData),
                      const SizedBox(height: 16),
                      weeklySummaryChart(touchInteraction, rideData),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '月骑行记录',
                style: TextStyle(fontSize: 20),
              ),
              // 新增：当月骑行统计卡片，随日历月份同步
              monthlySummaryInfo(currentMonth, rideData),
              monthlySummaryCalendar(rideData, currentMonth),
              const Text(
                '最佳成绩',
                style: TextStyle(fontSize: 20),
              ),
              if (dataLoader.bestScoreLoaded)
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
                )
              else
                Center(
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('数据加载中'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox monthlySummaryCalendar(Map<DateTime, Map<String, dynamic>> rideData,
      ValueNotifier<DateTime> currentMonth) {
    return SizedBox(
      height: 400,
      child: rideData.isEmpty
          ? const Center(child: Text("data loading"))
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) => false,
              child: TableCalendar(
                firstDay: rideData.keys
                    .reduce((a, b) => a.isBefore(b) ? a : b)
                    .subtract(const Duration(days: 1)),
                lastDay: DateTime.now(),
                focusedDay: currentMonth.value,
                calendarFormat: CalendarFormat.month,
                daysOfWeekVisible: true,
                availableGestures: AvailableGestures.none,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  leftChevronVisible: true,
                  rightChevronVisible: true,
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
                        (20.0 + (distance / 5000).clamp(0.0, 30.0)).toDouble();
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
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 禁用滑动，仅允许按钮切换月份
                onPageChanged: (focusedDay) {
                  currentMonth.value =
                      DateTime(focusedDay.year, focusedDay.month, 1);
                },
              ),
            ),
    );
  }

  ValueListenableBuilder<DateTime> monthlySummaryInfo(
      ValueNotifier<DateTime> currentMonth,
      Map<DateTime, Map<String, dynamic>> rideData) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: currentMonth,
      builder: (context, focusedMonth, _) {
        // 计算当前日历显示月份的起止
        final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
        final monthEnd = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
        final monthRecords = rideData.entries.where((entry) =>
            entry.key
                .isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
            entry.key.isBefore(monthEnd.add(const Duration(days: 1))));
        final totalDistance = monthRecords.fold<double>(
            0.0, (sum, entry) => sum + (entry.value['total_distance'] ?? 0));
        final totalAscent = monthRecords.fold<double>(
            0.0, (sum, entry) => sum + (entry.value['total_ascent'] ?? 0));
        final totalTime = monthRecords.fold<double>(
            0.0, (sum, entry) => sum + (entry.value['total_moving_time'] ?? 0));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: RideSummary(
            rideData: {
              'totalDistance': totalDistance,
              'totalRides': monthRecords.fold<int>(
                  0, (sum, entry) => (sum + entry.value['count']).toInt()),
              'totalTime': totalTime,
              'totalAscent': totalAscent,
            },
          ),
        );
      },
    );
  }

  Expanded weeklySummaryChart(
      ValueNotifier<LineTouchResponse?> touchInteraction,
      Map<DateTime, Map<String, dynamic>> rideData) {
    return Expanded(
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(),
            handleBuiltInTouches: true,
            touchCallback:
                (FlTouchEvent event, LineTouchResponse? touchResponse) {
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
                getTitlesWidget: (value, meta) => Text('${value.toInt()} km'),
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
                      days: now.weekday - 1 + (11 - value.toInt()) * 7));
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
                final weekStart = now.subtract(
                    Duration(days: now.weekday - 1 + (11 - index) * 7));
                final weekEnd = weekStart.add(const Duration(days: 6));
                final weeklyDistance = rideData.entries
                    .where((entry) =>
                        entry.key.isAfter(
                            weekStart.subtract(const Duration(seconds: 1))) &&
                        entry.key
                            .isBefore(weekEnd.add(const Duration(seconds: 1))))
                    .fold(0.0,
                        (sum, entry) => sum + entry.value['total_distance']);
                return FlSpot(
                    index.toDouble(), (weeklyDistance / 1000).toDouble());
              }),
              isCurved: false,
              isStrokeCapRound: false,
              color: Colors.deepOrange,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.deepOrange.withAlpha((0.3 * 255).toInt()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ValueListenableBuilder<LineTouchResponse?> weeklySummaryInfo(
      ValueNotifier<LineTouchResponse?> touchInteraction,
      Map<DateTime, Map<String, dynamic>> rideData) {
    return ValueListenableBuilder<LineTouchResponse?>(
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Column(
                    children: [
                      Text('距离', style: TextStyle(fontSize: 12)),
                      Text('-- km', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('爬升海拔', style: TextStyle(fontSize: 12)),
                      Text('-- m', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('时间', style: TextStyle(fontSize: 12)),
                      Text('-- h', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ],
          );
        }

        final spot = touchInteraction.lineBarSpots?.firstWhereOrNull(
            (spot) => spot.x == touchInteraction.lineBarSpots![0].x);
        if (spot == null) {
          return const SizedBox.shrink();
        }
        final index = spot.x.toInt();
        final now = DateTime.now();
        final weekStart =
            now.subtract(Duration(days: now.weekday - 1 + (11 - index) * 7));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weeklyDistance = rideData.entries
            .where((entry) =>
                entry.key
                    .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                entry.key.isBefore(weekEnd.add(const Duration(seconds: 1))))
            .fold(0.0, (sum, entry) => sum + entry.value['total_distance']);
        final weeklyElevation = rideData.entries
            .where((entry) =>
                entry.key
                    .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                entry.key.isBefore(weekEnd.add(const Duration(seconds: 1))))
            .fold(0.0, (sum, entry) => sum + entry.value['total_ascent']);
        final weeklyTime = rideData.entries
            .where((entry) =>
                entry.key
                    .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                entry.key.isBefore(weekEnd.add(const Duration(seconds: 1))))
            .fold(0.0, (sum, entry) => sum + entry.value['total_moving_time']);
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('距离', style: TextStyle(fontSize: 12)),
                    Text(
                      '${(weeklyDistance / 1000).toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('爬升海拔', style: TextStyle(fontSize: 12)),
                    Text(
                      '$weeklyElevation m',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('时间', style: TextStyle(fontSize: 12)),
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
    );
  }

  void _showDailyRecords(BuildContext context, DateTime day) {
    // 筛选出当天的骑行记录
    final dailyRecords = DataLoader()
        .histories
        .where((record) {
          final recordDate = DateTime.fromMillisecondsSinceEpoch(
              (parseFitDataToSummary(record).startTime! * 1000 + 631065600000)
                  .toInt());
          return recordDate.year == day.year &&
              recordDate.month == day.month &&
              recordDate.day == day.day;
        })
        .map((record) => MapEntry(
              DateTime.fromMillisecondsSinceEpoch(
                  (parseFitDataToSummary(record).startTime! * 1000 +
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
                                  parseFitDataToSummary(b.value)
                                      .totalDistance!),
                          'totalRides': dailyRecords.length,
                          'totalTime': dailyRecords.fold(
                              0.0,
                              (a, b) =>
                                  a +
                                  parseFitDataToSummary(b.value)
                                      .totalElapsedTime!)
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
                                builder: (context) => RideDetailPage(
                                    rideData: MapEntry('path', record.value)),
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
