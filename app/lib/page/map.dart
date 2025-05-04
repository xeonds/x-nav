import 'package:app/component/data.dart';
import 'package:app/page/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mbtiles/mbtiles.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/utils/data_loader.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

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
  int _mapMode = 1; // 0: 关闭, 1: 在线, 2: 离线
  List<String> _mbtilesFiles = [];
  String? _selectedMbtiles;
  LatLng _currentPosition = const LatLng(37.7749, -122.4194);
  Marker selectedMarker = const Marker(
    point: LatLng(34.1301578, 108.8277069),
    child: NavPoint(color: Colors.blue),
  );
  bool _isFullScreen = false;
  MbTiles? _mbtilesProvider;

  @override
  void initState() {
    super.initState();
    _showHistory = getPreference<int>('showHistory', 0);
    _showRoute = getPreference<bool>('showRoute', false);
    _mapMode = getPreference<int>('mapMode', 1);
    _controller = MapController();
    _loadMbtilesFiles();
  }

  Future<void> _loadMbtilesFiles() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'mbtiles'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mbtiles'))
        .map((f) => f.path)
        .toList();
    setState(() {
      _mbtilesFiles = files;
      final pref = getPreference<String?>(
          'mbtilesFile', files.isNotEmpty ? files.first : null);
      _selectedMbtiles = pref;
    });
    if (_selectedMbtiles != null) {
      final pvd = MbTiles(mbtilesPath: _selectedMbtiles!, gzip: false);
      setState(() {
        _mbtilesProvider = pvd;
      });
    }
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
    final dataLoader = context.watch<DataLoader>();
    final routes = dataLoader.routes;
    final histories = dataLoader.histories;
    final _theme = vtr.ProvidedThemes.lightTheme();

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
                                          'showHistory', _showHistory);
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
                                        'showRoute', _showRoute);
                                  },
                                ),
                                ListTile(
                                  title: const Text('地图模式'),
                                  subtitle: Text(
                                    _mapMode == 0
                                        ? '关闭'
                                        : _mapMode == 1
                                            ? '在线地图'
                                            : '离线地图',
                                  ),
                                  trailing: SegmentedButton<int>(
                                    showSelectedIcon: false,
                                    segments: const [
                                      ButtonSegment(
                                          value: 0, label: Text('关闭')),
                                      ButtonSegment(
                                          value: 1, label: Text('在线')),
                                      ButtonSegment(
                                          value: 2, label: Text('离线')),
                                    ],
                                    selected: {_mapMode},
                                    onSelectionChanged: (sel) {
                                      final mode = sel.first;
                                      setModalState(() {
                                        _mapMode = mode;
                                      });
                                      setState(() {
                                        _mapMode = mode;
                                      });
                                      setPreference<int>('mapMode', _mapMode);
                                      if (_mapMode == 2 &&
                                          _selectedMbtiles != null) {
                                        _loadMbtilesFiles();
                                      }
                                    },
                                  ),
                                ),
                                if (_mapMode == 2)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: _selectedMbtiles,
                                      hint: const Text('选择离线 MBTiles'),
                                      items: _mbtilesFiles.map((path) {
                                        return DropdownMenuItem(
                                          value: path,
                                          child: Text(p.basename(path)),
                                        );
                                      }).toList(),
                                      onChanged: (v) {
                                        setModalState(() {
                                          _selectedMbtiles = v;
                                        });
                                        setState(() {
                                          _selectedMbtiles = v;
                                        });
                                        if (v != null) {
                                          setPreference<String>(
                                              'mbtilesFile', v);
                                          final mbt =
                                              MbTiles(
                                                  mbtilesPath: v, gzip: false);
                                          setState(() {
                                            _mbtilesProvider = mbt;
                                          });
                                        }
                                      },
                                    ),
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
          // onTap: (tapPosition, point) {
          //   setState(() {
          //     selectedMarker = Marker(
          //       child: const NavPoint(color: Colors.blue),
          //       point: point,
          //     );
          //   });
          // },
        ),
        mapController: _controller,
        children: [
          if (_mapMode == 1)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              tileProvider: dataLoader.tileProvider,
            ),
          if (_mapMode == 2 && _mbtilesProvider != null)
            // TileLayer(
            //   tileProvider: _mbtilesProvider!,
            // ),
            VectorTileLayer(
              theme: _theme,
                tileProviders: TileProviders({
                    'openmaptiles': MbTilesVectorTileProvider(
                        mbtiles: _mbtilesProvider!,
                    ),
                }),
                maximumZoom: 18,
            ),
          PolylineLayer(
            polylines: [
              if (_showRoute && routes.isNotEmpty)
                ...dataLoader.routes.map((points) => Polyline(
                      points: points,
                      color: Colors.deepOrange,
                      strokeWidth: 3,
                    )),
              if (_showHistory == 1 && histories.isNotEmpty)
                ...dataLoader.histories.map((points) => Polyline(
                      points: points,
                      color: Colors.deepOrange,
                      strokeWidth: 3,
                    )),
              if (_showHistory == 2 && histories.isNotEmpty)
                ...dataLoader.histories.map((points) => Polyline(
                      points: points,
                      color: Colors.deepPurple.withOpacity(0.15),
                      strokeWidth: 3,
                    ))
            ],
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

  @override
  void dispose() {
    _mbtilesProvider?.dispose();
    super.dispose();
  }
}
