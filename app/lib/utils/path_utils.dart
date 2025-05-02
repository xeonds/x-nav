import 'dart:math';

import 'package:app/utils/fit_parser.dart'
    show parseFitDataToMetric, parseFitDataToRoute, parseFitDataToSummary;
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

class SegmentMatch {
  final List<LatLng> segmentPoints;
  final int startIndex; // 骑行记录中匹配到赛段的起始点索引
  final int endIndex; // 骑行记录中匹配到赛段的结束点索引
  final double matchPercentage; // 匹配度百分比
  final int segmentIndex; // 赛段在所有赛段中的索引

  SegmentMatch(this.segmentPoints, this.startIndex, this.endIndex,
      this.matchPercentage, this.segmentIndex);
}

class SegmentMatcher {
  /// 用于确定两个坐标点是否匹配的距离阈值（单位：米）
  final double distanceThreshold;

  /// 赛段匹配的最小百分比阈值，低于此值不视为匹配
  final double minMatchPercentage;
  final double maxMatchPercentage;

  /// 距离计算器
  final Distance distance = const Distance();

  SegmentMatcher(
      {this.distanceThreshold = 30.0, // 默认30米
      this.minMatchPercentage = 0.9, // 默认90%匹配度
      this.maxMatchPercentage = 1.1});

  /// 检查骑行记录是否包含指定的赛段
  /// 返回所有匹配的赛段及其在骑行记录中的位置
  List<SegmentMatch> findSegments(
      List<LatLng> ridePoints, List<List<LatLng>> allSegments) {
    List<SegmentMatch> matches = [];
    for (int i = 0; i < allSegments.length; i++) {
      final segment = allSegments[i];
      // 赛段过短（少于2个点）则跳过
      if (segment.length < 2) continue;

      // 寻找此赛段在骑行记录中的匹配
      final match = matchSegment(ridePoints, segment, i);
      matches.addAll(match);
    }

    return matches;
  }

  /// 匹配单个赛段
  List<SegmentMatch> matchSegment(
      List<LatLng> ridePoints, List<LatLng> segmentPoints, int segId) {
    // 赛段起点在骑行记录中的可能位置
    List<int> possibleStartIndices = [];
    final segDistance = latlngToDistance(segmentPoints);

    // 找到所有可能的起点（每圈只取一个起点，避免同一圈多次匹配）
    final minGap = segDistance * minMatchPercentage;
    // int? lastAddedIndex;
    for (int i = 0; i < ridePoints.length; i++) {
      final dist =
          distance.as(LengthUnit.Meter, ridePoints[i], segmentPoints[0]);
      // 成功识别到第一个起点，那么直接添加点，并seek到minGap指示的点
      if (dist <= distanceThreshold) {
        possibleStartIndices.add(i);
        // 跳转路径，直到走过minGap
        for (double dist = 0; dist < minGap && i < ridePoints.length - 1; i++) {
          dist += latlngPointDistance(ridePoints[i], ridePoints[i + 1]);
        }
      }
      // if (dist <= distanceThreshold) {
      //   if (lastAddedIndex == null || i - lastAddedIndex >= minGap) {
      //     possibleStartIndices.add(i);
      //     lastAddedIndex = i;
      //   } else if (dist <
      //       distance.as(LengthUnit.Meter, ridePoints[lastAddedIndex],
      //           segmentPoints[0])) {
      //     // 如果当前点比上一个已添加点更接近起点，则替换
      //     possibleStartIndices[possibleStartIndices.length - 1] = i;
      //     lastAddedIndex = i;
      //   }
      // }
    }

    List<SegmentMatch> bestMatch = [];

    // 对每个可能的起点进行完整匹配检查
    for (int startIndex in possibleStartIndices) {
      int pathIndex = startIndex + 1;
      int segmentIndex = 1;
      int lastMatchedPathIndex = startIndex; // 跟踪最后一个匹配点的索引

      // 特殊情况：如果赛段只有一个点
      if (segmentPoints.length == 1) {
        return [
          SegmentMatch(segmentPoints, startIndex, startIndex, 1.0, segId)
        ];
      }

      // 从起点后开始匹配剩余点
      while (segmentIndex < segmentPoints.length &&
          pathIndex < ridePoints.length) {
        // 检查当前骑行点是否匹配当前赛段点
        if (isPointMatch(ridePoints[pathIndex], segmentPoints[segmentIndex])) {
          segmentIndex++;
          lastMatchedPathIndex = pathIndex; // 更新最后匹配点
        }
        pathIndex++;
      }

      // 计算匹配百分比
      final matchedSubRouteDistance = latlngToDistance(
          ridePoints.sublist(startIndex, lastMatchedPathIndex));
      double matchPercentage = matchedSubRouteDistance / segDistance;

      if (matchPercentage > minMatchPercentage &&
          matchPercentage < maxMatchPercentage) {
        bestMatch.add(SegmentMatch(
          segmentPoints,
          startIndex,
          lastMatchedPathIndex,
          matchPercentage,
          segId,
        ));
      }
    }

    return bestMatch;
  }

  /// 使用改进的路径匹配算法（基于动态规划思想）
  SegmentMatch? matchSegmentImproved(
      List<LatLng> ridePoints, List<LatLng> segmentPoints, int segId) {
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
      return SegmentMatch(segmentPoints, startIdx, endIdx, bestScore, segId);
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

SegmentScore parseSegmentToScore(
  SegmentMatch segment,
  Map<String, dynamic> rideData,
  List<LatLng> routePoints,
) {
  final startIndex = segment.startIndex;
  final endIndex = segment.endIndex;
  final startTime = rideData['records'][startIndex].get('timestamp');
  final endTime = rideData['records'][endIndex].get('timestamp');
  return SegmentScore(
      segment: segment,
      startTime: startTime,
      endTime: endTime,
      duration: endTime - startTime, // 秒
      avgSpeed: ((latlngToDistance(routePoints.sublist(startIndex, endIndex)) /
              1000.0) /
          ((endTime - startTime) / 1000.0) *
          3.6), // km/h
      distance: latlngToDistance(
            routePoints.sublist(startIndex, endIndex),
          ) /
          1000.0, // km
      route: routePoints.sublist(startIndex, endIndex));
}

// 赛段成绩类
class SegmentScore {
  final SegmentMatch segment;
  final double startTime;
  final double endTime;
  final double duration;
  final double avgSpeed;
  final double distance;
  final List<LatLng> route;

  SegmentScore({
    required this.segment,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.avgSpeed,
    required this.distance,
    required this.route,
  });
}

class RideScore {
  final Map<String, dynamic> rideData; // fitData原始数据
  late final List<LatLng> routePoints; // 骑行记录的路径点
  late final Map<String, dynamic> summary; // 骑行记录的统计数据

  late final List<double> speed; // 速度数据
  late final List<double> distance; // 距离数据
  late final List<double> altitude; // 海拔数据

  RideScore({
    required this.rideData,
    required routes,
  }) {
    routePoints = parseFitDataToRoute(rideData);
    summary = parseFitDataToSummary(rideData);
    final preSpeed = parseFitDataToMetric<double>(rideData, "speed")
        .map((e) => e * 3.6)
        .toList(); // km/h
    final preDistance = parseFitDataToMetric<double>(
      rideData,
      "distance",
    ).map((e) => e / 1000.0).toList(); // km
    final preAltitude = parseFitDataToMetric<double>(rideData, "altitude"); // m
    // TODO: 处理数据长度不一致的问题
    final minLength = [
      preSpeed.length,
      preDistance.length,
      preAltitude.length,
    ].reduce((a, b) => a < b ? a : b);
    speed = preSpeed.sublist(0, minLength);
    distance = preDistance.sublist(0, minLength);
    altitude = preAltitude.sublist(0, minLength);
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

// 计算两个LatLng点之间的距离（单位：米）
double latlngPointDistance(LatLng point1, LatLng point2) {
  return const Distance().as(LengthUnit.Meter, point1, point2);
}
