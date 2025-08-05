import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:app/database.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/data_loader.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/model.dart';
import 'package:app/utils/path_utils.dart';
import 'package:drift/drift.dart';
import 'package:fit_tool/fit_tool.dart' hide Record;
import 'package:latlong2/latlong.dart';

String parseGpxFile(File file) {
  final gpxData = file.readAsStringSync();

  return gpxData;
}

Map<String, dynamic> analyzeRideData(List<Summary> summaries) {
  return summaries.fold<Map<String, dynamic>>(
    {'totalDistance': 0.0, 'totalRides': 0, 'totalTime': 0},
    (value, element) => {
      'totalDistance': value['totalDistance'] + element.totalDistance,
      'totalRides': value['totalRides'] + 1,
      'totalTime': value['totalTime'] + element.totalElapsedTime,
    },
  );
}

List<Map<String, dynamic>> analyzeSummaryData(List<List<Message>> fitData) {
  return fitData
      .map<SessionMessage>(parseFitDataToSummary)
      .map<Map<String, dynamic>>((session) {
    return {
      "timestamp": session.timestamp,
      "start_time": session.startTime,
      "sport": session.sport,
      "max_temperature": session.maxTemperature,
      "avg_temperature": session.avgTemperature,
      "total_ascent": session.totalAscent,
      "total_descent": session.totalDescent,
      "total_distance": session.totalDistance,
      "total_elapsed_time": session.totalElapsedTime,
    };
  }).toList();
}

BestScoresCompanion analyzeBestScore(Summary summary, Record recordMsg) {
  final records = recordMsg.messages;

  List<int> alignedTime = []; // 以1000m为间隔的时间点列表
  for (int dist = 0, i = 0;
      dist.toDouble() < summary.totalDistance! && i < records.length;
      i++) {
    if (dist.toDouble() < records[i].distance!) {
      alignedTime.add(timestampWithOffset(records[i].timestamp!));
      dist += 1000;
    }
  }

  // /*
  final bestSpeedByDistance = calculateMaxRangeAvgs<int, num>(
      [1, 5, 10, 20, 30, 50, 80, 100, 150, 160, 180, 200, 250, 300, 400, 500],
      alignedTime, (key, range) {
    final accumulate = key * 1000; // in this case is range's length
    final timeSpent = range.last - range.first;
    return timeSpent > 0 ? accumulate / timeSpent : 0.0; // in case of div 0
  });

  // ensure points are aligned to seconds
  // here for performance reason assume points are aligned as seconds
  final alignedPower = records.map((e) => e.power!).toList();
  final bestPowerByTime = calculateMaxRangeAvgs<int, num>(
      [5, 10, 30, 60, 300, 480, 1200, 1800, 3600], alignedPower, (key, range) {
    final accumulate = range.fold(0, (a, b) => a + b);
    return accumulate / key;
  });

  final alignedHR = records.map((e) => e.heartRate ?? 0).toList();
  final bestHRByTime = calculateMaxRangeAvgs<int, num>(
      [5, 10, 30, 60, 300, 480, 1200, 1800, 3600], alignedHR, (key, range) {
    final accumulate = range.fold(0, (a, b) => a + b);
    return accumulate / key;
  });
  return BestScoresCompanion(
    maxSpeed: Value(summary.maxSpeed!),
    maxAltitude: Value(summary.maxAltitude!),
    maxClimb: Value(summary.totalAscent!),
    maxDistance: Value(summary.totalDistance!),
    maxPower: Value(summary.maxPower ?? 0),
    maxTime: Value(summary.totalElapsedTime!.toInt()),
    bestSpeedByDistanceJson: Value(bestSpeedByDistance.toJson()),
    bestHRByTimeJson: Value(bestHRByTime.toJson()),
    bestPowerByTimeJson: Value(bestPowerByTime.toJson()),
  );
}

extension on Map<int, num> {
  String toJson() {
    return jsonEncode(this);
  }
}

List<SegmentsCompanion> analyzeSegment(
    List<Route> routes, List<RecordMessage> records, History history) {
  final segments = routes.map((e) => e.route).toList();
  final subRoutes = SegmentMatcher().findSegments(history.route, segments);
  var res = <SegmentsCompanion>[];
  //
  for (final subRoute in subRoutes) {
    // final segmentRecords = records.sublist(startIndex, endIndex + 1);
    final summary = Summary(
      id: 0,
      maxSpeed: 0,
      maxAltitude: 0,
      totalAscent: 0,
      totalDistance: 0,
      maxPower: 0,
      totalElapsedTime: 0,
    );
    final recordMsg = Record(
      messages: records.sublist(subRoute.startIndex, subRoute.endIndex + 1),
      id: 0,
      historyId: 0,
    );
    final bestScore = analyzeBestScore(summary, recordMsg);
    res.add(SegmentsCompanion(
      routeId: Value(subRoute.segmentId),
      historyId: Value(history.id),
      startIndex: Value(subRoute.startIndex),
      bestScoreId: Value(0), // 关联BestScores表的id
      endIndex: Value(subRoute.endIndex),
      matchPercentage: Value(subRoute.matchPercentage),
    ));
  }
  return res;
}

Summary parseRecordsToSummary(Record recordMsg) {
  final records = recordMsg.messages;
  if (records.isEmpty) {
    return Summary(
      id: 0,
      maxSpeed: 0,
      maxAltitude: 0,
      totalAscent: 0,
      totalDistance: 0,
      maxPower: 0,
      totalElapsedTime: 0,
    );
  }

  final firstRecord = records.first;
  final lastRecord = records.last;
  var res = {
    'maxSpeed': firstRecord.speed ?? 0.0,
    'maxAltitude': firstRecord.altitude ?? 0.0,
    'totalAscent': firstRecord.ascent ?? 0.0,
    'totalDistance': lastRecord.distance ?? 0.0,
    'maxPower': firstRecord.power ?? 0.0,
    'totalElapsedTime': (lastRecord.timestamp! - firstRecord.timestamp!).toDouble(),
  };

  for (final record in records) {
    res['maxSpeed'] = record.speed ?? res['maxSpeed'];
    res['maxAltitude'] = record.altitude ?? res['maxAltitude'];
    res['totalAscent'] += record.ascent ?? 0.0;
    res['totalDistance'] += record.distance ?? 0.0;
    res['maxPower'] = record.power ?? res['maxPower'];
  }

  return Summary(
    id: recordMsg.id,
    maxSpeed: res['maxSpeed'] ?? 0.0,
    maxAltitude: res['maxAltitude'] ?? 0.0,
    totalAscent: res['totalAscent'] ?? 0.0,
    totalDistance: res['totalDistance'] ?? 0.0,
    maxPower: res['maxPower'] ?? 0.0,
    totalElapsedTime: (lastRecord.timestamp! - firstRecord.timestamp!).toDouble(),
  );
}