import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_parser.dart';
import 'package:app/utils/model.dart';
import 'package:app/utils/path_utils.dart';
import 'package:app/utils/storage.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:gpx/gpx.dart';
import 'package:latlong2/latlong.dart';

class _DataLoadRequest {
  final String appDocPath;
  const _DataLoadRequest(this.appDocPath);
}

class DataLoader extends ChangeNotifier {
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

  // one-time task flag
  bool oneTimeTaskFlag = false;

  Future<void> initialize() async {
    if (!oneTimeTaskFlag) {
      await Future.wait([
        FMTCObjectBoxBackend().initialise(),
        Storage.initialize(),
      ]);
      await FMTCStore('mapStore').manage.create();
      oneTimeTaskFlag = true;
    }

    if (isLoading) return;
    isLoading = true;
    isInitialized = false;
    progressMessage = '准备加载数据...';
    gpxLoaded = false;
    fitLoaded = false;
    summaryLoaded = false;
    rideDataLoaded = false;
    bestScoreLoaded = false;
    String currentStep = '初始化';
    notifyListeners();

    try {
      await runInIsolateWithProgress<_DataLoadRequest>(
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
            if (onGpxLoaded != null) onGpxLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'fit') {
            print('adding id');
            fitData
              ..clear()
              ..addAll(msg['fitData']);
            fitLoaded = true;
            currentStep = '骑行记录加载完成';
            if (onFitLoaded != null) onFitLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'summary') {
            summaryList
              ..clear()
              ..addAll(msg['summary']);
            summaryLoaded = true;
            currentStep = '骑行摘要分析完成';
            if (onSummaryLoaded != null) onSummaryLoaded!();
            notifyListeners();
          } else if (msg is Map && msg['phase'] == 'rideData') {
            rideData
              ..clear()
              ..addAll(msg['rideData']);
            rideDataLoaded = true;
            currentStep = '骑行统计完成';
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
}

// 支持进度消息的异步任务
Future<void> runInIsolateWithProgress<P>({
  required void Function(P, SendPort) entry,
  required P parameter,
  required void Function(dynamic message) onMessage,
}) async {
  final receivePort = ReceivePort();
  await Isolate.spawn<_IsolateProgressMessage<P>>(
    (msg) => msg.entry(msg.parameter, msg.sendPort),
    _IsolateProgressMessage(entry, parameter, receivePort.sendPort),
  );
  await for (final message in receivePort) {
    onMessage(message);
  }
  receivePort.close();
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
      final parsedRoutes = parseGpxFiles(gpxFiles, sendPort: sendPort);
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
      final parsedHistories = parseFitFiles(fitFiles, sendPort: sendPort);
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
    final summary =
        await Future(() => analyzeSummaryData(parsedHistories.values.toList()));
    sendPort.send({
      'phase': 'summary',
      'summary': summary,
    });

    // 统计
    sendPort.send({'progress': '正在统计骑行数据...'});
    final rideData = await Future(() => analyzeRideData(summary));
    sendPort.send({
      'phase': 'rideData',
      'rideData': rideData,
    });

    // 最佳成绩
    sendPort.send({'progress': '正在分析最佳成绩...'});
    final bestScoreData =
        await Future(() => analyzeBestScore(parsedHistories.values.toList()));
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
