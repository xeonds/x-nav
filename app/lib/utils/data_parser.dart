import 'dart:io';
import 'dart:isolate';

import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/model.dart';
import 'package:app/utils/path_utils.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:flutter/material.dart';

Map<String, String> parseGpxFiles(List<File> files, {SendPort? sendPort}) {
  final gpxFiles = <String, String>{};
  int count = 0;

  for (var file in files) {
    try {
      final gpxData = file.readAsStringSync();
      gpxFiles[file.path] = gpxData;
      sendPort?.send({'progress': '路书解析中： ${count++}/${files.length}'});
    } catch (e) {
      debugPrint('Error reading GPX file: $e');
    }
  }

  return gpxFiles;
}

Map<String, List<Message>> parseFitFiles(List<File> files,
    {SendPort? sendPort}) {
  final fitDataList = <String, List<Message>>{};
  int count = 0;

  for (var file in files) {
    fitDataList[file.path] = parseFitFile(file);
    sendPort?.send({'progress': '骑行记录解析中： ${count++}/${files.length}'});
  }
  return fitDataList;
}

Map<String, dynamic> analyzeRideData(List<Map<String, dynamic>> summaries) {
  return summaries.fold<Map<String, dynamic>>(
    {'totalDistance': 0.0, 'totalRides': 0, 'totalTime': 0},
    (value, element) => {
      'totalDistance':
          value['totalDistance'] + (element['total_distance'] ?? 0.0),
      'totalRides': value['totalRides'] + 1,
      'totalTime': value['totalTime'] + (element['total_elapsed_time'] ?? 0),
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

Map<String, dynamic> analyzeBestScore(List<List<Message>> data) {
  final routes = data.map((record) => parseFitDataToRoute(record)).toList();

  final bestScoreTillNow = <int, BestScore>{};
  final bestScoreAtTimestamp = <int, BestScore>{};
  final bestSegment = <int, SortManager<SegmentScore, int>>{};
  final currBestScore = BestScore();
  final subRoutesOfRoutes = <int, List<SegmentScore>>{};

  final orderedFitData = data
    ..sort((a, b) => (timestampWithOffset(
                a.whereType<SessionMessage>().first.startTime!) -
            timestampWithOffset(b.whereType<SessionMessage>().first.startTime!))
        .toInt());

  for (var fitData in orderedFitData) {
    final timestamp = timestampWithOffset(
        fitData.whereType<SessionMessage>().first.startTime!);
    final bestScoreForTimestamp = BestScore().update(fitData);
    // modified, because merge current bestscore don't mix new best's judgement
    currBestScore.merge(bestScoreForTimestamp);
    bestScoreTillNow[timestamp] = BestScore()..merge(currBestScore); // copy
    bestScoreAtTimestamp[timestamp] = bestScoreForTimestamp;
    final routePoints = parseFitDataToRoute(fitData);
    final subRoutes = SegmentMatcher().findSegments(routePoints, routes);
    final analysisOfSubRoutes = subRoutes
        .map((item) => parseSegmentToScore(item, fitData, routePoints))
        .toList();
    subRoutesOfRoutes[timestamp] = analysisOfSubRoutes;
    for (var item in analysisOfSubRoutes) {
      if (bestSegment.containsKey(item.segment.segmentIndex)) {
        bestSegment[item.segment.segmentIndex]!
            .append(item, item.startTime.toInt());
      } else {
        bestSegment[item.segment.segmentIndex] =
            SortManager<SegmentScore, int>((a, b) => a.avgSpeed < b.avgSpeed)
              ..append(item, item.startTime.toInt());
      }
    }
  }

  return {
    'bestScore': bestScoreTillNow,
    'bestScoreAt': bestScoreAtTimestamp,
    'bestSegment': bestSegment,
    'subRoutesOfRoutes': subRoutesOfRoutes,
  };
}
