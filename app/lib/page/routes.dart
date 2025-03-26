import 'package:app/utils/gpx_parser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:gpx/gpx.dart';
import "package:app/utils/storage.dart";

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

  @override
  void initState() {
    super.initState();
    _loadGpxFiles();
  }

  Future<void> _loadGpxFiles() async {
    final files = await Storage().getGpxFiles();
    setState(() {
      gpxFiles = files;
      _parseGpxFiles();
    });
  }

  void _parseGpxFiles() {
    setState(() {
      polylines = gpxFiles
          .map((file) => parseGpxToPath(file.readAsStringSync()))
          .toList();
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
                  onPressed: _loadGpxFiles,
                ),
              ],
            ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(34.1301578, 108.8277069),
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              PolylineLayer(
                polylines: polylines.isEmpty
                    ? <Polyline>[]
                    : polylines
                        .map((points) => Polyline(
                              points: points,
                              color: Colors.deepOrange,
                              strokeWidth: 5,
                            ))
                        .toList(),
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
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
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
                        child: gpxFiles.isEmpty
                            ? const Center(
                                child: Text('无路书'),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: gpxFiles.length,
                                itemBuilder: (context, index) {
                                  final file = gpxFiles[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(file.path.split('/').last),
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (context) {
                                            return SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.8,
                                              child: RoutePreview(
                                                gpxData:
                                                    file.readAsStringSync(),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
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
          FloatingActionButton.extended(
            onPressed: () async {
              final file = await FilePicker.platform.pickFiles(
                type: FileType.any,
              );
              if (file != null) {
                final path = file.files.single.path!;
                final gpxFile = File(path);
                await Storage().saveGpxFile(
                  path.split('/').last,
                  await gpxFile.readAsBytes(),
                );
                _loadGpxFiles();
              }
            },
            label: const Text('导入'),
            icon: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RouteEditPage(route: 'new_route'),
                ),
              );
            },
            label: const Text('创建'),
            icon: const Icon(Icons.create),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                _isFullScreen = !_isFullScreen;
                widget.onFullScreenToggle?.call(_isFullScreen);
              });
            },
            label: Text(_isFullScreen ? '退出全屏' : '全屏'),
            icon:
                Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
        ],
      ),
    );
  }
}

class RoutePreview extends StatelessWidget {
  final String gpxData;
  const RoutePreview({super.key, required this.gpxData});

  Future<Gpx> _loadGpx(String data) async {
    return GpxReader().fromString(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Route'),
      ),
      body: FutureBuilder<Gpx>(
        future: _loadGpx(gpxData),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading GPX file'));
          } else {
            final gpx = snapshot.data!;
            final points = gpx.trks
                .expand((trk) => trk.trksegs)
                .expand((trkseg) => trkseg.trkpts)
                .map((trkpt) => LatLng(trkpt.lat!, trkpt.lon!))
                .toList();
            final polyline = Polyline(
              points: points,
              color: Colors.blue,
              strokeWidth: 5,
            );
            return Column(
              children: [
                Expanded(
                  flex: 2,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          points.isNotEmpty ? points.first : const LatLng(0, 0),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      PolylineLayer(polylines: [polyline]),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ListView(
                    children: [
                      ListTile(
                        title: Text('Route: $gpxData'),
                      ),
                      ListTile(
                        title: Text(
                            'Length: ${gpx.trks.first.trksegs.first.trkpts.length} points'),
                      ),
                      ListTile(
                        title: Text('Time: ${gpx.metadata?.time}'),
                      ),
                      // 添加更多路书信息
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class RouteEditPage extends StatefulWidget {
  final String route;

  RouteEditPage({required this.route});

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
