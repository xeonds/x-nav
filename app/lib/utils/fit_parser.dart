import 'dart:io';

import 'package:fit_parser/fit_parser.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FitParser {
  static List<Map<String, dynamic>> parseFitFiles(String directoryPath) {
    final directory = Directory(directoryPath);
    final fitFiles = directory
        .listSync()
        .where((file) => file.path.endsWith('.fit'))
        .map((file) => file.path)
        .toList();
    final rideHistory = <Map<String, dynamic>>[];

    for (var file in fitFiles) {
      // 解析 .fit 文件并生成数据
      final data = parseFitFile(file);
      rideHistory.add(data);
    }

    return rideHistory;
  }

  static Map<String, dynamic> parseFitFile(String file) {
    // 实现 .fit 文件解析逻辑
    // 返回包含 distance, time, speed 等数据的 Map

    final fitFile = FitFile(path: file).parse();
    final records =
        fitFile.dataMessages.where((msg) => msg.get('record') != null);
    final historyPoints = records.map((record) {
      final lat = record.get('position_lat')! / 1e7;
      final lon = record.get('position_long')! / 1e7;
      return LatLng(lat, lon);
    }).toList();
    return {
      'distance': records.last.get('distance')! / 1000, // 替换为实际数据
      'time': records.last.get('timestamp')! ~/ 60, // 替换为实际数据
      'speed': records.last.get('speed')! * 3.6, // 替换为实际数据
      'points': historyPoints,
    };
  }
}
