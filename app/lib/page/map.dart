import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/utils/data_loader.dart';

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
  bool _showMap = false;
  List<List<LatLng>> _routes = [];
  List<List<LatLng>> _histories = [];
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  Marker selectedMarker = const Marker(
    point: LatLng(34.1301578, 108.8277069),
    child: Icon(Icons.location_on),
  );
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initializeData();
    _controller = MapController();
  }

  Future<void> _initializeData() async {
    await DataLoader().initialize();
    setState(() {
      _routes = DataLoader().routes;
      _histories = DataLoader().histories;
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showHistory = prefs.getBool('showHistory') ?? false;
      _showRoute = prefs.getBool('showRoute') ?? false;
      _showMap = prefs.getBool('showMap') ?? false;
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showHistory', _showHistory);
    prefs.setBool('showRoute', _showRoute);
    prefs.setBool('showMap', _showMap);
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

  void _toggleMap(bool value) {
    setState(() {
      _showMap = value;
      _savePreferences();
    });
  }

  void _locatePosition() async {
    final location = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(location.latitude, location.longitude);
      _controller.move(_currentPosition, 15);
      selectedMarker = Marker(
        point: _currentPosition,
        child: const Icon(Icons.location_on),
      );
    });
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
                    CheckedPopupMenuItem(
                      value: 'showMap',
                      checked: _showMap,
                      child: const Text('显示地图'),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'showHistory') {
                      _toggleHistory(!_showHistory);
                    } else if (value == 'showRoute') {
                      _toggleRoute(!_showRoute);
                    } else if (value == 'showMap') {
                      _toggleMap(!_showMap);
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
              setState(() {
                selectedMarker = Marker(
                  child: const Icon(Icons.location_on),
                  point: point,
                );
              });
            }),
        mapController: _controller,
        children: [
          if (_showMap)
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
          // if (_showHistory && _histories.isNotEmpty)
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
