import 'dart:convert';

import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

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
