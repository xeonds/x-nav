import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:app/database.dart';
import 'package:app/utils/data_parser.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/path_utils.dart';
import 'package:app/utils/storage.dart';
import 'package:drift/drift.dart';
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

  // final List<List<LatLng>> routes = [];
  // final Map<String, String> gpxData = {};
  // final List<List<Message>> histories = []; // 历史路径
  // final Map<String, List<Message>> fitData = {};
  // final Map<String, dynamic> rideData = {}; // 骑行历史统计信息
  // final List<Map<String, dynamic>> summaryList = []; // 每个骑行记录对应的摘要
  // final Map<int, BestScore> bestScore = {}, bestScoreAt = {};
  // final Map<int, SortManager<Segment, int>> bestSegment =
  //     {}; // 任意赛段，截至任意时间戳的最佳记录
  // final Map<int, List<Segment>> subRoutesOfRoutes = {};

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
  // 数据库连接
  final Database database = Database();

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
          } else if (msg is Map && msg['phase'] == 'finish') {
            currentStep = '分析完成';
            // TODO: 加载数据到对象中/对象暴露getter提供即时数据拉取检索
            isInitialized = true;
            isLoading = false;
            progressMessage = null;
            notifyListeners();
            // else if (msg is Map && msg['phase'] == 'gpx') {
            //   routes
            //     ..clear()
            //     ..addAll(msg['routes']);
            //   gpxData
            //     ..clear()
            //     ..addAll(msg['gpxData']);
            //   gpxLoaded = true;
            //   currentStep = '路书加载完成';
            //   if (onGpxLoaded != null) onGpxLoaded!();
            //   notifyListeners();
            // } else if (msg is Map && msg['phase'] == 'fit') {
            //   print('adding id');
            //   fitData
            //     ..clear()
            //     ..addAll(msg['fitData']);
            //   fitLoaded = true;
            //   currentStep = '骑行记录加载完成';
            //   if (onFitLoaded != null) onFitLoaded!();
            //   notifyListeners();
            // } else if (msg is Map && msg['phase'] == 'summary') {
            //   summaryList
            //     ..clear()
            //     ..addAll(msg['summary']);
            //   summaryLoaded = true;
            //   currentStep = '骑行摘要分析完成';
            //   if (onSummaryLoaded != null) onSummaryLoaded!();
            //   notifyListeners();
            // } else if (msg is Map && msg['phase'] == 'rideData') {
            //   rideData
            //     ..clear()
            //     ..addAll(msg['rideData']);
            //   rideDataLoaded = true;
            //   currentStep = '骑行统计完成';
            //   if (onRideDataLoaded != null) onRideDataLoaded!();
            //   notifyListeners();
            // } else if (msg is Map && msg['phase'] == 'bestScore') {
            //   bestScore
            //     ..clear()
            //     ..addAll(msg['bestScore']);
            //   bestScoreAt
            //     ..clear()
            //     ..addAll(msg['bestScoreAt']);
            //   bestSegment
            //     ..clear()
            //     ..addAll(msg['bestSegment']);
            //   subRoutesOfRoutes
            //     ..clear()
            //     ..addAll(msg['subRoutesOfRoutes']);
            //   bestScoreLoaded = true;
            //   currentStep = '最佳成绩分析完成';
            // }
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
    sendPort.send({'progress': '正在初始化数据库...'});
    final db = Database();

    // GPX
    sendPort.send({'progress': '正在读取路书...'});
    await Future(() {
      final gpxFiles = Storage().getGpxFilesSync();
      for (var i = 0; i < gpxFiles.length; i++) {
        try {
          final file = gpxFiles[i];
          final str = parseGpxFile(file);
          final parsed = GpxReader().fromString(str);
          final path = parsed.trks.first.trksegs.first.trkpts
              .map((e) => LatLng(e.lat!, e.lon!))
              .toList();
          final distance = latlngToDistance(path);
          db.into(db.routes).insertOnConflictUpdate(RoutesCompanion.insert(
              filePath: file.path, distance: distance, route: path));
          sendPort.send({'progress': '路书解析中： ${i + 1}/${gpxFiles.length}'});
        } catch (e) {
          debugPrint('Error reading GPX file: $e');
        }
      }
    });

    // FIT
    sendPort.send({'progress': '正在分析骑行记录...'});
    await Future(() async {
      final fitFiles = Storage().getFitFilesSync();
      for (var i = 0; i < fitFiles.length; i++) {
        try {
          final file = fitFiles[i];
          final fitMsgs = parseFitFile(file);
          final session = fitMsgs.whereType<SessionMessage>().toList().first;
          final records = fitMsgs.whereType<RecordMessage>().toList();
          final path = records
              .map((r) => LatLng(r.positionLat ?? 0, r.positionLong ?? 0));
          final historyId = await db.into(db.historys).insert(
              HistorysCompanion.insert(
                  filePath: file.path,
                  createdAt: Value(DateTime(session.startTime ?? 0)),
                  route: path.toList()));
          db.into(db.records).insert(
              RecordsCompanion.insert(historyId: historyId, messages: records),
              mode: InsertMode.insertOrReplace);
          db.into(db.summarys).insert(SummarysCompanion.insert(
              timestamp: Value(session.timestamp),
              startTime: Value(DateTime(session.startTime!)),
              sport: Value(session.sport?.name),
              maxTemperature: Value(session.maxTemperature?.toDouble()),
              avgTemperature: Value(session.avgTemperature?.toDouble()),
              totalAscent: Value(session.totalAscent?.toDouble()),
              totalDescent: Value(session.totalDescent?.toDouble()),
              totalDistance: Value(session.totalDistance),
              totalElapsedTime: Value(session.totalElapsedTime)));
          sendPort.send({'progress': '骑行记录解析中： ${i + 1}/${fitFiles.length}'});
        } catch (e) {
          debugPrint('Error reading fit file: $e');
        }
      }
    });

    // 统计
    sendPort.send({'progress': '正在统计数据...'});
    await Future(() async {
      final summary = await db.select(db.summarys).get();
      final data = analyzeRideData(summary);
      for (var item in data.entries) {
        db.into(db.kVs).insert(
            mode: InsertMode.replace,
            KVsCompanion.insert(key: item.key, value: item.value.toString()));
      }
    });

    // 最佳成绩
    sendPort.send({'progress': '正在分析最佳成绩...'});
    await Future(() async {
      final history = await db.select(db.historys).get();
      for (var item in history) {
        final summary = await (db.select(db.summarys)
              ..where((s) => s.id.equals(item.summaryId ?? 0)))
            .getSingleOrNull();
        if (summary == null) continue;
        final record = await (db.select(db.records)
              ..where((r) => r.historyId.equals(item.id)))
            .getSingleOrNull();
        final res = analyzeBestScore(summary, record!);
        db.into(db.bestScores).insert(res);
      }
    });

    sendPort.send({'progress': '正在分析赛段成绩..'});
    await Future(() async {
      final routes = await db.select(db.routes).get();
      final histories = await db.select(db.historys).get();
      for (var item in histories) {
        final summary = await (db.select(db.summarys)
              ..where((s) => s.id.equals(item.summaryId ?? 0)))
            .getSingleOrNull();
        if (summary == null) continue;
        final record = await (db.select(db.records)
              ..where((r) => r.historyId.equals(item.id)))
            .getSingleOrNull();
        if (record == null) continue;
        final segments = await analyzeSegment(routes, record.messages, item);
        for (final segment in segments) {
          await db.into(db.segments).insert(segment);
        }
        sendPort.send({'progress': '赛段成绩分析中： ${item.filePath}'});
      }
    });
    sendPort.send({'phase': 'finish'});
  } catch (e, st) {
    sendPort.send({'error': e.toString(), 'stack': st.toString()});
  }
}
