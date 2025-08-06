import 'dart:convert';
import 'dart:io';

import 'package:app/database.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/path_utils.dart';
import 'package:drift/drift.dart';
import 'package:fit_tool/fit_tool.dart' hide Record;

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

Future<List<SegmentsCompanion>> analyzeSegment(
    List<Route> routes, List<RecordMessage> records, History history) async {
  final segments = routes.map((e) => e.route).toList();
  final subRoutes = SegmentMatcher().findSegments(history.route, segments);
  var res = <SegmentsCompanion>[];
  final db = Database();
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
    final bestScoreId = await db.into(db.bestScores).insert(bestScore);
    res.add(SegmentsCompanion(
      routeId: Value(subRoute.segmentId),
      historyId: Value(history.id),
      startIndex: Value(subRoute.startIndex),
      bestScoreId: Value(bestScoreId), // 关联BestScores表的id
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
    'maxSpeed': 0.0,
    'maxAltitude': 0.0,
    'totalAscent': 0.0,
    'totalDistance': lastRecord.distance! - firstRecord.distance!,
    'maxPower': 0.0,
    'totalElapsedTime':
        (lastRecord.timestamp! - firstRecord.timestamp!).toDouble(),
  };

  for (final record in records) {
    res['maxSpeed'] = (record.speed != null
        ? (record.speed! > res['maxSpeed']! ? record.speed! : res['maxSpeed'])
        : res['maxSpeed'])!;
    res['maxAltitude'] = (record.altitude != null
        ? (record.altitude! > res['maxAltitude']!
            ? record.altitude!
            : res['maxAltitude'])
        : res['maxAltitude'])!;
    res['maxPower'] = record.power != null
        ? (record.power! > res['maxPower']! ? record.power! : res['maxPower'])
            as double
        : res['maxPower'] as double;
  }

  return Summary(
    id: recordMsg.id,
    maxSpeed: res['maxSpeed'],
    maxAltitude: res['maxAltitude'],
    totalAscent: res['totalAscent'],
    totalDistance: res['totalDistance'],
    maxPower: res['maxPower'],
    totalElapsedTime: res['totalElapsedTime'] as double,
  );
}
