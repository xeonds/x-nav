import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_mbtiles/vector_map_tiles_mbtiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/prefs.dart';
import 'package:mbtiles/mbtiles.dart';
import 'dart:convert';

class ReusableMap extends StatefulWidget {
  final MapOptions? mapOptions;
  final MapController? mapController;
  final List<Widget> children;

  const ReusableMap({
    super.key,
    this.mapController,
    this.mapOptions,
    required this.children,
  });

  @override
  State<ReusableMap> createState() => _ReusableMapState();
}

class _ReusableMapState extends State<ReusableMap> {
  int _mapMode = 1;
  String? _selectedMbtiles;
  MbTiles? _mbtilesProvider;

  @override
  void initState() {
    super.initState();
    _mapMode = Prefs.getPreference<int>('mapMode', 1);
    _selectedMbtiles = Prefs.getPreference<String?>('mbtilesFile', null);
    _loadMbtilesFiles();
  }

  Future<void> _loadMbtilesFiles() async {
    final files = await DataLoader.listMbtilesFiles();
    if (_selectedMbtiles == null && files.isNotEmpty) {
      _selectedMbtiles = files.first;
      await Prefs.setPreference<String>('mbtilesFile', _selectedMbtiles!);
    }
    if (_selectedMbtiles != null) {
      final pvd = MbTiles(mbtilesPath: _selectedMbtiles!, gzip: true);
      setState(() {
        _mbtilesProvider = pvd;
      });
    }
  }

  // void _onMapModeChanged(int mode) {
  //   setState(() {
  //     _mapMode = mode;
  //   });
  //   Prefs.setPreference<int>('mapMode', mode);
  //   if (mode == 2 && _selectedMbtiles != null) {
  //     _loadMbtilesFiles();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final mapTheme = vtr.ThemeReader().read(jsonDecode("""
    {
      "version": 8,
      "name": "osm-basic-style",
      "sources": {"openmaptiles": {"type": "vector"}},
      "layers": [
        {"id": "osm-fill", "type": "fill", "source": "openmaptiles", "source-layer": "osm", "filter": ["==", "\$type", "Polygon"], "paint": {"fill-color": "#A0D2FF", "fill-opacity": 0.5}},
        {"id": "osm-line", "type": "line", "source": "openmaptiles", "source-layer": "osm", "filter": ["==", "\$type", "LineString"], "paint": {"line-color": "#0044CC", "line-width": 1.2}},
        {"id": "osm-point", "type": "circle", "source": "openmaptiles", "source-layer": "osm", "filter": ["==", "\$type", "Point"], "paint": {"circle-radius": 4, "circle-color": "#FF5E5E"}}
      ]
    }
    """));
    return Stack(
      children: [
        FlutterMap(
          options: widget.mapOptions ??
              MapOptions(
                initialCenter: const LatLng(34.1301578, 108.8277069),
                initialZoom: 10,
                minZoom: 0,
              ),
          mapController: widget.mapController ?? MapController(),
          children: [
            if (_mapMode == 1)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileProvider: Provider.of<DataLoader>(context).tileProvider,
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
            ...widget.children,
          ],
        ),
      ],
    );
  }
}
