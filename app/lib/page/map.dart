import 'dart:io';
import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/gpx_parser.dart';
import 'package:app/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.onFullScreenToggle});
  // 一个有bool参数的回调函数
  final ValueChanged<bool>? onFullScreenToggle;

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late MapController _controller;
  bool _showHistory = false;
  bool _showRoute = false;
  List<List<LatLng>> _routes = [];
  List<List<LatLng>> _histories = [];
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  Marker selectedMarker = const Marker(
    point: LatLng(34.1301578, 108.8277069),
    child: Icon(
      Icons.location_on,
      size: 80.0,
      color: Colors.red,
    ),
  );
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadRouteData();
    _loadHistoryData();
    _controller = MapController();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showHistory = prefs.getBool('showHistory') ?? false;
      _showRoute = prefs.getBool('showRoute') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showHistory', _showHistory);
    prefs.setBool('showRoute', _showRoute);
  }

  void _toggleHistory(bool value) {
    setState(() {
      _showHistory = value;
      _savePreferences();
    });
  }

  void _toggleRoute(bool value) {
    setState(() {
      _showRoute = value;
      _savePreferences();
    });
  }

  void _locatePosition() async {
    final location = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(location.latitude, location.longitude);
      _controller.move(_currentPosition, 15);
      selectedMarker = Marker(
        width: 80.0,
        height: 80.0,
        point: _currentPosition,
        child: const Icon(
          Icons.location_on,
          size: 80.0,
          color: Colors.red,
        ),
      );
    });
  }

  Future<void> _loadRouteData() async {
    final files = await Storage().getGpxFiles();
    _routes = files.map((file) {
      final gpx = File(file.path); // 从文件中读取gpx数据
      final gpxData = gpx.readAsStringSync();
      return parseGpxToPath(gpxData);
    }).toList();
  }

  Future<void> _loadHistoryData() async {
    final files = await Storage().getFitFiles();
    final fit = files.map((item) {
      return parseFitFile(item.path);
    }).toList();
    _histories = fit.map((item) {
      return (item['points'] as List)
          .map((point) => LatLng(point['lat'], point['lon']))
          .toList();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text('地图页面'),
              actions: [
                PopupMenuButton(
                  icon: const Icon(Icons.layers),
                  itemBuilder: (context) => [
                    CheckedPopupMenuItem(
                      value: 'showHistory',
                      checked: _showHistory,
                      child: const Text('显示历史活动'),
                    ),
                    CheckedPopupMenuItem(
                      value: 'showRoute',
                      checked: _showRoute,
                      child: const Text('显示路书'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'showHistory') {
                      _toggleHistory(!_showHistory);
                    } else if (value == 'showRoute') {
                      _toggleRoute(!_showRoute);
                    }
                  },
                ),
              ],
            ),
      body: FlutterMap(
        options: MapOptions(
            initialCenter: const LatLng(34.1301578, 108.8277069),
            initialZoom: 10,
            onTap: (tapPosition, point) {
              selectedMarker = Marker(
                child: const Icon(Icons.location_on),
                point: point,
              );
            }),
        mapController: _controller,
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          if (_showRoute)
            PolylineLayer(
              polylines: () {
                final polylines = <Polyline>[];
                for (var route in _routes) {
                  polylines.add(Polyline(
                    points: route,
                    color: Colors.deepOrange,
                    strokeWidth: 5,
                  ));
                }
                return polylines;
              }(),
            ),
          if (_showHistory)
            PolylineLayer(
              polylines: () {
                final polylines = <Polyline>[];
                for (var history in _histories) {
                  polylines.add(Polyline(
                    points: history,
                    color: Colors.orange,
                    strokeWidth: 5,
                  ));
                }
                return polylines;
              }(),
            ),
          if (_showHistory && _histories.isNotEmpty)
            MarkerLayer(
              markers: [selectedMarker],
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _locatePosition,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
                widget.onFullScreenToggle?.call(_isFullScreen);
              });
            },
            child:
                Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
        ],
      ),
    );
  }
}
