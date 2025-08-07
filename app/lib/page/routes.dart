import 'package:app/component/data.dart';
import 'package:app/page/routes/edit_route.dart';
import 'package:app/utils/provider.dart' show routesProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class RoutesPage extends ConsumerWidget {
  File? _selectedGpxFile;
  Gpx? _previewGpx;
  RangeValues? _routeLengthFilter;
  RangeValues? _distanceToStartFilter;
  RangeValues? _avgSlopeFilter;

  Widget _FilterTag(
    BuildContext context, {
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

  Widget _RangeSliderSheet(
    BuildContext context, {
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
              _currentValues = values;
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
  Widget build(BuildContext context, WidgetRef ref) {
    final dataLoader = context.watch<DataLoader>(); // 监听 DataLoader 的状态
    final routesState = ref.watch(routesProvider);

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
                  context,
                  label: _routeLengthFilter != null
                      ? '长度: ${_routeLengthFilter!.start.toStringAsFixed(1)}-${_routeLengthFilter!.end.toStringAsFixed(1)} km'
                      : '长度',
                  icon: Icons.timeline,
                  onTap: () async {
                    final result = await showModalBottomSheet<RangeValues>(
                      context: context,
                      builder: (context) => _RangeSliderSheet(
                        context,
                        title: '选择路线长度 (km)',
                        min: 0,
                        max: 100,
                        initial:
                            _routeLengthFilter ?? const RangeValues(0, 100),
                      ),
                    );
                    if (result != null) {
                      _routeLengthFilter = result;
                    }
                  },
                ),
                _FilterTag(
                  context,
                  label: _distanceToStartFilter != null
                      ? '起点距离: ${_distanceToStartFilter!.start.toStringAsFixed(1)}-${_distanceToStartFilter!.end.toStringAsFixed(1)} km'
                      : '起点距离',
                  icon: Icons.place,
                  onTap: () async {
                    final result = await showModalBottomSheet<RangeValues>(
                      context: context,
                      builder: (context) => _RangeSliderSheet(
                        context,
                        title: '选择起点距离 (km)',
                        min: 0,
                        max: 50,
                        initial:
                            _distanceToStartFilter ?? const RangeValues(0, 50),
                      ),
                    );
                    if (result != null) {
                      _distanceToStartFilter = result;
                    }
                  },
                ),
                _FilterTag(
                  context,
                  label: _avgSlopeFilter != null
                      ? '平均坡度: ${_avgSlopeFilter!.start.toStringAsFixed(1)}%-${_avgSlopeFilter!.end.toStringAsFixed(1)}%'
                      : '平均坡度',
                  icon: Icons.terrain,
                  onTap: () async {
                    final result = await showModalBottomSheet<RangeValues>(
                      context: context,
                      builder: (context) => _RangeSliderSheet(
                        context,
                        title: '选择平均坡度 (%)',
                        min: 0,
                        max: 30,
                        initial: _avgSlopeFilter ?? const RangeValues(0, 30),
                      ),
                    );
                    if (result != null) {
                      _avgSlopeFilter = result;
                    }
                  },
                ),
              ],
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Routes List',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: routesState.when(
              data: (data) => data.isEmpty
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
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final file = data[index];
                        return Card(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.white,
                          child: ListTile(
                            title: Text(
                              file.filePath.split('/').last,
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            onTap: () async {
                              try {
                                final gpxData = file.data;
                                final gpx = GpxReader().fromString(gpxData);
                                final points = file.route;
                                _selectedGpxFile = File(file.filePath);
                                _previewGpx = gpx;
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
                                                      _selectedGpxFile = null;
                                                      _previewGpx = null;
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
                                    content:
                                        Text('Failed to load GPX file: $e'),
                                  ),
                                );
                                _selectedGpxFile = File(file.filePath);
                                _previewGpx = null;
                              }
                            },
                          ),
                        );
                      },
                    ),
              error: (err, stack) =>
                  const Center(child: Text('No route selected')),
              loading: () => const Center(child: CircularProgressIndicator()),
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
                  builder: (context) => RouteEditPage(route: 'new_route'),
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
