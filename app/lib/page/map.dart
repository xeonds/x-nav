import 'dart:async';

import 'package:app/component/data.dart';
import 'package:app/page/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/utils/data_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.onFullScreenToggle});
  // 一个有bool参数的回调函数
  final ValueChanged<bool>? onFullScreenToggle;

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  late MapController _controller;
  int _showHistory = 0;
  bool _showRoute = false;
  bool _showMap = false;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  Marker selectedMarker = const Marker(
    point: LatLng(34.1301578, 108.8277069),
    child: NavPoint(color: Colors.blue),
  );
  bool _isFullScreen = false;
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _controller = MapController();
  }

  Future<void> _initializeData() async {
    final dataloader = Provider.of<DataLoader>(context, listen: false);
    prefs = await loadPreferences();
    _showHistory = getPreference<int>('showHistory', 0, prefs);
    _showRoute = getPreference<bool>('showRoute', false, prefs);
    _showMap = getPreference<bool>('showMap', false, prefs);
  }

  void _locatePosition() async {
    final location = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(location.latitude, location.longitude);
      _controller.move(_currentPosition, 15);
      selectedMarker = Marker(
        point: _currentPosition,
        child: NavPoint(color: Colors.blue),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataloader = Provider.of<DataLoader>(context, listen: true);
    final routes = dataloader.routes; 
    final histories = dataloader.histories;

    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text('地图页面'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.layers),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) {
                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('地图模式'),
                                  subtitle: Text(
                                    _showHistory == 1
                                        ? '普通地图'
                                        : _showHistory == 2
                                            ? '热力图'
                                            : '隐藏',
                                  ),
                                  trailing: SegmentedButton<int>(
                                    showSelectedIcon: false,
                                    segments: const [
                                      ButtonSegment(
                                        value: 0,
                                        label: Text('隐藏'),
                                      ),
                                      ButtonSegment(
                                        value: 1,
                                        label: Text('普通地图'),
                                      ),
                                      ButtonSegment(
                                        value: 2,
                                        label: Text('热力图'),
                                      ),
                                    ],
                                    selected: {_showHistory},
                                    onSelectionChanged: (newSelection) {
                                      setModalState(() {
                                        _showHistory = newSelection.first;
                                      });
                                      setState(() {
                                        _showHistory = newSelection.first;
                                      });
                                      setPreference<int>(
                                          'showHistory', _showHistory, prefs);
                                    },
                                  ),
                                ),
                                SwitchListTile(
                                  title: const Text('显示路书'),
                                  value: _showRoute,
                                  onChanged: (value) {
                                    setModalState(() {
                                      _showRoute = value;
                                    });
                                    setState(() {
                                      _showRoute = value;
                                    });
                                    setPreference<bool>(
                                        'showRoute', _showRoute, prefs);
                                  },
                                ),
                                SwitchListTile(
                                  title: const Text('显示地图'),
                                  value: _showMap,
                                  onChanged: (value) {
                                    setModalState(() {
                                      _showMap = value;
                                    });
                                    setState(() {
                                      _showMap = value;
                                    });
                                    setPreference<bool>(
                                        'showMap', _showMap, prefs);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
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
                  child: const NavPoint(color: Colors.blue),
                  point: point,
                );
              });
            }),
        mapController: _controller,
        children: [
          if (_showMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              tileProvider: dataloader.tileProvider,
            ),
          if (_showRoute && routes.isNotEmpty)
            PolylineLayer(
              polylines: () {
                final polylines = <Polyline>[];
                for (var route in routes) {
                  polylines.add(Polyline(
                    points: route,
                    color: Colors.deepOrange,
                    strokeWidth: 3,
                  ));
                }
                return polylines;
              }(),
            ),
          if (_showHistory == 1 && histories.isNotEmpty)
            PolylineLayer(
              polylines: () {
                final polylines = <Polyline>[];
                for (var history in histories) {
                  polylines.add(Polyline(
                    points: history,
                    color: Colors.orange,
                    strokeWidth: 3,
                  ));
                }
                return polylines;
              }(),
            ),
          if (_showHistory == 2 && histories.isNotEmpty)
            PolylineLayer(
              polylines: () {
                final polylines = <Polyline>[];
                for (var history in histories) {
                  polylines.add(Polyline(
                    points: history,
                    color: Colors.blue.withOpacity(0.15),
                    strokeWidth: 3,
                  ));
                }
                return polylines;
              }(),
            ),
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
