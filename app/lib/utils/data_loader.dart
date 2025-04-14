import 'dart:async';
import 'dart:io';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/gpx_parser.dart';
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
  final List<List<LatLng>> _histories = [];
  final Map<String, dynamic> _rideData = {};
  final List<Map<String, dynamic>> _summary = [];
  final Map<int, BestScore> _bestScore = {}; // 修改为 Map<int, BestScore>
  bool isInitialized = false;

  List<List<LatLng>> get routes => _routes;
  List<List<LatLng>> get histories => _histories;
  Map<String, dynamic> get rideData => _rideData;
  List<Map<String, dynamic>> get summaryList => _summary;
  List<Map<String, dynamic>> get fitData => _fitData;
  List<File> get gpxData => _gpxFile;
  Map<int, BestScore> get bestScore => _bestScore; // 修改 getter

  Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;

    await Future.wait([
      loadRouteData(),
      loadHistoryData(),
    ]);

    await Future.wait([
      loadRideData(),
      loadSummaryData(),
    ]);

    await Future.wait([
      loadBestScore(),
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
    }
  }
}
