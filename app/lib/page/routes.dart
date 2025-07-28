import 'package:app/component/data.dart';
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
import 'package:provider/provider.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key, this.onFullScreenToggle});
  final ValueChanged<bool>? onFullScreenToggle;

  @override
  State<RoutesPage> createState() => RoutesPageState();
}

class RoutesPageState extends State<RoutesPage> {
  File? _selectedGpxFile;
  Gpx? _previewGpx;
  RangeValues? _routeLengthFilter;
  RangeValues? _distanceToStartFilter;
  RangeValues? _avgSlopeFilter;

  @override
  void initState() {
    super.initState();
  }

  Widget _FilterTag({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        avatar: Icon(icon),
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
    );
  }

  Widget _RangeSliderSheet({
    required String title,
    required double min,
    required double max,
    required RangeValues initial,
  }) {
    RangeValues _currentValues = initial;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          RangeSlider(
            values: _currentValues,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            labels: RangeLabels(
              _currentValues.start.toStringAsFixed(1),
              _currentValues.end.toStringAsFixed(1),
            ),
            onChanged: (values) {
              setState(() {
                _currentValues = values;
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_currentValues);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataLoader = context.watch<DataLoader>(); // 监听 DataLoader 的状态

    return Scaffold(
      appBar: AppBar(title: const Text('Routes')),
      body: Column(
        children: [
          // Filter tags row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8,
              children: [
                _FilterTag(
                  label: _routeLengthFilter != null
                      ? '长度: ${_routeLengthFilter!.start.toStringAsFixed(1)}-${_routeLengthFilter!.end.toStringAsFixed(1)} km'
                      : '长度',
                  icon: Icons.timeline,
                  onTap: () async {
                    final result = await showModalBottomSheet<RangeValues>(
                      context: context,
                      builder: (context) => _RangeSliderSheet(
                        title: '选择路线长度 (km)',
                        min: 0,
                        max: 100,
                        initial:
                            _routeLengthFilter ?? const RangeValues(0, 100),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _routeLengthFilter = result;
                      });
                    }
                  },
                ),
                _FilterTag(
                  label: _distanceToStartFilter != null
                      ? '起点距离: ${_distanceToStartFilter!.start.toStringAsFixed(1)}-${_distanceToStartFilter!.end.toStringAsFixed(1)} km'
                      : '起点距离',
                  icon: Icons.place,
                  onTap: () async {
                    final result = await showModalBottomSheet<RangeValues>(
                      context: context,
                      builder: (context) => _RangeSliderSheet(
                        title: '选择起点距离 (km)',
                        min: 0,
                        max: 50,
                        initial:
                            _distanceToStartFilter ?? const RangeValues(0, 50),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _distanceToStartFilter = result;
                      });
                    }
                  },
                ),
                _FilterTag(
                  label: _avgSlopeFilter != null
                      ? '平均坡度: ${_avgSlopeFilter!.start.toStringAsFixed(1)}%-${_avgSlopeFilter!.end.toStringAsFixed(1)}%'
                      : '平均坡度',
                  icon: Icons.terrain,
                  onTap: () async {
                    final result = await showModalBottomSheet<RangeValues>(
                      context: context,
                      builder: (context) => _RangeSliderSheet(
                        title: '选择平均坡度 (%)',
                        min: 0,
                        max: 30,
                        initial: _avgSlopeFilter ?? const RangeValues(0, 30),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _avgSlopeFilter = result;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          // Title
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: Align(
          //     alignment: Alignment.centerLeft,
          //     child: Text(
          //       'Routes List',
          //       style: TextStyle(
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //         color: Theme.of(context).brightness == Brightness.dark
          //             ? Colors.white
          //             : Colors.black,
          //       ),
          //     ),
          //   ),
          // ),
          Expanded(
            child: dataLoader.gpxData.isEmpty
                ? Center(
                    child: Text(
                      '无路书',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: dataLoader.gpxData.length,
                    itemBuilder: (context, index) {
                      final file = dataLoader.gpxData.entries.toList()[index];
                      return Card(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.white,
                        child: ListTile(
                          title: Text(
                            file.key.split('/').last,
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          onTap: () async {
                            try {
                              final gpxData = file.value;
                              final gpx = GpxReader().fromString(gpxData);
                              final points = gpx.trks
                                  .expand((trk) => trk.trksegs)
                                  .expand((trkseg) => trkseg.trkpts)
                                  .map(
                                      (trkpt) => LatLng(trkpt.lat!, trkpt.lon!))
                                  .toList();
                              setState(() {
                                _selectedGpxFile = File(file.key);
                                _previewGpx = gpx;
                              });
                              // Show as bottom sheet first
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                ),
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    initialChildSize: 0.5,
                                    minChildSize: 0.3,
                                    maxChildSize: 1.0,
                                    expand: false,
                                    builder: (context, scrollController) {
                                      return NotificationListener<
                                          DraggableScrollableNotification>(
                                        onNotification: (notification) {
                                          // If dragged to full screen, push to full page
                                          if (notification.extent >= 0.99) {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    RoutePreviewPage(
                                                  gpx: _previewGpx,
                                                  file: _selectedGpxFile,
                                                  onDelete: () {
                                                    setState(() {
                                                      _selectedGpxFile = null;
                                                      _previewGpx = null;
                                                    });
                                                  },
                                                ),
                                              ),
                                            );
                                          }
                                          return false;
                                        },
                                        child: RoutePreviewContent(
                                          gpx: _previewGpx!,
                                          file: _selectedGpxFile!,
                                          // onDelete: () {
                                          //   setState(() {
                                          //     _selectedGpxData =
                                          //         null;
                                          //     _selectedGpxFile =
                                          //         null;
                                          //     _previewPath = [];
                                          //     _previewGpx = null;
                                          //   });
                                          //   Navigator.of(context)
                                          //       .pop();
                                          // },
                                          // scrollController:
                                          //     scrollController,
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            } catch (e) {
                              if (kDebugMode) {
                                print('Error loading GPX file: $e');
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to load GPX file: $e'),
                                ),
                              );
                              setState(() {
                                _selectedGpxFile = File(file.key);
                                _previewGpx = null;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
              }
            },
            child: const Icon(Icons.file_upload),
          ),
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RouteEditPage(route: 'new_route'),
                ),
              );
            },
            child: const Icon(Icons.create),
          ),
        ],
      ),
    );
  }
}

class RoutePreviewPage extends StatelessWidget {
  final Gpx? gpx;
  final File? file;
  final VoidCallback onDelete;

  const RoutePreviewPage({
    super.key,
    required this.gpx,
    required this.file,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (gpx == null || file == null) {
      return const Center(child: Text('No route selected'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(file!.path.split('/').last),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onDelete();
            },
          ),
        ],
      ),
      body: RoutePreviewContent(gpx: gpx!, file: file!),
    );
  }
}

class RoutePreviewContent extends StatelessWidget {
  final Gpx gpx;
  final File file;

  const RoutePreviewContent({
    super.key,
    required this.gpx,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('GPX File: ${file.path.split('/').last}'),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: gpx.wpts.length,
            itemBuilder: (context, index) {
              final waypoint = gpx.wpts[index];
              return ListTile(
                title: Text('Waypoint ${index + 1}'),
                subtitle: Text('Lat: ${waypoint.lat}, Lng: ${waypoint.lon}'),
              );
            },
          ),
        ),
      ],
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
                urlTemplate:
                    'https://map.iris.al/styles/basic-preview/512/{z}/{x}/{y}.png',
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
                          child: NavPoint(
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
                      child: NavPoint(color: Colors.orange),
                    ),
                  ],
                ),
            ],
          ),
          if (_isSelectingPoint)
            const Center(
              child: NavPoint(color: Colors.red),
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
                        waypoints.length < 3 ? waypoints.length * 52.0 : 156,
                    child: Card(
                      child: ReorderableListView(
                        onReorder: _reorderWaypoints,
                        children: List.generate(waypoints.length, (index) {
                          final point = waypoints[index];
                          return ListTile(
                            key: ValueKey(point),
                            dense: true, // Reduce height of each item
                            title: Text(
                              'Point ${index + 1}'
                              // ': (${point.latitude.toStringAsFixed(2)}, ${point.longitude.toStringAsFixed(2)})'
                              ,
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
