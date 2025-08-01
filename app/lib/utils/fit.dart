import 'dart:io';
import 'dart:math';

import 'package:fit_tool/fit_tool.dart';
import 'package:latlong2/latlong.dart';

// parse the original fit data
// Map<String, dynamic> parseFitFile(Uint8List content) {
//   late final FitFile fitFile;
//   try {
//     fitFile = FitFile(content: content).parse();
//   } catch (e) {
//     print(e);
//     return {};
//   }

//   final sessions = fitFile.dataMessages
//       .where((msg) => msg.definitionMessage!.globalMessageName == 'session')
//       .toList();

//   final records = fitFile.dataMessages
//       .where((msg) => msg.definitionMessage!.globalMessageName == 'record')
//       .where((msg) => msg.get('position_lat') != null)
//       .toList();

//   return {'records': records, 'sessions': sessions};
// }

List<Message> parseFitFile(File file) {
  final bytes = file.readAsBytesSync();
  final fitFile = FitFile.fromBytes(bytes);
  return fitFile.records
      .map((e) => e.message)
      .where((msg) => msg is RecordMessage || msg is SessionMessage)
      .toList();
}

List<LatLng> parseFitDataToRoute(List<Message> records) {
  return records
      .whereType<RecordMessage>()
      .map((e) => LatLng(
            // notice: value can be null, need judge
            e.positionLat! / 11930465.0,
            e.positionLong! / 11930465.0,
          ))
      .toList();
  // return data['records']
  //     .where((msg) => msg.get('position_lat') != null)
  //     .map((record) => LatLng(
  //           record.get('position_lat')! / 11930465.0,
  //           record.get('position_long')! / 11930465.0,
  //         ))
  //     .cast<LatLng>()
  //     .toList();
}

SessionMessage parseFitDataToSummary(List<Message> records) {
  return records.whereType<SessionMessage>().toList().first;
  // final sessions = data['sessions']
  //     .where((session) => session.get('sport') == 'cycling')
  //     .toList();

  // if (sessions.isEmpty) {
  //   return {
  //     'totalDistance': 0,
  //     'totalDuration': 0,
  //     'avgSpeed': 0,
  //   };
  // } else if (sessions.length == 1) {
  //   return {
  //     "timestamp": sessions.first.get('timestamp'),
  //     "start_time": sessions.first.get('start_time'),
  //     "sport": sessions.first.get('sport'),
  //     "max_temperature": sessions.first.get('max_temperature'),
  //     "avg_temperature": sessions.first.get('avg_temperature'),
  //     "total_ascent": sessions.first.get('total_ascent'),
  //     "total_descent": sessions.first.get('total_descent'),
  //     "total_distance": sessions.first.get('total_distance'),
  //     "total_elapsed_time": sessions.first.get('total_elapsed_time'),
  //     "total_timer_time": sessions.first.get('total_timer_time'),
  //     "total_moving_time": sessions.first.get('total_moving_time'),
  //     "total_calories": sessions.first.get('total_calories'),
  //     "total_work": sessions.first.get('total_work'),
  //     "max_power": sessions.first.get('max_power'),
  //     "enhanced_max_speed": sessions.first.get('enhanced_max_speed'),
  //     "max_speed": sessions.first.get('max_speed'),
  //     "max_cadence": sessions.first.get('max_cadence'),
  //     "max_heart_rate": sessions.first.get('max_heart_rate'),
  //     "avg_power": sessions.first.get('avg_power'),
  //     "enhanced_avg_speed": sessions.first.get('enhanced_avg_speed'),
  //     "avg_speed": sessions.first.get('avg_speed'),
  //     "avg_cadence": sessions.first.get('avg_cadence'),
  //     "avg_heart_rate": sessions.first.get('avg_heart_rate'),
  //     "enhanced_avg_altitude": sessions.first.get('enhanced_avg_altitude'),
  //     "avg_altitude": sessions.first.get('avg_altitude'),
  //     "enhanced_max_altitude": sessions.first.get('enhanced_max_altitude'),
  //     "max_altitude": sessions.first.get('max_altitude'),
  //     "avg_grade": sessions.first.get('avg_grade'),
  //     "threshold_power": sessions.first.get('threshold_power'),
  //   };
  // } else {
  //   return {
  //     "timestamp": sessions.first.get('timestamp'),
  //     "start_time": sessions.first.get('start_time'),
  //     "sport": sessions.first.get('sport'),
  //     "max_temperature": sessions
  //         .map((session) => session.get('max_temperature'))
  //         .reduce((a, b) => a > b ? a : b),
  //     "avg_temperature": sessions
  //             .map((session) => session.get('avg_temperature'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "total_ascent": sessions
  //         .map((session) => session.get('total_ascent'))
  //         .reduce((a, b) => a + b),
  //     "total_descent": sessions
  //         .map((session) => session.get('total_descent'))
  //         .reduce((a, b) => a + b),
  //     "total_distance": sessions
  //         .map((session) => session.get('total_distance'))
  //         .reduce((a, b) => a + b),
  //     "total_elapsed_time": sessions
  //         .map((session) => session.get('total_elapsed_time'))
  //         .reduce((a, b) => a + b),
  //     "total_timer_time": sessions
  //         .map((session) => session.get('total_timer_time'))
  //         .reduce((a, b) => a + b),
  //     "total_moving_time": sessions
  //         .map((session) => session.get('total_moving_time'))
  //         .reduce((a, b) => a + b),
  //     "total_calories": sessions
  //         .map((session) => session.get('total_calories'))
  //         .reduce((a, b) => a + b),
  //     "total_work": sessions
  //         .map((session) => session.get('total_work'))
  //         .reduce((a, b) => a + b),
  //     "max_power": sessions
  //         .map((session) => session.get('max_power'))
  //         .reduce((a, b) => a > b ? a : b),
  //     "enhanced_max_speed": sessions
  //         .map((session) => session.get('enhanced_max_speed'))
  //         .reduce((a, b) => a > b ? a : b),
  //     "max_speed": sessions
  //         .map((session) => session.get('max_speed'))
  //         .reduce((a, b) => a > b ? a : b),
  //     "max_cadence": sessions
  //         .map((session) => session.get('max_cadence'))
  //         .reduce((a, b) => a > b ? a : b),
  //     "max_heart_rate": sessions
  //         .map((session) => session.get('max_heart_rate'))
  //         .reduce((a, b) => a > b ? a : b),
  //     "avg_power": sessions
  //             .map((session) => session.get('avg_power'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "enhanced_avg_speed": sessions
  //             .map((session) => session.get('enhanced_avg_speed'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "avg_speed": sessions
  //             .map((session) => session.get('avg_speed'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "avg_cadence": sessions
  //             .map((session) => session.get('avg_cadence'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "avg_heart_rate": sessions
  //             .map((session) => session.get('avg_heart_rate'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "enhanced_avg_altitude": sessions
  //             .map((session) => session.get('enhanced_avg_altitude'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "avg_altitude": sessions
  //             .map((session) => session.get('avg_altitude'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "enhanced_max_altitude": sessions
  //         .map((session) => session.get('enhanced_max_altitude'))
  //         .reduce((a, b) => a > b ? a : b),
  //     "max_altitude": sessions
  //         .map((session) => session.get('max_altitude'))
  //         .reduce((a, b) => a > b ? a : b),
  //     "avg_grade": sessions
  //             .map((session) => session.get('avg_grade'))
  //             .reduce((a, b) => a + b) /
  //         sessions.length,
  //     "threshold_power": sessions
  //         .map((session) => session.get('threshold_power'))
  //         .reduce((a, b) => a > b ? a : b),
  //   };
  // }
}

List<T> parseFitDataToMetric<T>(
  Map<String, dynamic> data,
  String metric, {
  num? startTime,
  num? endTime,
}) {
  return data['records']
      .where((msg) {
        final value = msg.get(metric);
        final ts = msg.get('timestamp');
        if (value == null || ts == null) return false;
        if (startTime != null && ts < startTime) return false;
        if (endTime != null && ts > endTime) return false;
        return true;
      })
      .map((record) => record.get(metric)!)
      .cast<T>()
      .toList();
}

LatLng latlngWithOffset(LatLng origin) {
  return LatLng(origin.latitude / 11930465.0, origin.longitude / 11930465.0);
}

DateTime dateTimeWithOffset(num timestamp) {
  return DateTime.fromMillisecondsSinceEpoch(
      timestampWithOffset(timestamp) * 1000);
}

// convert fit timestamp to normal timestamp
int timestampWithOffset(num timestamp) {
  return ((timestamp + 631065600) / 1000).toInt();
}

String parseFitTimestampToDateTimeString(DateTime dateTime) {
  dateTime = dateTime.toLocal();
  final now = DateTime.now();
  final difference = now.difference(dateTime).inDays;
  if (difference == 0) {
    return '今天 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  } else if (difference == 1) {
    return '昨天 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  } else {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
