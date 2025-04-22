import 'dart:async';
import 'dart:io';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/gpx_parser.dart';
import 'package:app/utils/path_utils.dart';
import 'package:app/utils/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

class DataLoader extends ChangeNotifier {
  static final DataLoader _instance = DataLoader._internal();

  factory DataLoader() => _instance;

  DataLoader._internal();

  final List<List<LatLng>> _routes = [];
  final List<Map<String, dynamic>> _fitData = [];
  final List<File> _gpxFile = [];
  final List<List<LatLng>> _histories = []; // 历史路径
  final Map<String, dynamic> _rideData = {}; // 骑行历史统计信息
  final List<Map<String, dynamic>> _summary = []; // 每个骑行记录对应的摘要
  final Map<int, BestScore> _bestScore = {}; // 截至任意时间戳的骑行记录的最佳成绩
  final Map<int, SortManager<SegmentScore, int>> _bestSegment =
      {}; // 任意赛段，截至任意时间戳的最佳记录
  final FMTCTileProvider tileProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
  );
  bool isInitialized = false;

  List<List<LatLng>> get routes => _routes;
  List<List<LatLng>> get histories => _histories;
  Map<String, dynamic> get rideData => _rideData;
  List<Map<String, dynamic>> get summaryList => _summary;
  List<Map<String, dynamic>> get fitData => _fitData;
  List<File> get gpxData => _gpxFile;
  Map<int, BestScore> get bestScore => _bestScore;
  Map<int, SortManager<SegmentScore, int>> get bestSegment => _bestSegment;

  bool isLoading = false; // 是否正在加载数据

  Future<void> initialize() async {
    if (isLoading) return;
    isLoading = true;
    isInitialized = false;

    await Future.wait([
      loadRouteData(), // 加载路线库
      loadHistoryData(), // 加载骑行历史数据库
    ]);

    await Future.wait([
      loadRideData(), // 分析历史总骑行摘要
      loadSummaryData(), // 分析每次骑行的摘要数据
    ]);

    await Future.wait([
      loadBestScore(), // 加载截至每个时间戳的最佳骑行记录数据
    ]);

    isInitialized = true;
    isLoading = false;
    notifyListeners(); // 通知监听者数据已加载完成
  }

  Future<void> loadRouteData() async {
    _gpxFile.clear();
    _routes.clear();

    final files = await Storage().getGpxFiles();
    print('GPX files: ${files.length}');
    final parsedRoutes = await compute(_parseGpxFiles, files);
    print('Parsed GPX files: ${parsedRoutes['files'].length}');
    _gpxFile.addAll(parsedRoutes['files']);
    _routes.addAll(parsedRoutes['routes']);

    notifyListeners();
  }

  Future<void> loadHistoryData() async {
    _fitData.clear();
    _histories.clear();

    final files = await Storage().getFitFiles();
    print('FIT files: ${files.length}');
    final parsedHistories = await compute(_parseFitFiles, files);
    print('Parsed FIT files: ${parsedHistories['fitData'].length}');
    _fitData.addAll(parsedHistories['fitData']);
    _histories.addAll(parsedHistories['histories']);

    notifyListeners();
  }

  Future<void> loadRideData() async {
    print('Loading ride data...');
    final stopwatch = Stopwatch()..start(); // 开始计时
    final rideData = await compute(_analyzeRideData, _fitData);
    stopwatch.stop(); // 停止计时
    print(
        'Ride data loaded: ${rideData['totalRides']} rides in ${stopwatch.elapsedMilliseconds} ms');
    _rideData.clear();
    _rideData.addAll(rideData);

    notifyListeners();
  }

  Future<void> loadSummaryData() async {
    print('Loading summary data...');
    final stopwatch = Stopwatch()..start(); // 开始计时
    final summaries = await compute(_analyzeSummaryData, _fitData);
    stopwatch.stop(); // 停止计时
    print(
        'Summary data loaded: ${summaries.length} summaries in ${stopwatch.elapsedMilliseconds} ms');
    _summary.clear();
    _summary.addAll(summaries);

    notifyListeners();
  }

  Future<void> loadBestScore() async {
    print('Loading best score data...');
    final stopwatch = Stopwatch()..start(); // 开始计时
    final bestScoreData = await compute(_analyzeBestScore, {
      'fitData': _fitData,
      'routes': _routes,
      'rideData': _rideData,
    });
    stopwatch.stop(); // 停止计时
    print(
        'Best score data loaded: ${bestScoreData['bestScore'].length} scores in ${stopwatch.elapsedMilliseconds} ms');
    _bestScore.clear();
    _bestScore.addAll(bestScoreData['bestScore']);
    _bestSegment.clear();
    _bestSegment.addAll(bestScoreData['bestSegment']);

    notifyListeners();
  }
}

Map<String, dynamic> _parseGpxFiles(List<File> files) {
  final gpxFiles = <File>[];
  final routes = <List<LatLng>>[];

  for (var file in files) {
    try {
      final gpxData = file.readAsStringSync();
      gpxFiles.add(file);
      routes.add(parseGpxToPath(gpxData));
    } catch (e) {
      debugPrint('Error reading GPX file: $e');
    }
  }

  return {'files': gpxFiles, 'routes': routes};
}

Map<String, dynamic> _parseFitFiles(List<File> files) {
  final fitDataList = <Map<String, dynamic>>[];
  final histories = <List<LatLng>>[];

  for (var file in files) {
    final fitData = parseFitFile(file.readAsBytesSync());
    fitDataList.add({...fitData, 'path': file.path});
    histories.add(parseFitDataToRoute(fitData));
  }

  return {'fitData': fitDataList, 'histories': histories};
}

Map<String, dynamic> _analyzeRideData(List<Map<String, dynamic>> fitData) {
  final summaries = fitData.map(parseFitDataToSummary).toList();
  return summaries.fold<Map<String, dynamic>>(
    {'totalDistance': 0.0, 'totalRides': 0, 'totalTime': 0},
    (value, element) {
      return {
        'totalDistance':
            value['totalDistance'] + (element['total_distance'] ?? 0.0),
        'totalRides': value['totalRides'] + 1,
        'totalTime': value['totalTime'] + (element['total_elapsed_time'] ?? 0),
      };
    },
  );
}

List<Map<String, dynamic>> _analyzeSummaryData(
    List<Map<String, dynamic>> fitData) {
  return fitData.map(parseFitDataToSummary).toList();
}

Map<String, dynamic> _analyzeBestScore(Map<String, dynamic> input) {
  final fitData = input['fitData'] as List<Map<String, dynamic>>;
  final routes = input['routes'] as List<List<LatLng>>;
  final rideData = input['rideData'] as Map<String, dynamic>;

  final bestScore = <int, BestScore>{};
  final bestSegment = <int, SortManager<SegmentScore, int>>{};
  final currBestScore = BestScore();

  final orderedFitData = List<Map<String, dynamic>>.from(fitData)
    ..sort((a, b) =>
        (a['sessions'][0].get('timestamp') - b['sessions'][0].get('timestamp'))
            .toInt());

  for (var fitData in orderedFitData) {
    final timestamp = fitData['sessions'][0].get('timestamp');
    final bestScoreForTimestamp = BestScore().update(fitData['records']);
    bestScore[timestamp.toInt()] = BestScore()..merge(currBestScore);
    currBestScore.merge(bestScoreForTimestamp);

    final routePoints = parseFitDataToRoute(fitData);
    final subRoutes = SegmentMatcher().findSegments(routePoints, routes);
    final analysisOfSubRoutes = subRoutes
        .map((item) => parseSegmentToScore(item, rideData, routePoints));
    analysisOfSubRoutes.map((item) {
      if (bestSegment.containsKey(item.segment.segmentIndex)) {
        bestSegment[item.segment.segmentIndex]!
            .append(item, item.startTime.toInt());
      } else {
        bestSegment[item.segment.segmentIndex] =
            SortManager<SegmentScore, int>((a, b) => a.startTime < b.startTime)
              ..append(item, item.startTime.toInt());
      }
    });
  }

  return {'bestScore': bestScore, 'bestSegment': bestSegment};
}

class SortManager<T, K> {
  final bool Function(T a, T b) _comparator;
  final List<Entry<T, K>> _dataList = [];

  SortManager(this._comparator);

  void append(T item, K key) {
    _dataList.add(Entry(item, key));
  }

  int getPosition(K index) {
    final tIndex = _dataList.indexWhere((entry) => entry.key == index);
    if (tIndex == -1) {
      return -1;
    }
    final target = _dataList[tIndex].item;
    final subList = _dataList.sublist(0, tIndex + 1);
    subList.sort((a, b) => _comparator(a.item, b.item)
        ? 1
        : _comparator(b.item, a.item)
            ? -1
            : 0);
    for (int i = 0; i < subList.length; i++) {
      if (identical(subList[i], target)) {
        return i;
      }
    }
    return -1;
  }
}

class Entry<T, K> {
  final T item;
  final K key;

  Entry(this.item, this.key);
}
