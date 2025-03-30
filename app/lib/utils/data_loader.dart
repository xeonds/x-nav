import 'dart:async';
import 'dart:io';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/gpx_parser.dart';
import 'package:app/utils/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class DataLoader {
  static final DataLoader _instance = DataLoader._internal();

  factory DataLoader() => _instance;

  DataLoader._internal();

  final List<List<LatLng>> _routes = [];
  final List<Map<String, dynamic>> _fitData = [];
  final List<File> _gpxFile = [];
  final List<List<LatLng>> _histories = [];
  final Map<String, dynamic> _rideData = {};
  final List<Map<String, dynamic>> _summary = [];
  bool isInitialized = false;

  List<List<LatLng>> get routes => _routes;
  List<List<LatLng>> get histories => _histories;
  Map<String, dynamic> get rideData => _rideData;
  List<Map<String, dynamic>> get summaryList => _summary;
  List<Map<String, dynamic>> get fitData => _fitData;
  List<File> get gpxData => _gpxFile;

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
  }

  Future<void> loadHistoryData() async {
    _fitData.clear(); // 清空现有 FIT 数据列表
    _histories.clear(); // 清空现有历史路线列表

    final files = await Storage().getFitFiles();
    for (var file in files) {
      final fitData = parseFitFile(await file.readAsBytes());
      _fitData.add(fitData);
      _histories.add(parseFitDataToRoute(fitData));
    }
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
  }

  Future<void> loadSummaryData() async {
    _summary.clear(); // 清空现有摘要列表
    _fitData.map((e) => parseFitDataToSummary(e)).forEach((element) {
      _summary.add(element);
    });
  }
}
