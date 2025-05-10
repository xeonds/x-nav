import 'dart:async';

import 'package:app/component/data.dart';
import 'package:app/page/tachometer.dart';
import 'package:app/page/user.dart';
import 'package:app/utils/mvt_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'
    show PolylinePoints;
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
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/utils/path_utils.dart';

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
  LatLng _currentPosition = LatLng(34.1301578, 108.8277069);
  Marker? _destMarker; // 导航目标标记
  StreamSubscription<Position>? _locateSub; // 持续定位订阅
  Marker selectedMarker = const Marker(
    point: LatLng(34.1301578, 108.8277069),
    child: NavPoint(color: Colors.blue),
  );
  bool _isFullScreen = false;
  MbTiles? _mbtilesProvider;
  bool _isRecording = false; // 路径录制状态
  String _nextInstruction = ''; // 下一步导航提示
  bool _showElevationChart = false; // 是否在导航卡片中显示海拔图
  List<double> _elevationData = []; // 海拔数据
  // List<double> _slopeData = []; // 坡度百分比数据
  List<double> _distanceData = []; // 路径长度数据
  List<LatLng> _recordedPath = []; // 记录中的轨迹
  List<LatLng> _navRoute = [];
  StreamSubscription<Position>? _positionSub;
  List<SegmentMatch> _segmentMatches = [];
  List<int> _matchedSegmentIds = [];
  int _historicalBestDuration = 0; // 官方赛段历史最佳用时（秒）
  int? _activeSegmentId; // 当前正在骑行的赛段索引
  DateTime? _activeEntryTime; // 进入赛段时间
  int _currentSegmentElapsed = 0; // 实时段内已用秒数
  String? _segmentResultMessage; // 赛段完成消息

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
    });
  }

  void _onMapTap(LatLng dest) async {
    setState(() {
      _showElevationChart = false;
      _destMarker = Marker(point: dest, child: NavPoint(color: Colors.red));
      _nextInstruction = '计算路径中...';
    });
    // 获取最新位置信息
    // final pos = await Geolocator.getCurrentPosition();
    final coordinates = [_currentPosition, dest]
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final url =
        'http://router.project-osrm.org/route/v1/bike/$coordinates?overview=full&geometries=polyline';
    final response = await http.get(Uri.parse(url));
    late final List<LatLng> decodedPolyline;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];
      final polyline = route['geometry'];
      decodedPolyline = PolylinePoints()
          .decodePolyline(polyline)
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      setState(() {
        _nextInstruction = "路径规划失败";
      });
      decodedPolyline = [];
    }
    setState(() {
      // _currentPosition = LatLng(pos.latitude, pos.longitude);
      // _controller.move(_currentPosition, _controller.camera.zoom);
      // selectedMarker = Marker(point: dest, child: NavPoint(color: Colors.red));
      _navRoute.clear();
    });
    final route = [...decodedPolyline];
    // 计算距离
    final distances = [0.0];
    latlngToDistance(decodedPolyline);
    for (var i = 0, dist = 0.0; i < decodedPolyline.length - 1; i++) {
      dist += latlngPointDistance(decodedPolyline[i], decodedPolyline[i + 1]);
      distances.add(dist);
    }
    setState(() {
      _navRoute = route;
      _distanceData = distances;
      _nextInstruction = '剩余 ${(distances.last / 1000).toStringAsFixed(2)} km';
    });
    await _fetchElevationData(route);
    setState(() => _showElevationChart = true);
  }

  // 切换持续定位
  void _toggleContinuousLocate() {
    if (_locateSub == null)
      _startContinuousLocate();
    else
      _stopContinuousLocate();
  }

  void _startContinuousLocate() {
    final locSettings =
        LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2);
    _locateSub = Geolocator.getPositionStream(locationSettings: locSettings)
        .listen((pos) {
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPosition = point);
      _updateNavigationProgress(pos);
      _updateSegmentStatus(pos);
    });
  }

  void _stopContinuousLocate() {
    _locateSub?.cancel();
    _locateSub = null;
  }

  /// 实时更新导航进度：截取最近点至目标或重算路线
  void _updateNavigationProgress(Position pos) {
    if (_destMarker == null || _navRoute.isEmpty) return;
    final point = LatLng(pos.latitude, pos.longitude);
    // 找到最近路线上点
    double minD = double.infinity;
    int idx = 0;
    for (int i = 0; i < _navRoute.length; i++) {
      final d = Geolocator.distanceBetween(point.latitude, point.longitude,
          _navRoute[i].latitude, _navRoute[i].longitude);
      if (d < minD) {
        minD = d;
        idx = i;
      }
    }
    // 偏差大于阈值，重算路径
    if (minD > 50) {
      _onMapTap(_destMarker!.point);
    } else {
      // 裁剪路段
      final newRoute = _navRoute.sublist(idx);
      setState(() {
        _navRoute = newRoute;
        _distanceData = _distanceData.sublist(idx);
        _nextInstruction =
            '剩余 ${(latlngToDistance(newRoute) / 1000).toStringAsFixed(2)} km';
      });
    }
  }

  Future<void> _fetchElevationData(List<LatLng> route) async {
    final locations =
        route.map((p) => '${p.latitude},${p.longitude}').join('|');
    final url =
        'https://api.open-elevation.com/api/v1/lookup?locations=$locations';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final results = data['results'] as List;
        _elevationData =
            results.map((e) => (e['elevation'] as num).toDouble()).toList();
        // 计算坡度百分比
        // _slopeData = [];
        // for (var i = 1; i < _elevationData.length; i++) {
        //   final dAlt = _elevationData[i] - _elevationData[i - 1];
        //   final dDist = (_distanceData[i] - _distanceData[i - 1]);
        //   _slopeData.add(dDist > 0 ? (dAlt / dDist * 100) : 0);
        // }
      }
    } catch (e) {
      debugPrint('Elevation fetch error: $e');
    }
  }

  void _startRecording() {
    final locSettings =
        LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5);
    _positionSub = Geolocator.getPositionStream(locationSettings: locSettings)
        .listen((pos) {
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _recordedPath.add(point));
      _updateSegmentStatus(pos);
      _detectSegments();
    });
  }

  void _updateSegmentStatus(Position pos) {
    final loader = DataLoader();
    if (!loader.isInitialized) return;
    final now = DateTime.now();
    final point = LatLng(pos.latitude, pos.longitude);
    final distUtil = Distance();
    if (_activeSegmentId == null) {
      for (var i = 0; i < loader.routes.length; i++) {
        final segStart = loader.routes[i].first;
        if (distUtil.as(LengthUnit.Meter, point, segStart) < 30) {
          _activeSegmentId = i;
          _activeEntryTime = now;
          _historicalBestDuration = loader.bestSegment[i]?.dataList
                  .map((s) => s.item.duration)
                  .reduce((a, b) => a < b ? a : b)
                  .toInt() ??
              0;
          setState(() => _currentSegmentElapsed = 0);
          return;
        }
      }
    } else {
      final idx = _activeSegmentId!;
      final segPoints = loader.routes[idx];
      final segEnd = segPoints.last;
      final diffToEnd = distUtil.as(LengthUnit.Meter, point, segEnd);
      // 在赛段中
      if (diffToEnd > 30) {
        final elapsed = now.difference(_activeEntryTime!).inSeconds;
        setState(() => _currentSegmentElapsed = elapsed);
      } else {
        // 赛段完成
        final elapsed = now.difference(_activeEntryTime!).inSeconds;
        final best = _historicalBestDuration;
        final diff = elapsed - best;
        setState(() {
          _segmentResultMessage =
              '赛段${idx + 1}完成：用时${elapsed}s，历史最佳${best}s，${diff >= 0 ? '落后' : '领先'}${diff.abs()}s';
          _activeSegmentId = null;
        });
        // 自动隐藏结果卡片
        Future.delayed(Duration(seconds: 5),
            () => setState(() => _segmentResultMessage = null));
      }
    }
  }

  void _detectSegments() {
    final loader = DataLoader();
    if (!loader.isInitialized) return;
    final segments = loader.routes;
    final matches = SegmentMatcher().findSegments([_currentPosition], segments);
    setState(() {
      _segmentMatches = matches;
    });
  }

  Future<void> _stopRecording() async {
    await _positionSub?.cancel();
    // 保存到 JSON 文件
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'recordings',
        'track_${DateTime.now().millisecondsSinceEpoch}.json'));
    await file.parent.create(recursive: true);
    final data = _recordedPath
        .map((p) => {
              'lat': p.latitude,
              'lng': p.longitude,
              'time': DateTime.now().toIso8601String()
            })
        .toList();
    await file.writeAsString(JsonEncoder().convert(data));
  }

  @override
  Widget build(BuildContext context) {
    final dataLoader = context.watch<DataLoader>();
    final routes = dataLoader.routes;
    final histories = dataLoader.histories;
    final mapTheme = vtr.ThemeReader().read(lightStyle());

    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text('地图页面'),
              actions: [
                // IconButton(
                //     onPressed: () {
                //       Navigator.of(context).push(
                //         MaterialPageRoute(
                //           builder: (context) => TachometerPage(),
                //         ),
                //       );
                //     },
                //     icon: const Icon(Icons.navigation)),
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
                                const SizedBox(
                                  height: 20,
                                ),
                                buildListSubtitle('地图控制'),
                                ListTile(
                                  title: const Text('历史活动'),
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
                                          final mbt = MbTiles(
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
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(34.1301578, 108.8277069),
              initialZoom: 10,
              onTap: (tapPos, point) => _onMapTap(point),
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
                  theme: mapTheme,
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
                          color: Colors.deepPurple.withValues(alpha: 0.15),
                          strokeWidth: 3,
                        )),
                  if (_navRoute.isNotEmpty)
                    Polyline(
                        points: _navRoute, color: Colors.blue, strokeWidth: 4),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                      point: _currentPosition,
                      child: NavPoint(color: Colors.blue)),
                  if (_destMarker != null) _destMarker!,
                ],
              ),
            ],
          ),
          // 导航提示卡片（含海拔折线图）
          if (_nextInstruction.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                // color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_nextInstruction, style: TextStyle(fontSize: 16)),
                      if (_showElevationChart && _elevationData.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: LineChart(
                            LineChartData(
                              titlesData: FlTitlesData(
                                show: false,
                              ),
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                      _distanceData.length,
                                      (i) => FlSpot(
                                          _distanceData[i],
                                          i < _elevationData.length
                                              ? _elevationData[i]
                                              : 0)),
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  dotData: FlDotData(show: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // 录制中指示
          // 赛段匹配卡片
          if (_segmentMatches.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: Column(
                children: _segmentMatches.map((sm) {
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    color: Colors.orange.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '进入赛段 ${sm.segmentIndex + 1}，匹配度 ${(sm.matchPercentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          // 实时赛段卡片
          if (_activeSegmentId != null)
            Positioned(
              top: 140,
              left: 16,
              right: 16,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                color: Colors.green.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '赛段${_activeSegmentId! + 1}进行中：${_currentSegmentElapsed}s，' +
                        '历史最佳${_historicalBestDuration}s，' +
                        '差${(_currentSegmentElapsed - _historicalBestDuration).abs()}s',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          // 赛段完成卡片
          if (_segmentResultMessage != null)
            Positioned(
              top: 200,
              left: 16,
              right: 16,
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                color: Colors.blue.withOpacity(0.9),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _segmentResultMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isRecording)
            Chip(
              label: Text('Recording'),
              avatar: Icon(Icons.fiber_manual_record, color: Colors.red),
            ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'record',
            onPressed: () {
              setState(() {
                _isRecording = !_isRecording;
                if (_isRecording) {
                  _recordedPath.clear();
                  _startRecording();
                } else {
                  _stopRecording();
                }
              });
            },
            child: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mbtilesProvider?.dispose();
    super.dispose();
  }
}
