import 'dart:math';

import 'package:latlong2/latlong.dart';

// 获取一个路径的几何中心
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

// 获取一个路径的合适缩放比例
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

bool isSubPath(List<LatLng> path, List<LatLng> subPath,
    {double tolerance = 0.0001}) {
  if (subPath.isEmpty || path.isEmpty || subPath.length > path.length) {
    return false;
  }

  final distance = Distance();

  bool matches(int startIndex, List<LatLng> p2) {
    for (int i = 0; i < p2.length; i++) {
      final distanceBetween =
          distance.as(LengthUnit.Meter, path[startIndex + i], p2[i]);
      if (distanceBetween > tolerance) {
        return false;
      }
    }
    return true;
  }

  final reversedSubPath = subPath.reversed.toList();
  for (int i = 0; i <= path.length - subPath.length; i++) {
    if (matches(i, subPath) || matches(i, reversedSubPath)) {
      return true;
    }
  }

  return false;
}
