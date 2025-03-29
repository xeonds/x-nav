import 'dart:math';

import 'package:latlong2/latlong.dart';

LatLng initCenter(List<LatLng> routePoints) {
  if (routePoints.isEmpty) {
    return const LatLng(0, 0);
  }
  final minLat =
      routePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
  final maxLat =
      routePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
  final minLng =
      routePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
  final maxLng =
      routePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
  return LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
}

double initZoom(List<LatLng> routePoints) {
  if (routePoints.isEmpty) {
    return 13.0;
  }
  final minLat =
      routePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
  final maxLat =
      routePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
  final minLng =
      routePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
  final maxLng =
      routePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

  const worldWidth = 360.0; // Longitude range
  const worldHeight = 180.0; // Latitude range

  final lngZoom = (log(worldWidth / (maxLng - minLng)) / log(2));
  final latZoom = (log(worldHeight / (maxLat - minLat)) / log(2));

  return ((lngZoom < latZoom ? lngZoom : latZoom) + 0.5);
}
