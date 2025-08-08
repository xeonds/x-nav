import 'dart:convert';
import 'dart:math';

import 'package:app/utils/fit.dart';
import 'package:app/utils/model.dart';
import 'package:fit_tool/fit_tool.dart'
    show Message, RecordMessage, SessionMessage;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' show LatLng, Distance, LengthUnit;

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

  // /// 使用改进的路径匹配算法（基于动态规划思想）
  // SegmentMatch? matchSegmentImproved(
  //     List<LatLng> ridePoints, List<LatLng> segmentPoints, int segId) {
  //   if (ridePoints.isEmpty || segmentPoints.isEmpty) return null;

  //   // 使用动态规划的方法查找最佳匹配路径
  //   int m = ridePoints.length;
  //   int n = segmentPoints.length;

  //   // 创建一个矩阵来记录每个骑行点与赛段点的距离
  //   List<List<double>> distanceMatrix =
  //       List.generate(m, (_) => List.filled(n, double.infinity));

  //   // 填充距离矩阵
  //   for (int i = 0; i < m; i++) {
  //     for (int j = 0; j < n; j++) {
  //       distanceMatrix[i][j] =
  //           distance.as(LengthUnit.Meter, ridePoints[i], segmentPoints[j]);
  //     }
  //   }

  //   // 用于回溯的最佳匹配路径
  //   List<List<int>> bestPath = List.generate(m, (_) => List.filled(n, -1));

  //   // 动态规划求解
  //   int startIdx = -1;
  //   int endIdx = -1;
  //   double bestScore = double.negativeInfinity;

  //   for (int i = 0; i < m; i++) {
  //     if (distanceMatrix[i][0] <= distanceThreshold) {
  //       // 可能的起点
  //       int currentRideIdx = i;
  //       int currentSegmentIdx = 0;
  //       int matchedPoints = 1;

  //       while (currentRideIdx < m - 1 && currentSegmentIdx < n - 1) {
  //         currentRideIdx++;
  //         // 寻找下一个最佳匹配点
  //         double minDist = double.infinity;
  //         int bestNextSegmentIdx = -1;

  //         for (int j = currentSegmentIdx;
  //             j < min(currentSegmentIdx + 5, n);
  //             j++) {
  //           if (distanceMatrix[currentRideIdx][j] < minDist &&
  //               distanceMatrix[currentRideIdx][j] <= distanceThreshold) {
  //             minDist = distanceMatrix[currentRideIdx][j];
  //             bestNextSegmentIdx = j;
  //           }
  //         }

  //         if (bestNextSegmentIdx != -1) {
  //           currentSegmentIdx = bestNextSegmentIdx;
  //           matchedPoints++;
  //         }
  //       }

  //       double matchPercentage = matchedPoints / n;
  //       if (matchPercentage > bestScore &&
  //           matchPercentage >= minMatchPercentage) {
  //         bestScore = matchPercentage;
  //         startIdx = i;
  //         endIdx = currentRideIdx;
  //       }
  //     }
  //   }

  //   if (startIdx != -1 && endIdx != -1) {
  //     return SegmentMatch(segmentPoints, startIdx, endIdx, bestScore, segId);
  //   }

  //   return null;
  // }

  /// 判断两个点是否匹配（在阈值距离内）
  bool isPointMatch(LatLng point1, LatLng point2) {
    double pointDistance = distance.as(LengthUnit.Meter, point1, point2);
    return pointDistance <= distanceThreshold;
  }

  /// 辅助方法：返回两个数中的较小值
  int min(int a, int b) => a < b ? a : b;
}

// SegmentScore parseSegmentToScore(
//   SegmentMatch segment,
//   History rideData,
//   List<LatLng> routePoints,
// ) {
//   final sessionMsg = rideData.whereType<SessionMessage>().first;

//   final startIndex = segment.startIndex;
//   final endIndex = segment.endIndex;
//   final startTime = sessionMsg.startTime!;
//   final endTime = sessionMsg.totalMovingTime! + startTime;
//   return SegmentScore(
//       segment: segment,
//       startTime: startTime.toDouble(),
//       endTime: endTime,
//       duration: endTime - startTime, // 秒
//       avgSpeed: ((latlngToDistance(routePoints.sublist(startIndex, endIndex)) /
//               1000.0) /
//           ((endTime - startTime) / 1000.0) *
//           3.6), // km/h
//       distance: latlngToDistance(
//             routePoints.sublist(startIndex, endIndex),
//           ) /
//           1000.0, // km
//       route: routePoints.sublist(startIndex, endIndex));
// }

class RideScore {
  final List<Message> rideData; // fitData原始数据
  late final List<LatLng> routePoints; // 骑行记录的路径点
  late final SessionMessage summary; // 骑行记录的统计数据

  List<double> speed = []; // 速度数据
  List<double> distance = []; // 距离数据
  List<double> altitude = []; // 海拔数据
  List<num> power = []; // 功率数据
  List<num> heartRate = []; // 心率数据

  // fix: initialize list
  RideScore({
    required this.rideData,
    required routes,
  }) {
    routePoints = parseFitDataToRoute(rideData);
    summary = parseFitDataToSummary(rideData);
    rideData.whereType<RecordMessage>().toList().forEach((e) {
      speed.add(e.speed ?? 0.0 * 3.6); // km/h
      distance.add(e.distance ?? 0.0 / 1000.0); // km
      altitude.add(e.altitude ?? 0.0); // m
      power.add(e.power ?? 0.0); // W
      heartRate.add(e.heartRate ?? 0.0); // bpm
    });
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

class RidePathPainter extends CustomPainter {
  final List<LatLng> points;

  RidePathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (points.isNotEmpty) {
      final path = Path();

      // 获取经纬度的最小值和最大值
      final minLat =
          points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      final maxLat =
          points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      final minLng =
          points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      final maxLng =
          points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

      // 计算缩放比例
      final scaleX = size.width / (maxLng - minLng);
      final scaleY = size.height / (maxLat - minLat);
      final scale = scaleX < scaleY ? scaleX : scaleY;

      // 计算偏移量
      final offsetX = (size.width - (maxLng - minLng) * scale) / 2;
      final offsetY = (size.height - (maxLat - minLat) * scale) / 2;

      // 移动到起点
      path.moveTo(
        (points[0].longitude - minLng) * scale + offsetX,
        (maxLat - points[0].latitude) * scale + offsetY,
      );

      // 绘制路径
      for (var point in points) {
        path.lineTo(
          (point.longitude - minLng) * scale + offsetX,
          (maxLat - point.latitude) * scale + offsetY,
        );
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // 数据变化时触发重绘
  }
}

// 计算海拔高度，稀疏采样：当点太多时均匀间隔采样64点
Future<List<double>> fetchElevationData(List<LatLng> route) async {
  List<LatLng> sampledRoute;
  if (route.length > 64) {
    sampledRoute = List.generate(
      64,
      (i) => route[((route.length - 1) * i ~/ 63)],
    );
  } else {
    sampledRoute = route;
  }
  final locations =
      sampledRoute.map((p) => '${p.latitude},${p.longitude}').join('|');
  final url =
      'https://api.open-elevation.com/api/v1/lookup?locations=$locations';
  final resp = await http.get(Uri.parse(url));
  if (resp.statusCode == 200) {
    final data = jsonDecode(resp.body);
    final results = data['results'] as List;
    // _elevationData =
    //     results.map((e) => (e['elevation'] as num).toDouble()).toList();
    return results.map((e) => (e['elevation'] as num).toDouble()).toList();
    // 计算坡度百分比
    // _slopeData = [];
    // for (var i = 1; i < _elevationData.length; i++) {
    //   final dAlt = _elevationData[i] - _elevationData[i - 1];
    //   final dDist = (_distanceData[i] - _distanceData[i - 1]);
    //   _slopeData.add(dDist > 0 ? (dAlt / dDist * 100) : 0);
    // }
  } else {
    return [];
  }
}
