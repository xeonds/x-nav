import 'package:app/utils/path_utils.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:gpx/gpx.dart';
import "package:app/utils/storage.dart";
import 'package:app/utils/data_loader.dart';

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
  List<LatLng> _previewPath = [];
  Gpx? _previewGpx;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await DataLoader().initialize();
    setState(() {
      polylines = DataLoader().routes;
      gpxFiles = DataLoader().gpxData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: const Text('Routes'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await DataLoader().loadRouteData();
                    setState(() {
                      _initializeData();
                    });
                  },
                ),
              ],
            ),
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
              ),
              PolylineLayer(
                polylines: [
                  ...polylines.map((points) => Polyline(
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
                                              final gpxData =
                                                  file.readAsStringSync();
                                              final gpx = GpxReader()
                                                  .fromString(gpxData);
                                              final points = gpx.trks
                                                  .expand((trk) => trk.trksegs)
                                                  .expand(
                                                      (trkseg) => trkseg.trkpts)
                                                  .map((trkpt) => LatLng(
                                                      trkpt.lat!, trkpt.lon!))
                                                  .toList();
                                              _mapController.move(
                                                initCenter(points),
                                                initZoom(points),
                                              );
                                              setState(() {
                                                _selectedGpxData = gpxData;
                                                _previewGpx = gpx;
                                                _previewPath = points;
                                              });
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
                                  if (_selectedGpxData != null) {
                                    final file = gpxFiles.firstWhere(
                                      (f) =>
                                          f.readAsStringSync() ==
                                          _selectedGpxData,
                                      orElse: () => File(''),
                                    );
                                    if (file.existsSync()) {
                                      await file.delete();
                                      setState(() {
                                        _selectedGpxData = null;
                                        _previewPath = [];
                                        _previewGpx = null;
                                      });
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
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 16),
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
  State<RouteEditPage> createState() => _RouteEditPageState();
}

class _RouteEditPageState extends State<RouteEditPage> {
  List<LatLng> waypoints = [];
  List<LatLng> routePath = [];
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text =
        "${waypoints.isNotEmpty ? waypoints.first : '起点'}-${waypoints.isNotEmpty ? waypoints.last : '终点'} 的路线";
  }

  void _addWaypoint(LatLng point) {
    setState(() {
      waypoints.add(point);
      _updateRoute();
    });
  }

  void _removeWaypoint(int index) {
    setState(() {
      waypoints.removeAt(index);
      _updateRoute();
    });
  }

  Future<void> _updateRoute() async {
    // Call your route planning API here with the waypoints
    // For now, we'll just use the waypoints as the route path
    setState(() {
      routePath = List.from(waypoints);
    });
  }

  Future<void> _saveRoute() async {
    final gpx = Gpx();
    gpx.trks = [
      Trk(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Route'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
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
                _saveRoute();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: waypoints.isNotEmpty
                  ? waypoints.first
                  : const LatLng(34.1301578, 108.8277069),
              initialZoom: 14,
              onTap: (tapPosition, point) {
                // Add waypoint at tapped position
                _addWaypoint(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
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
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.2,
            minChildSize: 0.1,
            maxChildSize: 0.5,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: waypoints.length,
                        itemBuilder: (context, index) {
                          final point = waypoints[index];
                          return ListTile(
                            title: Text(
                                'Point ${index + 1}: (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeWaypoint(index),
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        final center = routePath.isNotEmpty
                            ? routePath.last
                            : const LatLng(34.1301578, 108.8277069);
                        _addWaypoint(center);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('新增途径点'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
