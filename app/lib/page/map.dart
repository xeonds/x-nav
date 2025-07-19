import 'dart:async';
import 'dart:math';

import 'package:app/component/data.dart';
import 'package:app/page/routes.dart';
import 'package:app/page/user.dart';
import 'package:app/utils/fit.dart' show parseFitDataToRoute;
import 'package:app/utils/location_provier.dart';
import 'package:app/utils/mvt_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
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
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/utils/path_utils.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  // 工具箱相关状态
  bool isMeasureOpen = false; // 地图测算开关
  bool isLocationShareOpen = false; // 位置共享开关
  bool isCruiseModeOpen = false; // 巡航模式开关
  bool isGapChaseOpen = false; // 秒差距追踪开关
  PageController? _cardPageController;

  // 界面组件显示控制
  int _showHistory = 0; // 地图骑行记录显示模式
  int _mapMode = 1; // 地图贴片模式: 0: 关闭, 1: 在线, 2: 离线
  bool _showRoute = false; // 展示路书

  // LatLng _currentPosition = LatLng(34.1301578, 108.8277069);
  Marker? _destMarker; // 导航目标标记
  Marker selectedMarker = const Marker(
    point: LatLng(34.1301578, 108.8277069),
    child: NavPoint(color: Colors.blue),
  );

  // 离线地图模块
  List<String> _mbtilesFiles = [];
  String? _selectedMbtiles;
  MbTiles? _mbtilesProvider;

  // 导航模块
  bool _isRecording = false; // 路径录制状态
  String _nextInstruction = ''; // 下一步导航提示
  List<LatLng> _recordedPath = []; // 记录中的轨迹
  List<LatLng> _navRoute = [];

  // 实时赛段功能
  List<SegmentMatch> _segmentMatches = [];
  List<int> _matchedSegmentIds = [];
  int _currentSegmentElapsed = 0; // 实时段内已用秒数
  String? _segmentResultMessage; // 赛段完成消息
  int _historicalBestDuration = 0; // 官方赛段历史最佳用时（秒）
  int? _activeSegmentId; // 当前正在骑行的赛段索引
  DateTime? _activeEntryTime; // 进入赛段时间

  // 测算功能相关状态
  List<LatLng> measurePoints = []; // 测量的点
  List<LatLng> measureRoute = []; // 测量路径
  List<double> _elevationData = []; // 海拔数据
  List<double> _slopeData = []; // 坡度百分比数据
  List<double> _distanceData = []; // 路径长度数据

  // 地图位置和控制流
  final MapController _mapController = MapController();
  final StreamController<double?> _followStream =
      StreamController<double?>.broadcast();

  @override
  void dispose() {
    _followStream.close();
    _mbtilesProvider?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _showHistory = getPreference<int>('showHistory', 0);
    _showRoute = getPreference<bool>('showRoute', false);
    _mapMode = getPreference<int>('mapMode', 1);
    _loadMbtilesFiles();
    _cardPageController = PageController();
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
      final pvd = MbTiles(mbtilesPath: _selectedMbtiles!, gzip: true);
      setState(() {
        _mbtilesProvider = pvd;
      });
    }
  }

  void _locatePosition() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    _followStream.add(null); // 通知 CurrentLocationLayer 居中
    locationProvider.fetchCurrentLocation(); // 主动刷新位置（可选）
  }

  // 地图点击事件
  void _onMapTap(LatLng dest) async {
    if (isMeasureOpen) {
      // 单点测算
      measurePoints = [dest];
      measureRoute = [];
      _fetchElevationData([dest]).then((_) {
        setState(() {});
      });
      setState(() {});
      return;
    }
    setState(() {
      _destMarker = Marker(point: dest, child: NavPoint(color: Colors.red));
    });
  }

  // 测算路径绘制相关
  bool _isDrawingMeasureRoute = false;

  void _onMapLongPressStart(LongPressStartDetails details, LatLng point) {
    if (!isMeasureOpen) return;
    // 开始绘制路径
    setState(() {
      _isDrawingMeasureRoute = true;
      measureRoute = [point];
      measurePoints = [];
      _elevationData = [];
      _distanceData = [];
    });
  }

  void _onMapLongPressMoveUpdate(
      LongPressMoveUpdateDetails details, LatLng point) {
    if (!isMeasureOpen || !_isDrawingMeasureRoute) return;
    setState(() {
      // 距离上一个点超过一定距离才添加，避免点太密
      if (measureRoute.isEmpty ||
          Geolocator.distanceBetween(
                measureRoute.last.latitude,
                measureRoute.last.longitude,
                point.latitude,
                point.longitude,
              ) >
              10) {
        measureRoute.add(point);
      }
    });
  }

  void _onMapLongPressEnd(LongPressEndDetails details, LatLng point) {
    if (!isMeasureOpen || !_isDrawingMeasureRoute) return;
    setState(() {
      _isDrawingMeasureRoute = false;
      // 结束后补上最后一个点
      if (measureRoute.isEmpty ||
          Geolocator.distanceBetween(
                measureRoute.last.latitude,
                measureRoute.last.longitude,
                point.latitude,
                point.longitude,
              ) >
              10) {
        measureRoute.add(point);
      }
    });
    // 采样海拔并计算距离
    _fetchElevationData(measureRoute).then((_) {
      // 计算距离数据
      double accDist = 0.0;
      _distanceData = List.generate(measureRoute.length, (i) {
        if (i == 0) return 0.0;
        accDist += Geolocator.distanceBetween(
          measureRoute[i - 1].latitude,
          measureRoute[i - 1].longitude,
          measureRoute[i].latitude,
          measureRoute[i].longitude,
        );
        return accDist;
      });
      setState(() {});
    });
  }

  // 退出测算或切换测算类型时清空路径
  void _clearMeasureRoute() {
    setState(() {
      measureRoute = [];
      measurePoints = [];
      _elevationData = [];
      _distanceData = [];
    });
  }

  // 路径规划
  Future<List<LatLng>> routePlan(LatLng dest) async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final pos = locationProvider.currentPosition;
    final coordinates = [
      LatLng(pos?.latitude ?? 34.1301578, pos?.longitude ?? 108.8277069),
      dest,
    ].map((point) => '${point.longitude},${point.latitude}').join(';');
    final url =
        'http://router.project-osrm.org/route/v1/bike/$coordinates?overview=full&geometries=polyline';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];
      final polyline = route['geometry'];
      return PolylinePoints()
          .decodePolyline(polyline)
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    } else {
      return [];
    }
  }

  // 计算距离
  double getMeasureDistance() {
    final res = latlngToDistance(measureRoute);
    return res;
  }

  // // 切换持续定位
  // void _toggleContinuousLocate() {
  //   if (_locateSub == null)
  //     _startContinuousLocate();
  //   else
  //     _stopContinuousLocate();
  // }

  // void _startContinuousLocate() {
  //   final locSettings =
  //       LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 2);
  //   _locateSub = Geolocator.getPositionStream(locationSettings: locSettings)
  //       .listen((pos) {
  //     final point = LatLng(pos.latitude, pos.longitude);
  //     setState(() => _currentPosition = point);
  //     _updateNavigationProgress(pos);
  //     _updateSegmentStatus(pos);
  //   });
  // }

  // void _stopContinuousLocate() {
  //   _locateSub?.cancel();
  //   _locateSub = null;
  // }

  // 实时更新导航进度：截取最近点至目标或重算路线
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

  // 计算海拔高度，稀疏采样：当点太多时均匀间隔采样64点
  Future<void> _fetchElevationData(List<LatLng> route) async {
    List<LatLng> sampledRoute;
    if (route.length > 64) {
      sampledRoute = List.generate(
        64,
        (i) => route[((route.length - 1) * i ~/ 63)],
      );
    } else {
      sampledRoute = route;
    }
    final locations =
        sampledRoute.map((p) => '${p.latitude},${p.longitude}').join('|');
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

  // TODO:需要重写，数据写入.fit中
  void _startRecording() {
    // final locSettings =
    //     LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 5);
    // _positionSub = Geolocator.getPositionStream(locationSettings: locSettings)
    //     .listen((pos) {
    //   final point = LatLng(pos.latitude, pos.longitude);
    //   setState(() => _recordedPath.add(point));
    //   _updateSegmentStatus(pos);
    //   // _detectSegments();
    // });
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

  // void _detectSegments() {
  //   final loader = DataLoader();
  //   if (!loader.isInitialized) return;
  //   final segments = loader.routes;
  //   final matches = SegmentMatcher().findSegments([_currentPosition], segments);
  //   setState(() {
  //     _segmentMatches = matches;
  //   });
  // }

  // 需要重写，文件写入fit
  Future<void> _stopRecording() async {
    // await _positionSub?.cancel();
    // // 保存到 JSON 文件
    // final dir = await getApplicationDocumentsDirectory();
    // final file = File(p.join(dir.path, 'recordings',
    //     'track_${DateTime.now().millisecondsSinceEpoch}.json'));
    // await file.parent.create(recursive: true);
    // final data = _recordedPath
    //     .map((p) => {
    //           'lat': p.latitude,
    //           'lng': p.longitude,
    //           'time': DateTime.now().toIso8601String()
    //         })
    //     .toList();
    // await file.writeAsString(JsonEncoder().convert(data));
  }

  // filter exist routes
  void filterRoute() {
    context.read<DataLoader>();
    double minLength = 0, maxLength = 100.0;
    double minStartDist = 0, maxStartDist = 20.0;
    double minSlope = -10, maxSlope = 20;

    RangeValues lengthRange = RangeValues(minLength, maxLength);
    RangeValues startDistRange = RangeValues(minStartDist, maxStartDist);
    RangeValues slopeRange = RangeValues(minSlope, maxSlope);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('筛选路线',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('路线长度(km)'),
                      Expanded(
                        child: RangeSlider(
                          min: minLength,
                          max: maxLength,
                          divisions: 20,
                          values: lengthRange,
                          labels: RangeLabels(
                            lengthRange.start.toStringAsFixed(1),
                            lengthRange.end.toStringAsFixed(1),
                          ),
                          onChanged: (v) {
                            setModalState(() => lengthRange = v);
                          },
                        ),
                      ),
                      Text(
                          '${lengthRange.start.toStringAsFixed(1)}~${lengthRange.end.toStringAsFixed(1)}'),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('起点距当前位置(km)'),
                      Expanded(
                        child: RangeSlider(
                          min: minStartDist,
                          max: maxStartDist,
                          divisions: 20,
                          values: startDistRange,
                          labels: RangeLabels(
                            startDistRange.start.toStringAsFixed(1),
                            startDistRange.end.toStringAsFixed(1),
                          ),
                          onChanged: (v) {
                            setModalState(() => startDistRange = v);
                          },
                        ),
                      ),
                      Text(
                          '${startDistRange.start.toStringAsFixed(1)}~${startDistRange.end.toStringAsFixed(1)}'),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('平均坡度(%)'),
                      Expanded(
                        child: RangeSlider(
                          min: minSlope,
                          max: maxSlope,
                          divisions: 30,
                          values: slopeRange,
                          labels: RangeLabels(
                            slopeRange.start.toStringAsFixed(1),
                            slopeRange.end.toStringAsFixed(1),
                          ),
                          onChanged: (v) {
                            setModalState(() => slopeRange = v);
                          },
                        ),
                      ),
                      Text(
                          '${slopeRange.start.toStringAsFixed(1)}~${slopeRange.end.toStringAsFixed(1)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // 这里可以实现筛选逻辑并刷新地图上的路线
                      Navigator.pop(context);
                    },
                    child: const Text('应用筛选'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataLoader = context.watch<DataLoader>();
    final routes = dataLoader.routes;
    final histories = dataLoader.histories;

    bool isDrawingRoute = isMeasureOpen && _isDrawingMeasureRoute;
    return Scaffold(
      body: Stack(
        children: [
          Listener(
            // onPointerDown: (event) {
            //   if (isDrawingRoute) {
            //     // 开始绘制测算路径
            //     _onMapLongPressStart(
            //       LongPressStartDetails(
            //         globalPosition: event.position,
            //         localPosition: event.localPosition,
            //       ),
            //       _mapController.camera.center,
            //     );
            //   } else {
            //     // 普通点击事件
            //     final localPos = event.localPosition;
            //     _onMapTap(_mapController.camera
            //         .pointToLatLng(Point(localPos.dx, localPos.dy)));
            //   }
            // },
            onPointerUp: (event) {
              if (isDrawingRoute) {
                // 结束绘制测算路径
                _onMapLongPressEnd(
                  LongPressEndDetails(
                    globalPosition: event.position,
                    localPosition: event.localPosition,
                  ),
                  _mapController.camera.center,
                );
              }
            },
            onPointerMove: (event) {
              if (_isDrawingMeasureRoute) {
                setState(() {
                  measureRoute.add(
                    _mapController.camera.center,
                  );
                });
              }
            },
            child: FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(34.1301578, 108.8277069),
                initialZoom: 12,
                minZoom: 0,
                onTap: isDrawingRoute
                    ? (tapPos, point) {
                        setState(() {
                          measureRoute.add(point);
                        });
                      }
                    : (tapPos, point) => _onMapTap(point),
              ),
              mapController: _mapController,
              children: [
                if (_mapMode == 1)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    tileProvider: dataLoader.tileProvider,
                  ),
                if (_mapMode == 2 && _mbtilesProvider != null)
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
                      ...(dataLoader.routes).map((points) => Polyline(
                            points: points,
                            color: Colors.deepOrange,
                            strokeWidth: 3,
                          )),
                    if (_showHistory == 1 && histories.isNotEmpty)
                      ...(dataLoader.histories)
                          .map((e) => parseFitDataToRoute(e))
                          .map((points) => Polyline(
                                points: points,
                                color: Colors.deepOrange,
                                strokeWidth: 3,
                              )),
                    if (_showHistory == 2 && histories.isNotEmpty)
                      ...(dataLoader.histories)
                          .map((e) => parseFitDataToRoute(e))
                          .map((List<LatLng> points) => Polyline(
                                points: points,
                                color: Colors.deepPurple.withOpacity(0.15),
                                strokeWidth: 3,
                              )),
                    if (_navRoute.isNotEmpty)
                      Polyline(
                          points: _navRoute,
                          color: Colors.blue,
                          strokeWidth: 4),
                    // 测算路径实时显示
                    if (measureRoute.length > 1)
                      Polyline(
                        points: measureRoute,
                        color: Colors.blueAccent,
                        strokeWidth: 4,
                      ),
                  ],
                ),
                MarkerLayer(markers: [
                  if (isMeasureOpen &&
                      measurePoints.isNotEmpty &&
                      measurePoints.length == 1)
                    Marker(
                        point: measurePoints.first,
                        child: const Icon(Icons.location_on,
                            color: Colors.blue, size: 22),
                        alignment: Alignment.topCenter),
                ]),
                CurrentLocationLayer(
                  positionStream:
                      Provider.of<LocationProvider>(context).positionStream,
                  alignPositionStream: _followStream.stream,
                  alignPositionOnUpdate: AlignOnUpdate.never,
                  alignDirectionOnUpdate: AlignOnUpdate.never,
                  moveAnimationDuration: Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
          Positioned(
            top: 32,
            left: 16,
            child: FloatingActionButton(
              onPressed: filterRoute,
              mini: true,
              child: Icon(Icons.filter_alt),
            ),
          ),
          Positioned(
            top: 32,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RoutesPage(),
                  ),
                );
              },
              mini: true,
              child: Icon(Icons.alt_route),
            ),
          ),
          // 卡片和FAB区域
          Builder(
            builder: (context) {
              // 构建卡片列表
              final List<Widget> cards = [
                if (isMeasureOpen) _buildMeasureCard(),
                if (isLocationShareOpen) _buildLocationShareCard(),
                if (_navRoute.isNotEmpty) _buildRouteCard(),
              ];
              final bool hasCards = cards.isNotEmpty;
              // FAB列
              final fabColumn = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        showMapLayerControllerPopup(context);
                      },
                      mini: true,
                      child: const Icon(Icons.layers),
                    ),
                    const SizedBox(height: 4),
                    FloatingActionButton(
                      onPressed: () {
                        showToolboxPopup(context);
                      },
                      mini: true,
                      child: const Icon(Icons.build),
                    ),
                    const SizedBox(height: 4),
                    FloatingActionButton(
                      onPressed: _locatePosition,
                      mini: true,
                      child: const Icon(Icons.my_location),
                    ),
                    // 测算模式下仅显示“创建路书”按钮和完成按钮
                    if (isMeasureOpen) ...[
                      const SizedBox(height: 4),
                      FloatingActionButton(
                        heroTag: 'drawRoute',
                        mini: true,
                        child: Icon(
                            _isDrawingMeasureRoute ? Icons.done : Icons.create),
                        onPressed: () {
                          setState(() {
                            if (_isDrawingMeasureRoute) {
                              // 完成绘制，触发测算
                              _isDrawingMeasureRoute = false;
                              _fetchElevationData(measureRoute).then((_) {
                                // 计算距离数据
                                _distanceData =
                                    List.generate(measureRoute.length, (i) {
                                  if (i == 0) return 0.0;
                                  return _distanceData[i - 1] +
                                      Geolocator.distanceBetween(
                                        measureRoute[i - 1].latitude,
                                        measureRoute[i - 1].longitude,
                                        measureRoute[i].latitude,
                                        measureRoute[i].longitude,
                                      );
                                });
                                setState(() {});
                              });
                            } else {
                              // 开始绘制
                              _isDrawingMeasureRoute = true;
                              measureRoute = [];
                              _elevationData = [];
                              _distanceData = [];
                            }
                          });
                        },
                      ),
                    ],
                  ]);
              if (!hasCards) {
                return Positioned(
                  right: 16,
                  bottom: 16,
                  child: fabColumn,
                );
              } else {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 16, top: 8, bottom: 8),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: fabColumn,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          color: Colors.transparent,
                          child: SizedBox(
                            height: 144,
                            child: PageView(
                              controller: _cardPageController,
                              onPageChanged: (idx) {},
                              children: cards,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<dynamic> showToolboxPopup(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                buildListSubtitle('工具'),
                SwitchListTile(
                  title: const Text('地图测算'),
                  value: isMeasureOpen,
                  onChanged: (v) {
                    setModalState(() => isMeasureOpen = v);
                    setState(() => isMeasureOpen = v);
                  },
                ),
                SwitchListTile(
                  title: const Text('位置共享'),
                  value: isLocationShareOpen,
                  onChanged: (v) {
                    setModalState(() => isLocationShareOpen = v);
                    setState(() => isLocationShareOpen = v);
                  },
                ),
                SwitchListTile(
                  title: const Text('巡航模式'),
                  value: isCruiseModeOpen,
                  onChanged: (v) {
                    setModalState(() => isCruiseModeOpen = v);
                    setState(() => isCruiseModeOpen = v);
                  },
                ),
                ListTile(
                  title: Text(_isRecording ? '结束路径记录' : '开始路径记录'),
                  onTap: () async {
                    if (_isRecording) {
                      await _stopRecording();
                    } else {
                      _startRecording();
                    }
                    setModalState(() {});
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('秒差距追踪'),
                  value: isGapChaseOpen,
                  onChanged: (v) {
                    setModalState(() => isGapChaseOpen = v);
                    setState(() => isGapChaseOpen = v);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 卡片构建方法 ---
  Widget _buildMeasureCard() {
    final isPoint = measurePoints.length == 1 && measureRoute.isEmpty;
    final isRoute = measureRoute.length > 1;
    String info = '';
    Widget? chart;
    List<Widget> extraWidgets = [];
    final currentPosition =
        Provider.of<LocationProvider>(context).currentPosition;

    if (isPoint) {
      final pt = measurePoints.first;
      final elev = _elevationData.isNotEmpty
          ? _elevationData.first.toStringAsFixed(1)
          : '--';
      final dist = Geolocator.distanceBetween(
        currentPosition?.latitude ?? 34.1301578,
        currentPosition?.longitude ?? 108.8277069,
        pt.latitude,
        pt.longitude,
      );
      info =
          '经纬度: ${pt.latitude.toStringAsFixed(6)}, ${pt.longitude.toStringAsFixed(6)}\n'
          '海拔: $elev m\n'
          '距当前位置: ${(dist / 1000).toStringAsFixed(2)} km';
      extraWidgets.add(Icon(Icons.place, color: Colors.blue, size: 32));
    } else if (isRoute) {
      final totalDist = getMeasureDistance();
      final elevGain = _elevationData.isNotEmpty
          ? (_elevationData.last - _elevationData.first).toStringAsFixed(1)
          : '--';
      // 路径起点到当前位置的直线距离
      double startToCurrent = 0.0;
      if (measureRoute.isNotEmpty && currentPosition != null) {
        startToCurrent = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          measureRoute.first.latitude,
          measureRoute.first.longitude,
        );
      }
      info = '路径点数: ${measureRoute.length}\n'
          '总长度: ${(totalDist / 1000).toStringAsFixed(2)} km\n'
          '海拔变化: $elevGain m\n'
          '起点到当前位置: ${(startToCurrent / 1000).toStringAsFixed(2)} km';
      if (_elevationData.length > 1 && _distanceData.length > 1) {
        print(_distanceData.length);
        chart = SizedBox(
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(show: false),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    _elevationData.length,
                    (i) => FlSpot(i.toDouble(), _elevationData[i]),
                  ),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        );
      }
      extraWidgets.add(Icon(Icons.timeline, color: Colors.orange, size: 32));
    } else {
      info = '请在地图上点击或长按拖动';
      extraWidgets.add(Icon(Icons.info_outline, color: Colors.grey, size: 32));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...extraWidgets,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('地图测算', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  // 更直观的测算结果展示
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPoint) ...[
                            Row(
                              children: [
                                Icon(Icons.place, color: Colors.blue, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '经纬度: ${measurePoints.first.latitude.toStringAsFixed(6)}, ${measurePoints.first.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.height,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '海拔: ${_elevationData.isNotEmpty ? _elevationData.first.toStringAsFixed(1) : '--'} m',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.social_distance,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '距当前位置: ${(Geolocator.distanceBetween(
                                        currentPosition?.latitude ?? 34.1301578,
                                        currentPosition?.longitude ??
                                            108.8277069,
                                        measurePoints.first.latitude,
                                        measurePoints.first.longitude,
                                      ) / 1000).toStringAsFixed(2)} km',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ] else if (isRoute) ...[
                            Row(
                              children: [
                                Icon(Icons.timeline,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '路径点数: ${measureRoute.length}',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.route, color: Colors.blue, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '总长度: ${(getMeasureDistance() / 1000).toStringAsFixed(2)} km',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.height,
                                    color: Colors.orange, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '海拔变化: ${_elevationData.isNotEmpty ? (_elevationData.last - _elevationData.first).toStringAsFixed(1) : '--'} m',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '请在地图上点击或长按拖动',
                                    style: TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            if (chart != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 80,
                    height: 50,
                    child: chart,
                  ),
                ],
              ),
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('分享测算信息'),
                    content: SelectableText(info),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('关闭'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationShareCard() {
    // TODO: 实现位置共享卡片内容
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('位置共享', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('API Key/在线人数/服务状态'),
                ],
              ),
            ),
            Icon(Icons.people, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard() {
    // 保留原有路线卡片内容
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initCenter(_navRoute),
                initialZoom: initZoom(_navRoute),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: context.read<DataLoader>().tileProvider,
                ),
                if (_navRoute.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _navRoute,
                        color: Colors.blue,
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                if (_navRoute.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _navRoute.first,
                        child: Icon(Icons.circle, color: Colors.green, size: 8),
                      ),
                      Marker(
                        point: _navRoute.last,
                        child: Icon(Icons.flag, color: Colors.red, size: 10),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "长度: \\${(_distanceData.isNotEmpty ? _distanceData.last / 1000 : 0).toStringAsFixed(2)} km",
                      style: TextStyle(color: Colors.green, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    if (_elevationData.length > 1 && _distanceData.length > 1)
                      Builder(builder: (context) {
                        final totalDist =
                            _distanceData.last > 0 ? _distanceData.last : 1;
                        final totalElev =
                            _elevationData.last - _elevationData.first;
                        final slope = (totalElev / totalDist * 100)
                            .clamp(-99, 99)
                            .toStringAsFixed(1);
                        return Text(
                          "坡度: \\$slope%",
                          style: TextStyle(color: Colors.orange, fontSize: 13),
                        );
                      }),
                  ],
                ),
                if (_elevationData.length > 1 && _distanceData.length > 1)
                  SizedBox(
                    height: 18,
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(show: false),
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
                                      : 0),
                            ),
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 2,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  _nextInstruction,
                  style: TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.navigation, color: Colors.blue),
            onPressed: null,
            tooltip: "导航中",
          ),
        ],
      ),
    );
  }

  Future<dynamic> showMapLayerControllerPopup(BuildContext context) {
    return showModalBottomSheet(
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
                      setPreference<int>('showHistory', _showHistory);
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
                    setPreference<bool>('showRoute', _showRoute);
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
                      ButtonSegment(value: 0, label: Text('关闭')),
                      ButtonSegment(value: 1, label: Text('在线')),
                      ButtonSegment(value: 2, label: Text('离线')),
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
                      if (_mapMode == 2 && _selectedMbtiles != null) {
                        _loadMbtilesFiles();
                      }
                    },
                  ),
                ),
                if (_mapMode == 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          setPreference<String>('mbtilesFile', v);
                          final mbt = MbTiles(mbtilesPath: v, gzip: false);
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
  }
}
