import 'package:app/utils/fit_parser/src/fit_file.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

// parse the original fit data
Map<String, dynamic> parseFitFile(Uint8List content) {
  late final FitFile fitFile;
  try {
    fitFile = FitFile(content: content).parse();
  } catch (e) {
    print(e);
    return {};
  }

  final sessions = fitFile.dataMessages
      .where((msg) => msg.definitionMessage!.globalMessageName == 'session')
      .toList();

  final records = fitFile.dataMessages
      .where((msg) => msg.definitionMessage!.globalMessageName == 'record')
      .where((msg) => msg.get('position_lat') != null)
      .toList();

  return {'records': records, 'sessions': sessions};
}

List<LatLng> parseFitDataToRoute(Map<String, dynamic> data) {
  return data['records']
      .where((msg) => msg.get('position_lat') != null)
      .map((record) => LatLng(
            record.get('position_lat')! / 11930465.0,
            record.get('position_long')! / 11930465.0,
          ))
      .cast<LatLng>()
      .toList();
}

Map<String, dynamic> parseFitDataToSummary(Map<String, dynamic> data) {
  final records = data['records'];
  final sessions = data['sessions'];

  final totalDistance = records
      .map((record) => record.get('distance') ?? 0)
      .fold(0, (a, b) => a + b);

  final totalDuration = sessions
      .map((session) => session.get('total_elapsed_time') ?? 0)
      .fold(0, (a, b) => a + b);

  final totalCalories = sessions
      .map((session) => session.get('total_calories') ?? 0)
      .fold(0, (a, b) => a + b);

  return {
    'totalDistance': totalDistance,
    'totalDuration': totalDuration,
    'totalCalories': totalCalories,
  };
}
