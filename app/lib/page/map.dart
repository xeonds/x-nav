import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:fit_parser/fit_parser.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  MapController? _controller;
  bool _showHistory = false;
  bool _showRoute = false;
  List<LatLng> _routePoints = [];
  List<LatLng> _historyPoints = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadRouteData();
    _loadHistoryData();
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
    // 实现定位到当前位置的逻辑
    // 获取当前位置
    final location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // 移动地图到当前位置
    _controller?.move(LatLng(location.latitude, location.longitude), 15);
  }

  Future<void> _loadRouteData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/route.gpx');
    if (await file.exists()) {
      final document = xml.XmlDocument.parse(await file.readAsString());
      final points = document.findAllElements('trkpt');
      setState(() {
        _routePoints = points.map((point) {
          final lat = double.parse(point.getAttribute('lat')!);
          final lon = double.parse(point.getAttribute('lon')!);
          return LatLng(lat, lon);
        }).toList();
      });
    }
  }

  Future<void> _loadHistoryData() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/history.fit';
    final fitFile = FitFile(path: path).parse();
    final records =
        fitFile.dataMessages.where((msg) => msg.get('record') != null);
    setState(() {
      _historyPoints = records.map((record) {
        final lat = record.get('position_lat')! / 1e7;
        final lon = record.get('position_long')! / 1e7;
        return LatLng(lat, lon);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          initialCenter: LatLng(37.7749, -122.4194),
          initialZoom: 10,
          onTap: (tapPosition, point) => print(point),
        ),
        mapController: _controller,
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          if (_showRoute)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: Colors.blue,
                  strokeWidth: 5,
                ),
              ],
            ),
          if (_showHistory)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _historyPoints,
                  color: Colors.red,
                  strokeWidth: 5,
                ),
              ],
            ),
          if (_showHistory && _historyPoints.isNotEmpty)
            MarkerLayer(
              markers: [
                Marker(
                    point: _historyPoints.last,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                    )),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _locatePosition,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
