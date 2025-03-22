import 'package:fit_parser/fit_parser.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> parseFitFile(String file) {
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

List<LatLng> parseFitFileToRoute(Map<String, dynamic> data) {
  return data['points'];
}
