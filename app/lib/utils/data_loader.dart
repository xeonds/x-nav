import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:app/database.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/path_utils.dart';
import 'package:app/utils/storage.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';

class _DataLoadRequest {
  final String appDocPath;
  const _DataLoadRequest(this.appDocPath);
}

class _DataLoadResult {
  final List<List<LatLng>> routes;
  final List<List<LatLng>> histories;
  final List<Map<String, dynamic>> fitData;
  final List<File> gpxFiles;
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
  // 缓存一致性检测：判断底层文件是否发生变化
  Future<bool> isCacheStale() async {
    // 获取当前文件列表和修改时间
    final gpxFiles = Storage().getGpxFilesSync();
    final fitFiles = Storage().getFitFilesSync();
    final gpxMeta = gpxFiles
        .map((f) => {
              'path': f.path,
              'mtime': f.lastModifiedSync().millisecondsSinceEpoch
            })
        .toList();
    final fitMeta = fitFiles
        .map((f) => {
              'path': f.path,
              'mtime': f.lastModifiedSync().millisecondsSinceEpoch
            })
        .toList();
    // 从数据库读取上次文件快照
    final db = await dbHelper.database;
    final res =
        await db.query('cache', where: 'key = ?', whereArgs: ['fileMeta']);
    if (res.isEmpty) return true;
    try {
      final lastMeta = jsonDecode(res.first['value'] as String);
      // 比较快照
      if (jsonEncode(lastMeta['gpx']) != jsonEncode(gpxMeta) ||
          jsonEncode(lastMeta['fit']) != jsonEncode(fitMeta)) {
        return true;
      }
      return false;
    } catch (e) {
      return true;
    }
  }

  // 更新文件快照到数据库
  Future<void> updateFileMetaCache() async {
    final gpxFiles = Storage().getGpxFilesSync();
    final fitFiles = Storage().getFitFilesSync();
    final gpxMeta = gpxFiles
        .map((f) => {
              'path': f.path,
              'mtime': f.lastModifiedSync().millisecondsSinceEpoch
            })
        .toList();
    final fitMeta = fitFiles
        .map((f) => {
              'path': f.path,
              'mtime': f.lastModifiedSync().millisecondsSinceEpoch
            })
        .toList();
    await saveCache('fileMeta', {'gpx': gpxMeta, 'fit': fitMeta});
  }

  // 新增：数据库实例
  final dbHelper = DatabaseHelper();

  // 数据库缓存相关方法
  Future<Map<String, dynamic>?> getAllCache() async {
    final db = await dbHelper.database;
    final res = await db.query('cache');
    if (res.isEmpty) return null;
    final Map<String, dynamic> result = {};
    for (final row in res) {
      try {
        result[row['key'] as String] =
            row['value'] != null ? jsonDecode(row['value'] as String) : null;
      } catch (e) {
        result[row['key'] as String] = null;
      }
    }
    return result;
  }

  Future<void> saveCache(String key, dynamic value) async {
    final db = await dbHelper.database;
    final valueStr = jsonEncode(value);
    await db.insert(
      'cache',
      {'key': key, 'value': valueStr},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static final DataLoader _instance = DataLoader._internal();

  factory DataLoader() => _instance;

  DataLoader._internal();

  final List<List<LatLng>> routes = [];
  final Map<String, String> gpxData = {};
  final List<List<Message>> histories = []; // 历史路径
  final Map<String, List<Message>> fitData = {};
  final Map<String, dynamic> rideData = {}; // 骑行历史统计信息
  final List<Map<String, dynamic>> summaryList = []; // 每个骑行记录对应的摘要
  final Map<int, BestScore> bestScore = {}, bestScoreAt = {};
  final Map<int, SortManager<SegmentScore, int>> bestSegment =
      {}; // 任意赛段，截至任意时间戳的最佳记录
  final Map<int, List<SegmentScore>> subRoutesOfRoutes = {};

  // 获取 MBTiles 文件列表
  static Future<List<String>> listMbtilesFiles() async {
    // 默认存储在 appDocPath/mbtiles 目录下
    if (Storage.appDocPath == null) {
      await Storage.initialize();
    }
    final dir = Directory('${Storage.appDocPath}/mbtiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mbtiles'))
        .map((f) => f.path)
        .toList();
    return files;
  }

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

  Future<void> initialize() async {
    await Future.wait([
      FMTCObjectBoxBackend().initialise(),
      Storage.initialize(),
    ]);
    await FMTCStore('mapStore').manage.create();

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

    String currentStep = '初始化';

    try {
      // 检查底层文件是否发生变化
      final cacheStale = await isCacheStale();
      final cached = await getAllCache();
      if (!cacheStale && cached != null && cached.isNotEmpty) {
        // 直接复用数据库缓存
        routes
          ..clear()
          ..addAll(cached['routes'] ?? []);
        gpxData
          ..clear()
          ..addAll(cached['gpxData'] ?? {});
        fitData
          ..clear()
          ..addAll(cached['fitData'] ?? {});
        summaryList
          ..clear()
          ..addAll(cached['summary'] ?? []);
        rideData
          ..clear()
          ..addAll(cached['rideData'] ?? {});
        bestScore
          ..clear()
          ..addAll(cached['bestScore'] ?? {});
        bestScoreAt
          ..clear()
          ..addAll(cached['bestScoreAt'] ?? {});
        bestSegment
          ..clear()
          ..addAll(cached['bestSegment'] ?? {});
        subRoutesOfRoutes
          ..clear()
          ..addAll(cached['subRoutesOfRoutes'] ?? {});
        gpxLoaded = true;
        fitLoaded = true;
        summaryLoaded = true;
        rideDataLoaded = true;
        bestScoreLoaded = true;
        isInitialized = true;
        isLoading = false;
        progressMessage = null;
        notifyListeners();
        return;
      }

      // 文件有变动或无缓存，重新计算并更新数据库快照
      await runInIsolateWithProgress<_DataLoadRequest, _DataLoadResult>(
        entry: _dataLoadIsolateEntryWithProgressPhased,
        parameter: _DataLoadRequest(Storage.appDocPath!),
        onMessage: (msg) async {
          if (msg is Map && msg['progress'] != null) {
            progressMessage = msg['progress'];
            currentStep = msg['progress']; // 记录当前进度
            notifyListeners();
          } else if (msg is Map && msg['error'] != null) {
            progressMessage = '加载失败: ${msg['error']}（步骤：$currentStep）';
            isLoading = false;
            isInitialized = false;
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'gpx') {
            routes
              ..clear()
              ..addAll(msg['routes']);
            gpxData
              ..clear()
              ..addAll(msg['gpxData']);
            gpxLoaded = true;
            currentStep = '路书加载完成';
            await saveCache('routes', routes);
            await saveCache('gpxData', gpxData);
            await updateFileMetaCache(); // 更新文件快照
            if (onGpxLoaded != null) onGpxLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'fit') {
            print('adding id');
            fitData
              ..clear()
              ..addAll(msg['fitData']);
            fitLoaded = true;
            currentStep = '骑行记录加载完成';
            await saveCache('fitData', fitData);
            await updateFileMetaCache(); // 更新文件快照
            if (onFitLoaded != null) onFitLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'summary') {
            summaryList
              ..clear()
              ..addAll(msg['summary']);
            summaryLoaded = true;
            currentStep = '骑行摘要分析完成';
            await saveCache('summary', summaryList);
            if (onSummaryLoaded != null) onSummaryLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'rideData') {
            rideData
              ..clear()
              ..addAll(msg['rideData']);
            rideDataLoaded = true;
            currentStep = '骑行统计完成';
            await saveCache('rideData', rideData);
            if (onRideDataLoaded != null) onRideDataLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'bestScore') {
            bestScore
              ..clear()
              ..addAll(msg['bestScore']);
            bestScoreAt
              ..clear()
              ..addAll(msg['bestScoreAt']);
            bestSegment
              ..clear()
              ..addAll(msg['bestSegment']);
            subRoutesOfRoutes
              ..clear()
              ..addAll(msg['subRoutesOfRoutes']);
            bestScoreLoaded = true;
            currentStep = '最佳成绩分析完成';
            await saveCache('bestScore', bestScore);
            await saveCache('bestScoreAt', bestScoreAt);
            await saveCache('bestSegment', bestSegment);
            await saveCache('subRoutesOfRoutes', subRoutesOfRoutes);
            isInitialized = true;
            isLoading = false;
            progressMessage = null;
            notifyListeners();
          }
        },
      );
    } catch (e) {
      progressMessage = '加载失败: ${e.toString()}（步骤：$currentStep）';
      print('err in catch, step: $currentStep');
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

Map<String, String> _parseGpxFiles(List<File> files, {SendPort? sendPort}) {
  final gpxFiles = <String, String>{};
  int count = 0;

  for (var file in files) {
    try {
      final gpxData = file.readAsStringSync();
      gpxFiles[file.path] = gpxData;
      sendPort?.send({'progress': '路书解析中： ${count++}/${files.length}'});
    } catch (e) {
      debugPrint('Error reading GPX file: $e');
    }
  }

  return gpxFiles;
}

Map<String, List<Message>> _parseFitFiles(List<File> files,
    {SendPort? sendPort}) {
  final fitDataList = <String, List<Message>>{};
  int count = 0;

  for (var file in files) {
    fitDataList[file.path] = parseFitFile(file);
    sendPort?.send({'progress': '骑行记录解析中： ${count++}/${files.length}'});
  }
  return fitDataList;
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

List<Map<String, dynamic>> _analyzeSummaryData(List<List<Message>> fitData) {
  return fitData
      .map<SessionMessage>(parseFitDataToSummary)
      .map<Map<String, dynamic>>((session) {
    return {
      "timestamp": session.timestamp,
      "start_time": session.startTime,
      "sport": session.sport,
      "max_temperature": session.maxTemperature,
      "avg_temperature": session.avgTemperature,
      "total_ascent": session.totalAscent,
      "total_descent": session.totalDescent,
      "total_distance": session.totalDistance,
      "total_elapsed_time": session.totalElapsedTime,
    };
  }).toList();
}

Map<String, dynamic> _analyzeBestScore(List<List<Message>> data) {
  final routes = data.map((record) => parseFitDataToRoute(record)).toList();

  final bestScoreTillNow = <int, BestScore>{};
  final bestScoreAtTimestamp = <int, BestScore>{};
  final bestSegment = <int, SortManager<SegmentScore, int>>{};
  final currBestScore = BestScore();
  final subRoutesOfRoutes = <int, List<SegmentScore>>{};

  final orderedFitData = data
    ..sort((a, b) => (timestampWithOffset(
                a.whereType<SessionMessage>().first.startTime!) -
            timestampWithOffset(b.whereType<SessionMessage>().first.startTime!))
        .toInt());

  for (var fitData in orderedFitData) {
    final timestamp = timestampWithOffset(
        fitData.whereType<SessionMessage>().first.startTime!);
    final bestScoreForTimestamp = BestScore().update(fitData);
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

    // GPX
    sendPort.send({'progress': '正在读取路书...'});
    final parsedRoutes = await Future(() {
      final gpxFiles = Storage().getGpxFilesSync();
      final parsedRoutes = _parseGpxFiles(gpxFiles, sendPort: sendPort);
      print('all gpx parsed');
      return parsedRoutes;
    });
    sendPort.send({
      'phase': 'gpx',
      'routes': parsedRoutes.values.map((e) => GpxReader()
          .fromString(e)
          .trks
          .first
          .trksegs
          .first
          .trkpts
          .map((p) => LatLng(p.lat!, p.lon!))
          .toList()),
      'gpxData': parsedRoutes,
    });

    // FIT
    sendPort.send({'progress': '正在读取骑行记录...'});
    final parsedHistories = await Future(() {
      final fitFiles = Storage().getFitFilesSync();
      final parsedHistories = _parseFitFiles(fitFiles, sendPort: sendPort);
      print('all fit parsed');
      return parsedHistories;
    });
    sendPort.send({
      'phase': 'fit',
      'fitData': parsedHistories,
    });

    // 摘要
    sendPort.send({'progress': '正在分析骑行摘要...'});
    print('start analyzing summary');
    final summary = await Future(
        () => _analyzeSummaryData(parsedHistories.values.toList()));
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
    final bestScoreData =
        await Future(() => _analyzeBestScore(parsedHistories.values.toList()));
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
