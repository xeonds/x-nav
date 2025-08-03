import 'dart:io';

import 'package:app/database.dart';
import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit.dart';
import 'package:app/utils/model.dart';
import 'package:app/utils/path_utils.dart';
import 'package:fit_tool/fit_tool.dart';

String parseGpxFile(File file) {
  final gpxData = file.readAsStringSync();

  return gpxData;
}

Map<String, dynamic> analyzeRideData(List<SummaryData> summaries) {
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

List<MapEntry<int, BestScore>> analyzeBestScore(List<SummaryData> data) {
  final res = {};
  final dataByTimeAsc = data
    ..sort((a, b) => (a.startTime!.isAfter(b.startTime!) ? 1 : -1));

  
}

void analyzeSegment() {
  final subRoutesOfRoutes = <int, List<Segment>>{};
  final bestSegment = <int, SortManager<Segment, int>>{};

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
            SortManager<Segment, int>((a, b) => a.avgSpeed < b.avgSpeed)
              ..append(item, item.startTime.toInt());
      }
    }
  }
}
