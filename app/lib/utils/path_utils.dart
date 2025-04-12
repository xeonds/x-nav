import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

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

class SegmentMatch {
  final List<LatLng> segmentPoints;
  final int startIndex; // 骑行记录中匹配到赛段的起始点索引
  final int endIndex; // 骑行记录中匹配到赛段的结束点索引
  final double matchPercentage; // 匹配度百分比

  SegmentMatch(
      this.segmentPoints, this.startIndex, this.endIndex, this.matchPercentage);
}

class SegmentMatcher {
  /// 用于确定两个坐标点是否匹配的距离阈值（单位：米）
  final double distanceThreshold;

  /// 赛段匹配的最小百分比阈值，低于此值不视为匹配
  final double minMatchPercentage;

  /// 距离计算器
  final Distance distance = const Distance();

  SegmentMatcher({
    this.distanceThreshold = 30.0, // 默认30米
    this.minMatchPercentage = 0.8, // 默认80%匹配度
  });

  /// 检查骑行记录是否包含指定的赛段
  /// 返回所有匹配的赛段及其在骑行记录中的位置
  List<SegmentMatch> findSegments(
      List<LatLng> ridePoints, List<List<LatLng>> allSegments) {
    List<SegmentMatch> matches = [];

    for (List<LatLng> segment in allSegments) {
      // 赛段过短（少于2个点）则跳过
      if (segment.length < 2) continue;

      // 寻找此赛段在骑行记录中的匹配
      SegmentMatch? match = matchSegment(ridePoints, segment);
      if (match != null) {
        matches.add(match);
      }
    }

    return matches;
  }

  /// 匹配单个赛段
  SegmentMatch? matchSegment(
      List<LatLng> ridePoints, List<LatLng> segmentPoints) {
    // 赛段起点在骑行记录中的可能位置
    List<int> possibleStartIndices = [];

    // 先找到所有可能的起点
    for (int i = 0; i < ridePoints.length; i++) {
      if (isPointMatch(ridePoints[i], segmentPoints[0])) {
        possibleStartIndices.add(i);
      }
    }

    SegmentMatch? bestMatch;
    double bestMatchPercentage = 0;

    // 对每个可能的起点进行完整匹配检查
    for (int startIndex in possibleStartIndices) {
      int matchedPoints = 1; // 起点已匹配
      int currentRideIndex = startIndex + 1;
      int segmentIndex = 1;

      // 特殊情况：如果赛段只有一个点
      if (segmentPoints.length == 1) {
        return SegmentMatch(segmentPoints, startIndex, startIndex, 1.0);
      }

      // 从起点后开始匹配剩余点
      while (segmentIndex < segmentPoints.length &&
          currentRideIndex < ridePoints.length) {
        // 检查当前骑行点是否匹配当前赛段点
        if (isPointMatch(
            ridePoints[currentRideIndex], segmentPoints[segmentIndex])) {
          matchedPoints++;
          segmentIndex++;
        }

        currentRideIndex++;
      }

      // 计算匹配百分比
      double matchPercentage = matchedPoints / segmentPoints.length;

      // 更新最佳匹配
      if (matchPercentage > bestMatchPercentage) {
        bestMatchPercentage = matchPercentage;
        bestMatch = SegmentMatch(segmentPoints, startIndex,
            startIndex + (currentRideIndex - startIndex - 1), matchPercentage);
      }
    }

    // 如果匹配度达到阈值，返回匹配结果
    if (bestMatch != null && bestMatch.matchPercentage >= minMatchPercentage) {
      return bestMatch;
    }

    return null;
  }

  /// 使用改进的路径匹配算法（基于动态规划思想）
  SegmentMatch? matchSegmentImproved(
      List<LatLng> ridePoints, List<LatLng> segmentPoints) {
    if (ridePoints.isEmpty || segmentPoints.isEmpty) return null;

    // 使用动态规划的方法查找最佳匹配路径
    int m = ridePoints.length;
    int n = segmentPoints.length;

    // 创建一个矩阵来记录每个骑行点与赛段点的距离
    List<List<double>> distanceMatrix =
        List.generate(m, (_) => List.filled(n, double.infinity));

    // 填充距离矩阵
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < n; j++) {
        distanceMatrix[i][j] =
            distance.as(LengthUnit.Meter, ridePoints[i], segmentPoints[j]);
      }
    }

    // 用于回溯的最佳匹配路径
    List<List<int>> bestPath = List.generate(m, (_) => List.filled(n, -1));

    // 动态规划求解
    int startIdx = -1;
    int endIdx = -1;
    double bestScore = double.negativeInfinity;

    for (int i = 0; i < m; i++) {
      if (distanceMatrix[i][0] <= distanceThreshold) {
        // 可能的起点
        int currentRideIdx = i;
        int currentSegmentIdx = 0;
        int matchedPoints = 1;

        while (currentRideIdx < m - 1 && currentSegmentIdx < n - 1) {
          currentRideIdx++;
          // 寻找下一个最佳匹配点
          double minDist = double.infinity;
          int bestNextSegmentIdx = -1;

          for (int j = currentSegmentIdx;
              j < min(currentSegmentIdx + 5, n);
              j++) {
            if (distanceMatrix[currentRideIdx][j] < minDist &&
                distanceMatrix[currentRideIdx][j] <= distanceThreshold) {
              minDist = distanceMatrix[currentRideIdx][j];
              bestNextSegmentIdx = j;
            }
          }

          if (bestNextSegmentIdx != -1) {
            currentSegmentIdx = bestNextSegmentIdx;
            matchedPoints++;
          }
        }

        double matchPercentage = matchedPoints / n;
        if (matchPercentage > bestScore &&
            matchPercentage >= minMatchPercentage) {
          bestScore = matchPercentage;
          startIdx = i;
          endIdx = currentRideIdx;
        }
      }
    }

    if (startIdx != -1 && endIdx != -1) {
      return SegmentMatch(segmentPoints, startIdx, endIdx, bestScore);
    }

    return null;
  }

  /// 判断两个点是否匹配（在阈值距离内）
  bool isPointMatch(LatLng point1, LatLng point2) {
    double pointDistance = distance.as(LengthUnit.Meter, point1, point2);
    return pointDistance <= distanceThreshold;
  }

  /// 辅助方法：返回两个数中的较小值
  int min(int a, int b) => a < b ? a : b;
}

// 使用示例
void main() {
  // 创建一些测试数据

  // 一条骑行记录
  List<LatLng> rideRoute = [
    LatLng(39.9042, 116.4074),
    LatLng(39.9043, 116.4075),
    LatLng(39.9044, 116.4076),
    LatLng(39.9045, 116.4077),
    LatLng(39.9046, 116.4078),
    LatLng(39.9047, 116.4079),
    LatLng(39.9048, 116.4080),
    LatLng(39.9049, 116.4081),
    LatLng(39.9050, 116.4082),
  ];

  // 赛段数据库
  List<List<LatLng>> segments = [
    // 赛段1：应该匹配
    [
      LatLng(39.9044, 116.4076),
      LatLng(39.9045, 116.4077),
      LatLng(39.9046, 116.4078),
    ],
    // 赛段2：不应该匹配
    [
      LatLng(39.8044, 116.3076),
      LatLng(39.8045, 116.3077),
    ],
    // 赛段3：部分匹配
    [
      LatLng(39.9049, 116.4081),
      LatLng(39.9050, 116.4082),
      LatLng(39.9051, 116.4083), // 骑行记录中没有这个点
    ],
  ];

  // 创建匹配器实例
  var matcher = SegmentMatcher();

  // 执行匹配
  List<SegmentMatch> matches = matcher.findSegments(rideRoute, segments);

  // 输出结果
  for (int i = 0; i < matches.length; i++) {
    var match = matches[i];
    print('匹配赛段 ${i + 1}:');
    print('  起始索引: ${match.startIndex}');
    print('  结束索引: ${match.endIndex}');
    print('  匹配百分比: ${(match.matchPercentage * 100).toStringAsFixed(2)}%');
    print('');
  }
}

// 可视化匹配结果的组件示例
class SegmentMatchVisualizer extends StatelessWidget {
  final List<LatLng> ridePoints;
  final List<SegmentMatch> matches;

  const SegmentMatchVisualizer({
    Key? key,
    required this.ridePoints,
    required this.matches,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // 这里可以使用flutter_map或其他地图组件来展示匹配结果
      // 简单起见，只返回文字描述
      child: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final match = matches[index];
          return ListTile(
            title: Text('赛段 ${index + 1}'),
            subtitle: Text(
                '匹配度: ${(match.matchPercentage * 100).toStringAsFixed(1)}%\n'
                '从点 ${match.startIndex} 到点 ${match.endIndex}'),
          );
        },
      ),
    );
  }
}

// 计算List<LatLng>的距离（单位：米）
double latlngToDistance(List<LatLng> points) {
  double totalDistance = 0.0;
  for (int i = 0; i < points.length - 1; i++) {
    totalDistance += const Distance()
        .as(LengthUnit.Meter, points[i], points[i + 1]); // 使用latlong2库计算距离
  }
  return totalDistance;
}
