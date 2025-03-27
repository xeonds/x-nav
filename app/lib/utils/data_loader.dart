import 'dart:async';
import 'dart:io';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/gpx_parser.dart';
import 'package:app/utils/storage.dart';
import 'package:latlong2/latlong.dart';

class DataLoader {
  static final DataLoader _instance = DataLoader._internal();

  factory DataLoader() => _instance;

  DataLoader._internal();

  final List<List<LatLng>> _routes = [];
  final List<Map<String, dynamic>> _fitData = [];
  final List<List<LatLng>> _histories = [];
  final Map<String, dynamic> _rideData = {};
  final List<Map<String, dynamic>> _summary = [];
  bool _isInitialized = false;

  List<List<LatLng>> get routes => _routes;
  List<List<LatLng>> get histories => _histories;
  Map<String, dynamic> get rideData => _rideData;
  List<Map<String, dynamic>> get summaryList => _summary;
  List<Map<String, dynamic>> get fitData => _fitData;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

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
    final files = await Storage().getGpxFiles();
    for (var file in files) {
      final gpx = File(file.path);
      final gpxData = await gpx.readAsString();
      _routes.add(parseGpxToPath(gpxData));
    }
  }

  Future<void> loadHistoryData() async {
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
    print(_rideData);
  }

  Future<void> loadSummaryData() async {
    _fitData.map((e) => parseFitDataToSummary(e)).forEach((element) {
      _summary.add(element);
    });
  }
}
