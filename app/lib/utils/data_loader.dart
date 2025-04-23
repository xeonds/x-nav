import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/gpx_parser.dart';
import 'package:app/utils/path_utils.dart';
import 'package:app/utils/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

Future<R> runInIsolate<P, R>(R Function(P) function, P parameter) async {
  final receivePort = ReceivePort();
  await Isolate.spawn<_IsolateMessage<P, R>>(
    _isolateEntry,
    _IsolateMessage(function, parameter, receivePort.sendPort),
  );
  return await receivePort.first as R;
}

class _IsolateMessage<P, R> {
  final R Function(P) function;
  final P parameter;
  final SendPort sendPort;

  _IsolateMessage(this.function, this.parameter, this.sendPort);
}

// Entry point for the spawned isolate
void _isolateEntry<P, R>(_IsolateMessage<P, R> message) {
  final result = message.function(message.parameter);
  message.sendPort.send(result);
}

class _DataLoadRequest {
  final String appDocPath;
  const _DataLoadRequest(this.appDocPath);
}

class _DataLoadResult {
  final List<List<LatLng>> routes;
  final List<Map<String, dynamic>> fitData;
  final List<File> gpxFiles;
  final List<List<LatLng>> histories;
  final Map<String, dynamic> rideData;
  final List<Map<String, dynamic>> summary;
  final Map<int, BestScore> bestScore, bestScoreAt;
  final Map<int, SortManager<SegmentScore, int>> bestSegment;

  _DataLoadResult({
    required this.routes,
    required this.fitData,
    required this.gpxFiles,
    required this.histories,
    required this.rideData,
    required this.summary,
    required this.bestScore,
    required this.bestScoreAt,
    required this.bestSegment,
  });
}

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
  final Map<int, BestScore> _bestScore = {}, _bestScoreAt = {};
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
  Map<int, BestScore> get bestScoreAt => _bestScoreAt;
  Map<int, SortManager<SegmentScore, int>> get bestSegment => _bestSegment;

  bool isLoading = false; // 是否正在加载数据

  Future<void> initialize() async {
    if (isLoading) return;
    isLoading = true;
    isInitialized = false;

    // 传递appDocPath到isolate
    final result = await runInIsolate<_DataLoadRequest, _DataLoadResult>(
      (req) => _dataLoadIsolateEntrySync(req),
      _DataLoadRequest(Storage.appDocPath!),
    );

    _routes
      ..clear()
      ..addAll(result.routes);
    _fitData
      ..clear()
      ..addAll(result.fitData);
    _gpxFile
      ..clear()
      ..addAll(result.gpxFiles);
    _histories
      ..clear()
      ..addAll(result.histories);
    _rideData
      ..clear()
      ..addAll(result.rideData);
    _summary
      ..clear()
      ..addAll(result.summary);
    _bestScore
      ..clear()
      ..addAll(result.bestScore);
    _bestScoreAt
      ..clear()
      ..addAll(result.bestScoreAt);
    _bestSegment
      ..clear()
      ..addAll(result.bestSegment);

    isInitialized = true;
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadRouteData() async {}
  Future<void> loadHistoryData() async {}
  Future<void> loadRideData() async {}
  Future<void> loadSummaryData() async {}
  Future<void> loadBestScore() async {}
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

Map<String, dynamic> _analyzeRideData(List<Map<String, dynamic>> summaries) {
  return summaries.fold<Map<String, dynamic>>(
    {'totalDistance': 0.0, 'totalRides': 0, 'totalTime': 0},
    (value, element) => {
      'totalDistance':
          value['totalDistance'] + (element['total_distance'] ?? 0.0),
      'totalRides': value['totalRides'] + 1,
      'totalTime': value['totalTime'] + (element['total_elapsed_time'] ?? 0),
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

  final bestScoreTillTimestamp = <int, BestScore>{};
  final bestScoreAtTimestamp = <int, BestScore>{};
  final bestSegment = <int, SortManager<SegmentScore, int>>{};
  final currBestScore = BestScore();

  final orderedFitData = List<Map<String, dynamic>>.from(fitData)
    ..sort((a, b) => (getTimestampFromDataMessage(a['sessions'][0]) -
            getTimestampFromDataMessage(b['sessions'][0]))
        .toInt());

  for (var fitData in orderedFitData) {
    final timestamp = getTimestampFromDataMessage(fitData['sessions'][0]);
    final bestScoreForTimestamp = BestScore().update(fitData['records']);
    bestScoreTillTimestamp[timestamp] = BestScore()
      ..merge(currBestScore); // copy
    bestScoreAtTimestamp[timestamp] = bestScoreForTimestamp;
    currBestScore.merge(bestScoreForTimestamp);

    final routePoints = parseFitDataToRoute(fitData);
    final subRoutes = SegmentMatcher().findSegments(routePoints, routes);
    final analysisOfSubRoutes = subRoutes
        .map((item) => parseSegmentToScore(item, fitData, routePoints));
    for (var item in analysisOfSubRoutes) {
      if (bestSegment.containsKey(item.segment.segmentIndex)) {
        bestSegment[item.segment.segmentIndex]!
            .append(item, item.startTime.toInt());
      } else {
        bestSegment[item.segment.segmentIndex] =
            SortManager<SegmentScore, int>((a, b) => a.avgSpeed < b.avgSpeed)
              ..append(item, item.startTime.toInt());
      }
    }
  }

  return {
    'bestScore': bestScoreTillTimestamp,
    'bestScoreAt': bestScoreAtTimestamp,
    'bestSegment': bestSegment
  };
}

class SortManager<T, K> {
  final bool Function(T a, T b) _comparator;
  final List<Entry<T, K>> dataList = [];

  SortManager(this._comparator);

  void append(T item, K key) {
    dataList.add(Entry(item, key));
  }

  int getPosition(K index) {
    final tIndex = dataList.indexWhere((entry) => entry.key == index);
    if (tIndex == -1) {
      return -1;
    }
    final target = dataList[tIndex];
    final subList = dataList.sublist(0, tIndex + 1);
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

_DataLoadResult _dataLoadIsolateEntrySync(_DataLoadRequest request) {
  // isolate中设置Storage的appDocPath
  Storage.appDocPath = request.appDocPath;

  final gpxFiles = Storage().getGpxFilesSync();
  final parsedRoutes = _parseGpxFiles(gpxFiles);
  final fitFiles = Storage().getFitFilesSync();
  final parsedHistories = _parseFitFiles(fitFiles);
  final summary = _analyzeSummaryData(parsedHistories['fitData']);
  final rideData = _analyzeRideData(summary);
  final bestScoreData = _analyzeBestScore({
    'fitData': parsedHistories['fitData'],
    'routes': parsedRoutes['routes'],
  });

  return _DataLoadResult(
    routes: parsedRoutes['routes'],
    fitData: parsedHistories['fitData'],
    gpxFiles: parsedRoutes['files'],
    histories: parsedHistories['histories'],
    rideData: rideData,
    summary: summary,
    bestScore: bestScoreData['bestScore'],
    bestScoreAt: bestScoreData['bestScoreAt'],
    bestSegment: bestScoreData['bestSegment'],
  );
}
