import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('X-Nav'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(),
                      handleBuiltInTouches: true,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) =>
                              Text('${value.toInt()}'),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) =>
                              Text('${value.toInt()}'),
                        ),
                      ),
                      topTitles: AxisTitles(),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          const FlSpot(0, 1),
                          const FlSpot(1, 3),
                          const FlSpot(2, 2),
                          const FlSpot(3, 1.5),
                          const FlSpot(4, 2.5),
                          const FlSpot(5, 3),
                          const FlSpot(6, 4),
                        ],
                        isCurved: false,
                        color: Colors.deepOrange,
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              Colors.deepOrange.withAlpha((0.3 * 255).toInt()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 400,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    // 模拟数据：根据日期生成一个值
                    double value = (day.day % 10) / 10.0;
                    return Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(value),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
