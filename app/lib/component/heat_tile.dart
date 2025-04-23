import 'dart:ui';

import 'package:app/utils/path_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:latlong2/latlong.dart';

List<LatLng> discretizePath(List<LatLng> path, double intervalMeters) {
  List<LatLng> densePoints = [];
  for (int i = 0; i < path.length - 1; i++) {
    LatLng start = path[i];
    LatLng end = path[i + 1];
    double distance = calculateDistance(start, end);
    int steps = (distance / intervalMeters).ceil();
    for (int j = 0; j <= steps; j++) {
      double ratio = j / steps;
      densePoints.add(LatLng(
        start.latitude + (end.latitude - start.latitude) * ratio,
        start.longitude + (end.longitude - start.longitude) * ratio,
      ));
    }
  }
  return densePoints;
}

// 定义网格结构
class HeatGrid {
  final int x;
  final int y;
  int count = 0;
  HeatGrid(this.x, this.y);
}

// 转换坐标到网格索引
HeatGrid latLngToGrid(LatLng point, MapState map, int gridSize) {
  final pixelPoint = map.project(point);
  int x = (pixelPoint.x / gridSize).floor();
  int y = (pixelPoint.y / gridSize).floor();
  return HeatGrid(x, y);
}

class Point {
  final double x;
  final double y;
  Point(this.x, this.y);
}

class MapState {
  Point project(LatLng point) {
    // 假设这里有一个将LatLng转换为像素坐标的实现
    // 实际实现可能依赖于地图的缩放级别和投影方式
    return Point(point.latitude, point.longitude);
  }
}

// 统计所有路径的热度
Map<String, HeatGrid> buildHeatMap(List<List<LatLng>> allPaths, MapState map) {
  Map<String, HeatGrid> gridMap = {};
  for (var path in allPaths) {
    List<LatLng> densePath = discretizePath(path, 1.0); // 1米间隔插值
    for (var point in densePath) {
      HeatGrid grid = latLngToGrid(point, map, 100); // 100像素网格
      String key = "${grid.x}_${grid.y}";
      gridMap.update(key, (g) {
        g.count++;
        return g;
      }, ifAbsent: () {
        grid.count = 1;
        return grid;
      });
    }
  }
  return gridMap;
}

class PathHeatmapLayer extends Layer {
  final Map<String, HeatGrid> heatGrids;
  final int gridSize;

  PathHeatmapLayer({required this.heatGrids, this.gridSize = 100});

// 修改绘制逻辑，添加模糊效果
  void build(MapState map, Canvas canvas, Size size) {
    final blurRadius = gridSize * 0.5; // 模糊半径与网格尺寸相关
    final blurFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    heatGrids.forEach((key, grid) {
      final left = grid.x * gridSize.toDouble();
      final top = grid.y * gridSize.toDouble();
      final rect =
          Rect.fromLTWH(left, top, gridSize.toDouble(), gridSize.toDouble());
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.red.withOpacity(0.8),
            Colors.red.withOpacity(0.0),
          ],
          stops: [0.0, 1.0],
        ).createShader(rect)
        ..maskFilter = blurFilter;

      canvas.drawCircle(rect.center, gridSize * 0.8, gradientPaint);
    });
  }

  @override
  void addToScene(SceneBuilder builder) {
    final canvas = builder.build();
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    heatGrids.forEach((key, grid) {
      final left = grid.x * gridSize.toDouble();
      final top = grid.y * gridSize.toDouble();
      final rect =
          Rect.fromLTWH(left, top, gridSize.toDouble(), gridSize.toDouble());
    });
  }
}
