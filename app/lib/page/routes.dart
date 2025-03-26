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
    // 解析gpx文件并生成polylines
    // 这里需要添加具体的解析逻辑
    setState(() {
      polylines = gpxFiles.map((file) {
        final gpx = File(file.path); // 从文件中读取gpx数据
        final gpxData = gpx.readAsStringSync();
        return parseGpxToPath(gpxData);
      }).toList();
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
              initialChildSize: 0.1,
              minChildSize: 0.1,
              maxChildSize: 1.0,
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
                                        // 点击后的反应之后再说
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
        children: [
          FloatingActionButton(
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
            child: const Icon(Icons.add),
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

class RoutePreviewPage extends StatelessWidget {
  final String route;

  RoutePreviewPage({required this.route});

  Future<Gpx> _loadGpx(String path) async {
    final file = File(path);
    final xmlString = await file.readAsString();
    return GpxReader().fromString(xmlString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Route'),
      ),
      body: FutureBuilder<Gpx>(
        future: _loadGpx('/home/xeonds/code/x-nav/appdir/route/$route'),
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
                        title: Text('Route: $route'),
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

class RouteEditPage extends StatelessWidget {
  final String route;

  RouteEditPage({required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Route'),
      ),
      body: Center(
        child: Text('Editing $route'),
      ),
    );
  }
}
