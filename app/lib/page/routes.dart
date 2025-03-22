import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:gpx/gpx.dart'; // 添加 gpx 解析库
import "package:app/utils/storage.dart";

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => RoutesPageState();
}

class RoutesPageState extends State<RoutesPage> {
  List<File> gpxFiles = [];
  Set<Polyline> polylines = {};

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(0, 0),
                initialZoom: 2,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                PolylineLayer(
                  polylines: polylines.toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
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
        title: Text('Preview Route'),
      ),
      body: FutureBuilder<Gpx>(
        future: _loadGpx('/home/xeonds/code/x-nav/appdir/route/$route'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading GPX file'));
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
                          points.isNotEmpty ? points.first : LatLng(0, 0),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
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
        title: Text('Edit Route'),
      ),
      body: Center(
        child: Text('Editing $route'),
      ),
    );
  }
}
