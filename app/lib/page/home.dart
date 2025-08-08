import 'package:app/component/data.dart';
import 'package:app/component/ride_stats_card.dart';
import 'package:app/database.dart';
import 'package:app/page/history.dart';
import 'package:app/page/routes/edit_route.dart';
import 'package:app/page/tachometer.dart';
import 'package:app/utils/data_loader.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

enum StatsRangeType { all, month, year, custom }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = Database();
  List<History> histories = [];
  List<Summary> summaries = [];
  List<KV> bestScores = [];
  Map<DateTime, List<Summary>> summariesByDay = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dataLoader = Provider.of<DataLoader>(context);

    if (!dataLoader.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('X-Nav'),
        ),
        body: const Center(
          child: Text('无骑行记录，请先导入'),
        ),
      );
    } else {
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
                        weeklySummaryInfo(touchInteraction),
                        const SizedBox(height: 16),
                        weeklySummaryChart(touchInteraction),
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
                monthlySummaryInfo(currentMonth),
                monthlySummaryCalendar(currentMonth),
                const Text(
                  '最佳成绩',
                  style: TextStyle(fontSize: 20),
                ),
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: bestScores.map((entry) {
                    final key = entry.key;
                    final value = entry.value;
                    return ListTile(
                      title: Text(key),
                      subtitle: Text(value),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        ),
      );
    }
  }

  Map<DateTime, List<Summary>> groupSummariesByDay(List<Summary> summaries) {
    return summaries.groupListsBy((e) => e.startTime!);
    // return summaries
    //     .map((e) => {
    //           'timestamp': DateTime.fromMillisecondsSinceEpoch(
    //                   timestampWithOffset(e.startTime!.microsecondsSinceEpoch))
    //               .toLocal(),
    //           'total_distance': e.totalDistance,
    //           'total_ascent': e.totalAscent,
    //           'total_moving_time': e.totalMovingTime,
    //         })
    //     .groupFoldBy<DateTime, Map<String, dynamic>>(
    //         (element) => DateTime(
    //             (element['timestamp']! as DateTime).year,
    //             (element['timestamp']! as DateTime).month,
    //             (element['timestamp']! as DateTime).day), (previousValue, element) {
    //   previousValue ??= {
    //     'total_distance': 0,
    //     'total_ascent': 0,
    //     'total_moving_time': 0,
    //     'count': 0,
    //   };
    //   previousValue['total_distance'] += element['total_distance'];
    //   previousValue['total_ascent'] += element['total_ascent'];
    //   previousValue['total_moving_time'] += element['total_moving_time'];
    //   previousValue['count'] += 1;
    //   return previousValue;
    // });
  }

  SizedBox monthlySummaryCalendar(ValueNotifier<DateTime> currentMonth) {
    return SizedBox(
      height: 400,
      child: histories.isEmpty
          ? const Center(child: Text("data loading"))
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) => false,
              child: TableCalendar(
                firstDay: summaries
                    .map((e) => e.startTime!)
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
                    final distance = summaries
                        .where((entry) =>
                            entry.startTime!.year == day.year &&
                            entry.startTime!.month == day.month &&
                            entry.startTime!.day == day.day)
                        .fold(0.0, (e0, e) => e0 + (e.totalDistance ?? 0.0));
                    final size =
                        (20.0 + (distance / 5000).clamp(0.0, 30.0)).toDouble();
                    if (distance == 0) {
                      return Center(
                        child: GestureDetector(
                          onTap: () => showDailyRecords(context, day),
                          child: Text('${day.day}'),
                        ),
                      );
                    }
                    return Center(
                      child: GestureDetector(
                        onTap: () => showDailyRecords(context, day),
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
      ValueNotifier<DateTime> currentMonth) {
    return ValueListenableBuilder<DateTime>(
      valueListenable: currentMonth,
      builder: (context, focusedMonth, _) {
        // 计算当前日历显示月份的起止
        final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
        final monthEnd = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
        final monthRecords = summariesByDay.entries.where((entry) =>
            entry.key
                .isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
            entry.key.isBefore(monthEnd.add(const Duration(days: 1))));
        final totalDistance = monthRecords.fold<double>(
            0.0,
            (sum, entry) =>
                sum + entry.value.fold(0.0, (e0, e) => e0 + e.totalDistance!));
        // final totalAscent = monthRecords.fold<double>(
        //     0.0,
        //     (sum, entry) =>
        //         sum + entry.value.fold(0.0, (e0, e) => e0 + e.totalAscent!));
        final totalTime = monthRecords.fold<double>(
            0.0,
            (sum, entry) =>
                sum +
                entry.value.fold(0.0, (e0, e) => e0 + e.totalElapsedTime!));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: RideSummary(
            totalDistance: totalDistance,
            totalRides: monthRecords.fold<int>(
                0, (sum, entry) => (sum + entry.value.length).toInt()),
            totalTime: totalTime,
          ),
        );
      },
    );
  }

  Expanded weeklySummaryChart(
      ValueNotifier<LineTouchResponse?> touchInteraction) {
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
                final weeklyDistance = summariesByDay.entries
                    .where((entry) =>
                        entry.key.isAfter(
                            weekStart.subtract(const Duration(seconds: 1))) &&
                        entry.key
                            .isBefore(weekEnd.add(const Duration(seconds: 1))))
                    .fold(
                        0.0,
                        (sum, entry) =>
                            sum +
                            entry.value
                                .fold(0.0, (e0, e) => e0 + e.totalDistance!));
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
      ValueNotifier<LineTouchResponse?> touchInteraction) {
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
        final weeklyDistance = summariesByDay.entries
            .where((entry) =>
                entry.key
                    .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                entry.key.isBefore(weekEnd.add(const Duration(seconds: 1))))
            .fold(
                0.0,
                (sum, entry) =>
                    sum +
                    entry.value.fold(0, (e0, e) => e0 + e.totalDistance!));
        final weeklyElevation = summariesByDay.entries
            .where((entry) =>
                entry.key
                    .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                entry.key.isBefore(weekEnd.add(const Duration(seconds: 1))))
            .fold(
                0.0,
                (sum, entry) =>
                    sum + entry.value.fold(0, (e0, e) => e0 + e.totalAscent!));
        final weeklyTime = summariesByDay.entries
            .where((entry) =>
                entry.key
                    .isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                entry.key.isBefore(weekEnd.add(const Duration(seconds: 1))))
            .fold(
                0.0,
                (sum, entry) =>
                    sum +
                    entry.value.fold(0, (e0, e) => e0 + e.totalElapsedTime!));

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

  void showDailyRecords(BuildContext context, DateTime day) {
    // 筛选出当天的骑行记录
    final summaryToday = summaries
        .where((e) =>
            e.startTime!.year == day.year &&
            e.startTime!.month == day.month &&
            e.startTime!.day == day.day)
        .sorted((a, b) => a.startTime!.compareTo(b.startTime!));
    final ids = summaryToday.map((e) => e.historyId).toList();
    final dailyRecords = ids
        .map((id) => histories.firstWhereOrNull((e) => e.id == id))
        .whereType<History>()
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
                        child: RideSummary(
                          totalDistance: summaryToday.fold(
                              0.0, (a, b) => a + b.totalDistance!),
                          totalRides: summaryToday.length,
                          totalTime: summaryToday.fold(
                              0.0, (a, b) => a + b.totalElapsedTime!),
                        ),
                      ),
                    ),
                    SliverList(
                        delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return RideHistoryState.buildRideHistoryCard(
                            dailyRecords[index], summaryToday[index], context);
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

String parseTime(int seconds) {
  final hours = (seconds / 3600).floor();
  final minutes = ((seconds % 3600) / 60).floor();
  return '${hours.toString().padLeft(2, '0')}h:${minutes.toString().padLeft(2, '0')}m';
}
