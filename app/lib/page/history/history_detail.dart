class RideDetailPage extends StatefulWidget {
  final History history;
  const RideDetailPage({super.key, required this.history});

  @override
  State<RideDetailPage> createState() => RideDetailPageState();
}

class RideDetailPageState extends State<RideDetailPage> {
  late final History history;
  late final RideScore rideScore;
  late final DataLoader dataLoader;
  late int highlightRouteIndex;
  late RangeValues chartRange;

  @override
  void initState() {
    super.initState();
    history = widget.history;
    highlightRouteIndex = -1;
    rideScore = RideScore(history: history.value, routes: dataLoader.routes);
    chartMaxX = rideScore.distance.isNotEmpty ? rideScore.distance.last : 0;
    chartRange = RangeValues(
      rideScore.distance.isNotEmpty ? rideScore.distance.first : 0,
      rideScore.distance.isNotEmpty ? rideScore.distance.last : 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionMsg = history.value.whereType<SessionMessage>().first;
    final timestamp = timestampWithOffset(sessionMsg.timestamp!);
    late final BestScore bestScore, bestScoreTillNow;
    late final List<Segment> analysisOfSubRoutes;
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
