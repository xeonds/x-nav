import 'package:app/utils/path_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:gpx/gpx.dart';
import "package:app/utils/storage.dart";
import 'package:app/utils/data_loader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key, this.onFullScreenToggle});
  final ValueChanged<bool>? onFullScreenToggle;

  @override
  State<RoutesPage> createState() => RoutesPageState();
}

class RoutesPageState extends State<RoutesPage> {
  List<File> gpxFiles = [];
  List<List<LatLng>> polylines = [];
  bool _isFullScreen = false;
  String? _selectedGpxData;
  File? _selectedGpxFile = null;
  List<LatLng> _previewPath = [];
  Gpx? _previewGpx;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final dataloader = Provider.of<DataLoader>(context, listen: false);
    while (!dataloader.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    setState(() {
      polylines = dataloader.routes;
      gpxFiles = dataloader.gpxData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataLoader = context.watch<DataLoader>(); // 监听 DataLoader 的状态

    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(title: const Text('Routes')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(34.1301578, 108.8277069),
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                tileProvider: dataLoader.tileProvider,
              ),
              PolylineLayer(
                polylines: [
                  ...dataLoader.routes.map((points) => Polyline(
                        points: points,
                        color: Colors.deepOrange,
                        strokeWidth: 5,
                      )),
                  if (_previewPath.isNotEmpty)
                    Polyline(
                      points: _previewPath,
                      color: Colors.blue,
                      strokeWidth: 5,
                    ),
                ],
              ),
            ],
          ),
          if (!_isFullScreen)
            DraggableScrollableSheet(
              initialChildSize: 0.2,
              minChildSize: 0.2,
              maxChildSize: 1.0,
              shouldCloseOnMinExtent: true,
              snap: true,
              snapSizes: const [0.2, 0.5, 1.0],
              builder:
                  (BuildContext context, ScrollController scrollController) {
                final isDarkMode = MediaQuery.of(context).platformBrightness ==
                    Brightness.dark;
                return Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: _selectedGpxData == null
                      ? CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Routes List',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            gpxFiles.isEmpty
                                ? SliverFillRemaining(
                                    child: Center(
                                      child: Text(
                                        '无路书',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final file = gpxFiles[index];
                                        return Card(
                                          color: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.white,
                                          child: ListTile(
                                            title: Text(
                                              file.path.split('/').last,
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            onTap: () async {
                                              try {
                                                final gpxData =
                                                    file.readAsStringSync();
                                                final gpx = GpxReader()
                                                    .fromString(gpxData);
                                                final points = gpx.trks
                                                    .expand(
                                                        (trk) => trk.trksegs)
                                                    .expand((trkseg) =>
                                                        trkseg.trkpts)
                                                    .map((trkpt) => LatLng(
                                                        trkpt.lat!, trkpt.lon!))
                                                    .toList();
                                                _mapController.move(
                                                  initCenter(points),
                                                  initZoom(points),
                                                );
                                                setState(() {
                                                  _selectedGpxData = gpxData;
                                                  _selectedGpxFile = file;
                                                  _previewGpx = gpx;
                                                  _previewPath = points;
                                                });
                                              } catch (e) {
                                                if (kDebugMode) {
                                                  print(
                                                      'Error loading GPX file: $e');
                                                }
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Failed to load GPX file: $e'),
                                                  ),
                                                );
                                                setState(() {
                                                  _selectedGpxData = "";
                                                  _selectedGpxFile = file;
                                                  _previewPath = [];
                                                  _previewGpx = null;
                                                });
                                              }
                                            },
                                          ),
                                        );
                                      },
                                      childCount: gpxFiles.length,
                                    ),
                                  ),
                          ],
                        )
                      : Column(
                          children: [
                            ListTile(
                              leading: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () {
                                  setState(() {
                                    _selectedGpxData = null;
                                    _selectedGpxFile = null;
                                    _previewPath = [];
                                    _previewGpx = null;
                                  });
                                },
                              ),
                              title: Text(
                                'Preview Route',
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  if (_selectedGpxFile != null) {
                                    if (_selectedGpxFile!.existsSync()) {
                                      await _selectedGpxFile!.delete();
                                      setState(() {
                                        _selectedGpxData = null;
                                        _selectedGpxFile = null;
                                        _previewPath = [];
                                        _previewGpx = null;
                                      });
                                      await DataLoader().loadRouteData();
                                      _initializeData();
                                    }
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                controller: scrollController,
                                children: [
                                  if (_previewGpx != null)
                                    ListTile(
                                      title: Text(
                                        'Length: ${_previewGpx!.trks.first.trksegs.first.trkpts.length} points',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  if (_previewGpx?.metadata?.time != null)
                                    ListTile(
                                      title: Text(
                                        'Time: ${_previewGpx!.metadata!.time}',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  // 添加更多路书信息
                                ],
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_selectedGpxFile == null)
            FloatingActionButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  allowMultiple: true,
                );
                if (result != null) {
                  for (final file in result.files) {
                    final path = file.path!;
                    final gpxFile = File(path);
                    await Storage().saveGpxFile(
                      path.split('/').last,
                      await gpxFile.readAsBytes(),
                    );
                  }
                  _initializeData();
                }
              },
              child: const Icon(Icons.file_upload),
            ),
          if (_selectedGpxFile == null) const SizedBox(height: 16),
          if (_selectedGpxFile == null)
            FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const RouteEditPage(route: 'new_route'),
                  ),
                );
              },
              child: const Icon(Icons.create),
            ),
          if (_selectedGpxFile != null)
            // export gpx file
            FloatingActionButton(
              onPressed: () async {
                if (_selectedGpxFile != null) {
                  final file = _selectedGpxFile!;
                  try {
                    await Share.shareXFiles(
                        [XFile(file.path, mimeType: 'application/gpx+xml')],
                        text: 'Sharing GPX file');
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error sharing GPX file: $e');
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to share GPX file: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Icon(Icons.output),
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

class RouteEditPage extends StatefulWidget {
  final String route;

  const RouteEditPage({super.key, required this.route});

  @override
  State<RouteEditPage> createState() => RouteEditPageState();
}

class RouteEditPageState extends State<RouteEditPage> {
  List<LatLng> waypoints = [];
  Map<LatLng, bool> isCustomPointMap = {}; // 辅助Map，标记点是否为自定义点
  List<LatLng> routePath = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectingPoint = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final MapController _mapController = MapController();
  LatLng? _centerPoint; // 地图中心点
  LatLng? _selectedWaypoint; // 当前选中的途径点
  bool _isMovingPoint = false; // 是否正在移动点

  @override
  void initState() {
    super.initState();
    _titleController.text =
        "${waypoints.isNotEmpty ? waypoints.first : '起点'}-${waypoints.isNotEmpty ? waypoints.last : '终点'} 的路线";
  }

  Future<void> _updateRoute() async {
    List<LatLng> combinedPath = [];
    if (waypoints.isNotEmpty) {
      combinedPath.add(waypoints.first);
    }

    // Traverse waypoints to process intervals and points
    int i = 0;
    while (i < waypoints.length) {
      if (isCustomPointMap[waypoints[i]] != true) {
        // Start of a potential false interval
        int start = i;
        while (i + 1 < waypoints.length &&
            isCustomPointMap[waypoints[i + 1]] != true) {
          i++;
        }
        // Fetch route for the interval if length > 1
        if (i > start) {
          final coordinates = waypoints
              .sublist(start, i + 1)
              .map((point) => '${point.longitude},${point.latitude}')
              .join(';');
          final url =
              'http://router.project-osrm.org/route/v1/bike/$coordinates?overview=full&geometries=polyline';
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final route = data['routes'][0];
            final polyline = route['geometry'];
            final decodedPolyline = PolylinePoints().decodePolyline(polyline);
            combinedPath.addAll(decodedPolyline
                .map((point) => LatLng(point.latitude, point.longitude)));
          } else {
            if (kDebugMode) {
              print('Failed to fetch route: ${response.statusCode}');
            }
          }
        } else {
          // Single non-custom point
          combinedPath.add(waypoints[start]);
        }
      } else {
        // Custom point, append directly
        combinedPath.add(waypoints[i]);
      }
      i++; // Move to the next point
    }

    setState(() {
      routePath = combinedPath;
    });
  }

  void _addWaypoint(LatLng point, {bool isCustom = false}) {
    setState(() {
      waypoints.add(point);
      isCustomPointMap[point] = isCustom;
      _updateRoute();
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      final point = waypoints.removeAt(index);
      isCustomPointMap.remove(point);
      _updateRoute();
    });
  }

  void _reorderWaypoints(int oldIndex, int newIndex) {
    setState(() {
      final point = waypoints.removeAt(oldIndex);
      waypoints.insert(newIndex, point);
      _updateRoute();
    });
  }

  Future<void> _searchLocation(String query) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=$query&format=json';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final results = json.decode(response.body) as List;
      setState(() {
        _searchResults = results
            .map((result) => {
                  'name': result['display_name'],
                  'lat': double.parse(result['lat']),
                  'lon': double.parse(result['lon']),
                })
            .toList();
      });
    }
  }

  // TODO: add more metadata for gpx and solve save error
  Future<void> _saveRoute() async {
    final gpx = Gpx();
    // gpx.metadata = Metadata(
    //   name: _titleController.text,
    //   desc: 'Route created with ${waypoints.length} waypoints',
    //   time: DateTime.now(),
    // );

    // Calculate total distance
    gpx.trks = [
      Trk(
        // name: _titleController.text,
        // desc: 'Total distance: ${totalDistance.toStringAsFixed(2)} meters',
        trksegs: [
          Trkseg(
            trkpts: routePath
                .map((point) => Wpt(lat: point.latitude, lon: point.longitude))
                .toList(),
          ),
        ],
      ),
    ];
    final gpxString = GpxWriter().asString(gpx);
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.gpx";
    await Storage().saveGpxFile(fileName, gpxString.codeUnits);
    Navigator.of(context).pop();
  }

  void _locatePosition() async {
    final location = await Geolocator.getCurrentPosition();
    setState(() {
      _mapController.move(
        LatLng(location.latitude, location.longitude),
        15,
      );
    });
  }

  void _startMovingPoint(LatLng point) {
    setState(() {
      _selectedWaypoint = point;
      _isMovingPoint = true;
    });
  }

  void _confirmMovingPoint() {
    if (_selectedWaypoint != null && _centerPoint != null) {
      setState(() {
        final index = waypoints.indexOf(_selectedWaypoint!);
        if (index != -1) {
          waypoints[index] = _centerPoint!;
          isCustomPointMap[_centerPoint!] =
              isCustomPointMap[_selectedWaypoint!]!;
          isCustomPointMap.remove(_selectedWaypoint!);
          _updateRoute();
        }
        _selectedWaypoint = null;
        _isMovingPoint = false;
        _centerPoint = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataLoader = context.watch<DataLoader>();
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: waypoints.isNotEmpty
                  ? waypoints.first
                  : const LatLng(34.1301578, 108.8277069),
              initialZoom: 14,
              onMapEvent: (event) {
                if (_isSelectingPoint || _isMovingPoint) {
                  setState(() {
                    _centerPoint = event.camera.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                tileProvider: dataLoader.tileProvider,
              ),
              if (routePath.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePath,
                      color: Colors.blue,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: waypoints
                    .map((point) => Marker(
                          point: point,
                          child: Icon(
                            Icons.location_on,
                            color: isCustomPointMap[point] == true
                                ? Colors.green
                                : Colors.red,
                          ),
                        ))
                    .toList(),
              ),
              if (_isMovingPoint && _centerPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _centerPoint!,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.orange,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_isSelectingPoint)
            const Center(
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          Positioned(
            top: 32,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (_isSearching)
                  Card(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchResults.clear();
                            });
                          },
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () =>
                              _searchLocation(_searchController.text),
                        ),
                        hintText: 'Search location',
                      ),
                    ),
                  ),
                if (_searchResults.isNotEmpty)
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(result['name']),
                          onTap: () {
                            _mapController.move(
                              LatLng(result['lat'], result['lon']),
                              14,
                            );
                            setState(() {
                              _centerPoint =
                                  LatLng(result['lat'], result['lon']);
                              _isSelectingPoint = true;
                              // Clear search results & stop searching
                              _searchResults.clear();
                              _isSearching = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (!_isSearching)
                  SizedBox(
                    height:
                        waypoints.length < 3 ? waypoints.length * 52.0 : 150,
                    child: Card(
                      child: ReorderableListView(
                        onReorder: _reorderWaypoints,
                        children: List.generate(waypoints.length, (index) {
                          final point = waypoints[index];
                          return ListTile(
                            key: ValueKey(point),
                            dense: true, // Reduce height of each item
                            title: Text(
                              'Point ${index + 1}: (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.drag_handle, size: 18),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _startMovingPoint(point),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () => _removeWaypoint(index),
                                ),
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _mapController.move(point, 14);
                                _isSelectingPoint = false;
                              });
                            },
                          );
                        }),
                      ),
                    ),
                  ),
                if (!_isSearching)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_location),
                        label: const Text('Add Point'),
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSelectingPoint = true;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                      ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isSelectingPoint)
            FloatingActionButton.extended(
              onPressed: () {
                if (_centerPoint != null) {
                  _addWaypoint(_centerPoint!);
                  setState(() {
                    _isSelectingPoint = false;
                    _centerPoint = null;
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Nav Point'),
            ),
          if (_isSelectingPoint) const SizedBox(height: 16),
          if (_isSelectingPoint)
            FloatingActionButton.extended(
              onPressed: () {
                if (_centerPoint != null) {
                  _addWaypoint(_centerPoint!, isCustom: true);
                  setState(() {
                    _isSelectingPoint = false;
                    _centerPoint = null;
                  });
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Point'),
            ),
          if (_isSelectingPoint) const SizedBox(height: 16),
          if (_isSelectingPoint)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isSelectingPoint = false;
                  _centerPoint = null;
                });
              },
              child: const Icon(Icons.close),
            ),
          if (_isSelectingPoint) const SizedBox(height: 16),
          if (_isMovingPoint)
            FloatingActionButton.extended(
              onPressed: _confirmMovingPoint,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Move'),
            ),
          if (_isMovingPoint) const SizedBox(height: 16),
          if (_isMovingPoint)
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isMovingPoint = false;
                  _selectedWaypoint = null;
                  _centerPoint = null;
                });
              },
              child: const Icon(Icons.close),
            ),
          if (_isMovingPoint) const SizedBox(height: 16),
          // locate button
          FloatingActionButton(
            onPressed: _locatePosition,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          // save button
          FloatingActionButton(
            child: const Icon(Icons.save),
            onPressed: () async {
              final title = await showDialog<String>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Save Route'),
                    content: TextField(
                      controller: _titleController,
                      decoration:
                          const InputDecoration(labelText: 'Route Title'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_titleController.text),
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );
              if (title != null) {
                await _saveRoute();
              }
            },
          )
        ],
      ),
    );
  }
}
