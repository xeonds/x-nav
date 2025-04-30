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
  final Map<int, List<SegmentScore>> subRoutesOfRoutes;

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
    required this.subRoutesOfRoutes,
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
  final Map<int, List<SegmentScore>> _subRoutesOfRoutes = {};
  final FMTCTileProvider tileProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
  );
  bool isInitialized = false;

  // 新增：阶段性加载状态
  bool isLoading = false;
  String? progressMessage;
  bool gpxLoaded = false;
  bool fitLoaded = false;
  bool summaryLoaded = false;
  bool rideDataLoaded = false;
  bool bestScoreLoaded = false;

  // 新增：阶段性回调
  VoidCallback? onGpxLoaded;
  VoidCallback? onFitLoaded;
  VoidCallback? onSummaryLoaded;
  VoidCallback? onRideDataLoaded;
  VoidCallback? onBestScoreLoaded;

  List<List<LatLng>> get routes => _routes;
  List<List<LatLng>> get histories => _histories;
  Map<String, dynamic> get rideData => _rideData;
  List<Map<String, dynamic>> get summaryList => _summary;
  List<Map<String, dynamic>> get fitData => _fitData;
  List<File> get gpxData => _gpxFile;
  Map<int, BestScore> get bestScore => _bestScore;
  Map<int, BestScore> get bestScoreAt => _bestScoreAt;
  Map<int, SortManager<SegmentScore, int>> get bestSegment => _bestSegment;
  Map<int, List<SegmentScore>> get subRoutesOfRoutes => _subRoutesOfRoutes;

  Future<void> initialize() async {
    if (isLoading) return;
    isLoading = true;
    isInitialized = false;
    progressMessage = '准备加载数据...';
    gpxLoaded = false;
    fitLoaded = false;
    summaryLoaded = false;
    rideDataLoaded = false;
    bestScoreLoaded = false;
    notifyListeners();

    try {
      await runInIsolateWithProgress<_DataLoadRequest, _DataLoadResult>(
        entry: _dataLoadIsolateEntryWithProgressPhased,
        parameter: _DataLoadRequest(Storage.appDocPath!),
        onMessage: (msg) {
          if (msg is Map && msg['progress'] != null) {
            progressMessage = msg['progress'];
            notifyListeners();
          } else if (msg is Map && msg['error'] != null) {
            progressMessage = '加载失败: ${msg['error']}';
            isLoading = false;
            isInitialized = false;
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'gpx') {
            _routes
              ..clear()
              ..addAll(msg['routes']);
            _gpxFile
              ..clear()
              ..addAll(msg['gpxFiles']);
            gpxLoaded = true;
            if (onGpxLoaded != null) onGpxLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'fit') {
            _fitData
              ..clear()
              ..addAll(msg['fitData']);
            _histories
              ..clear()
              ..addAll(msg['histories']);
            fitLoaded = true;
            if (onFitLoaded != null) onFitLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'summary') {
            _summary
              ..clear()
              ..addAll(msg['summary']);
            summaryLoaded = true;
            if (onSummaryLoaded != null) onSummaryLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'rideData') {
            _rideData
              ..clear()
              ..addAll(msg['rideData']);
            rideDataLoaded = true;
            if (onRideDataLoaded != null) onRideDataLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'bestScore') {
            _bestScore
              ..clear()
              ..addAll(msg['bestScore']);
            _bestScoreAt
              ..clear()
              ..addAll(msg['bestScoreAt']);
            _bestSegment
              ..clear()
              ..addAll(msg['bestSegment']);
            _subRoutesOfRoutes
              ..clear()
              ..addAll(msg['subRoutesOfRoutes']);
            bestScoreLoaded = true;
            if (onBestScoreLoaded != null) onBestScoreLoaded!();
            isInitialized = true;
            isLoading = false;
            progressMessage = null;
            notifyListeners();
          }
        },
      );
    } catch (e) {
      progressMessage = '加载失败: ${e.toString()}';
      isLoading = false;
      isInitialized = false;
      notifyListeners();
    }
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

  final bestScoreTillNow = <int, BestScore>{};
  final bestScoreAtTimestamp = <int, BestScore>{};
  final bestSegment = <int, SortManager<SegmentScore, int>>{};
  final currBestScore = BestScore();
  final subRoutesOfRoutes = <int, List<SegmentScore>>{};

  final orderedFitData = List<Map<String, dynamic>>.from(fitData)
    ..sort((a, b) => (getTimestampFromDataMessage(a['sessions'][0]) -
            getTimestampFromDataMessage(b['sessions'][0]))
        .toInt());

  for (var fitData in orderedFitData) {
    final timestamp = getTimestampFromDataMessage(fitData['sessions'][0]);
    final bestScoreForTimestamp = BestScore().update(fitData['records']);
    // modified, because merge current bestscore don't mix new best's judgement
    currBestScore.merge(bestScoreForTimestamp);
    bestScoreTillNow[timestamp] = BestScore()..merge(currBestScore); // copy
    bestScoreAtTimestamp[timestamp] = bestScoreForTimestamp;
    final routePoints = parseFitDataToRoute(fitData);
    final subRoutes = SegmentMatcher().findSegments(routePoints, routes);
    final analysisOfSubRoutes = subRoutes
        .map((item) => parseSegmentToScore(item, fitData, routePoints))
        .toList();
    subRoutesOfRoutes[timestamp] = analysisOfSubRoutes;
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
    'bestScore': bestScoreTillNow,
    'bestScoreAt': bestScoreAtTimestamp,
    'bestSegment': bestSegment,
    'subRoutesOfRoutes': subRoutesOfRoutes,
  };
}

// 支持进度消息的异步任务
Future<R> runInIsolateWithProgress<P, R>({
  required void Function(P, SendPort) entry,
  required P parameter,
  required void Function(dynamic message) onMessage,
}) async {
  final receivePort = ReceivePort();
  await Isolate.spawn<_IsolateProgressMessage<P>>(
    (msg) => msg.entry(msg.parameter, msg.sendPort),
    _IsolateProgressMessage(entry, parameter, receivePort.sendPort),
  );
  late R result;
  await for (final message in receivePort) {
    onMessage(message);
    if (message is R) {
      result = message;
      break;
    }
  }
  receivePort.close();
  return result;
}

class _IsolateProgressMessage<P> {
  final void Function(P, SendPort) entry;
  final P parameter;
  final SendPort sendPort;
  _IsolateProgressMessage(this.entry, this.parameter, this.sendPort);
}

// 新增：分阶段并行加载的isolate入口
void _dataLoadIsolateEntryWithProgressPhased(
    _DataLoadRequest request, SendPort sendPort) async {
  try {
    sendPort.send({'progress': '正在初始化存储...'});
    Storage.appDocPath = request.appDocPath;

    // 并行读取GPX和FIT文件
    final gpxFuture = Future(() {
      final gpxFiles = Storage().getGpxFilesSync();
      final parsedRoutes = _parseGpxFiles(gpxFiles);
      return parsedRoutes;
    });
    final fitFuture = Future(() {
      final fitFiles = Storage().getFitFilesSync();
      final parsedHistories = _parseFitFiles(fitFiles);
      return parsedHistories;
    });

    // GPX
    final parsedRoutes = await gpxFuture;
    sendPort.send({
      'phase': 'gpx',
      'routes': parsedRoutes['routes'],
      'gpxFiles': parsedRoutes['files'],
    });

    // FIT
    final parsedHistories = await fitFuture;
    sendPort.send({
      'phase': 'fit',
      'fitData': parsedHistories['fitData'],
      'histories': parsedHistories['histories'],
    });

    // 摘要
    sendPort.send({'progress': '正在分析骑行摘要...'});
    final summary =
        await Future(() => _analyzeSummaryData(parsedHistories['fitData']));
    sendPort.send({
      'phase': 'summary',
      'summary': summary,
    });

    // 统计
    sendPort.send({'progress': '正在统计骑行数据...'});
    final rideData = await Future(() => _analyzeRideData(summary));
    sendPort.send({
      'phase': 'rideData',
      'rideData': rideData,
    });

    // 最佳成绩
    sendPort.send({'progress': '正在分析最佳成绩...'});
    final bestScoreData = await Future(() => _analyzeBestScore({
          'fitData': parsedHistories['fitData'],
          'routes': parsedRoutes['routes'],
        }));
    sendPort.send({
      'phase': 'bestScore',
      'bestScore': bestScoreData['bestScore'],
      'bestScoreAt': bestScoreData['bestScoreAt'],
      'bestSegment': bestScoreData['bestSegment'],
      'subRoutesOfRoutes': bestScoreData['subRoutesOfRoutes'],
    });
  } catch (e, st) {
    sendPort.send({'error': e.toString(), 'stack': st.toString()});
  }
}
