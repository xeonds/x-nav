import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpx/gpx.dart'; // 添加 gpx 解析库

class RoutesPage extends StatefulWidget {
  @override
  _RoutesPageState createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  List<String> routes = [];

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/route');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final files = directory
        .listSync()
        .where((item) => item.path.endsWith('.gpx'))
        .toList();
    setState(() {
      routes = files.map((file) => file.path.split('/').last).toList();
    });
  }

  Future<void> _importRoute() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      File file = File(result.files.single.path!);
      final root = await getApplicationDocumentsDirectory();
      final directory = Directory('${root.path}/route');
      final newFile =
          await file.copy('${directory.path}/${file.uri.pathSegments.last}');
      setState(() {
        routes.add(newFile.path.split('/').last);
      });
    }
  }

  Future<void> _exportRoute(String route) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/route');
    final file = File('${directory.path}/$route');
    final newFile = await file.copy('${directory.path}/$route');
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route exported to ${newFile.path}')));
  }

  void _previewRoute(String route) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RoutePreviewPage(route: route)));
  }

  void _editRoute(String route) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => RouteEditPage(route: route)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Routes'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _importRoute,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(routes[index]),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_red_eye),
                  onPressed: () => _previewRoute(routes[index]),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editRoute(routes[index]),
                ),
                IconButton(
                  icon: Icon(Icons.file_download),
                  onPressed: () => _exportRoute(routes[index]),
                ),
              ],
            ),
          );
        },
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
              polylineId: PolylineId('route'),
              points: points,
              color: Colors.blue,
              width: 5,
            );
            return Column(
              children: [
                Expanded(
                  flex: 2,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: points.isNotEmpty ? points.first : LatLng(0, 0),
                      zoom: 14,
                    ),
                    polylines: {polyline},
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
