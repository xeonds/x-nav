import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

// 解析gpx文件并生成路径
List<LatLng> parseGpxToPath(String gpxData) {
  final document = XmlDocument.parse(gpxData);
  final track = document.findAllElements('trk').first;
  final trackSeg = track.findElements('trkseg').first;
  final trackPoints = trackSeg.findElements('trkpt');
  return trackPoints.map((point) {
    final lat = double.parse(point.getAttribute('lat')!);
    final lon = double.parse(point.getAttribute('lon')!);
    return LatLng(lat, lon);
  }).toList();
}

// 解析gpx文件并生成路线名称
String parseGpxToName(String gpxData) {
  final document = XmlDocument.parse(gpxData);
  final track = document.findAllElements('trk').first;
  final name = track.findElements('name').first;
  return name.value?.trim() ?? '';
}
