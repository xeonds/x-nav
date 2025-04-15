import 'dart:async';
import 'dart:io';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/gpx_parser.dart';
import 'package:app/utils/path_utils.dart';
import 'package:app/utils/storage.dart';
import 'package:flutter/foundation.dart';
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
  bool isInitialized = false;

  List<List<LatLng>> get routes => _routes;
  List<List<LatLng>> get histories => _histories;
  Map<String, dynamic> get rideData => _rideData;
  List<Map<String, dynamic>> get summaryList => _summary;
  List<Map<String, dynamic>> get fitData => _fitData;
  List<File> get gpxData => _gpxFile;
  Map<int, BestScore> get bestScore => _bestScore;
  Map<int, SortManager<SegmentScore, int>> get bestSegment => _bestSegment;

  Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;

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

    notifyListeners(); // 通知监听者数据已加载完成
  }

  Future<void> loadRouteData() async {
    _gpxFile.clear(); // 清空现有 GPX 文件列表
    _routes.clear(); // 清空现有路线列表

    final files = await Storage().getGpxFiles();
    print('GPX files: ${files.length}');
    for (var file in files) {
      final gpx = File(file.path);
      _gpxFile.add(gpx);
      late final String gpxData;
      try {
        gpxData = await gpx.readAsString();
      } catch (e) {
        if (kDebugMode) {
          print('Error reading GPX file: $e');
        }
        continue;
      }
      _routes.add(parseGpxToPath(gpxData));
    }

    notifyListeners(); // 通知监听者数据已更新
  }

  Future<void> loadHistoryData() async {
    _fitData.clear(); // 清空现有 FIT 数据列表
    _histories.clear(); // 清空现有历史路线列表

    final files = await Storage().getFitFiles();
    for (var file in files) {
      final fitData = parseFitFile(await file.readAsBytes());
      _fitData.add({...fitData, 'path': file.path});
      _histories.add(parseFitDataToRoute(fitData));
    }

    notifyListeners(); // 通知监听者数据已更新
  }

  Future<void> loadRideData() async {
    _fitData.map((e) => parseFitDataToSummary(e)).fold<Map<String, dynamic>>(
      {'totalDistance': 0.0, 'totalRides': 0, 'totalTime': 0},
      (value, element) {
        return {
          'totalDistance':
              value['totalDistance'] + (element['total_distance'] ?? 0.0),
          'totalRides': value['totalRides'] + 1,
          'totalTime':
              value['totalTime'] + (element['total_elapsed_time'] ?? 0),
        };
      },
    ).forEach((key, value) {
      _rideData[key] = value;
    });

    notifyListeners(); // 通知监听者数据已更新
  }

  Future<void> loadSummaryData() async {
    _summary.clear(); // 清空现有摘要列表
    _fitData.map((e) => parseFitDataToSummary(e)).forEach((element) {
      _summary.add(element);
    });

    notifyListeners(); // 通知监听者数据已更新
  }

  Future<void> loadBestScore() async {
    _bestScore.clear(); // 清空现有最佳成绩映射
    final currBestScore = BestScore();
    final orderedFitData = List<Map<String, dynamic>>.from(_fitData)
      ..sort((a, b) => (a['sessions'][0].get('timestamp') -
              b['sessions'][0].get('timestamp'))
          .toInt());
    // 计算每个时间戳节点的 bestScore
    for (var fitData in orderedFitData) {
      final timestamp = fitData['sessions'][0].get('timestamp');
      final bestScore = BestScore().update(fitData['records']);
      _bestScore[timestamp.toInt()] = BestScore()
        ..merge(currBestScore); // 使用 timestamp 作为键，存储截至上次的最佳成绩
      currBestScore.merge(bestScore);
      final routePoints = parseFitDataToRoute(fitData);
      final subRoutes = SegmentMatcher().findSegments(routePoints, _routes);
      final analysisOfSubRoutes = subRoutes
          .map((item) => parseSegmentToScore(item, rideData, routePoints));
      analysisOfSubRoutes.map((item) {
        if (_bestSegment.containsKey(item.segment.segmentIndex)) {
          _bestSegment[item.segment.segmentIndex]!
              .append(item, item.startTime.toInt());
        } else {
          _bestSegment[item.segment.segmentIndex] = SortManager<SegmentScore,
              int>((a, b) => a.startTime < b.startTime)
            ..append(item, item.startTime.toInt());
        }
      });
    }
  }
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
