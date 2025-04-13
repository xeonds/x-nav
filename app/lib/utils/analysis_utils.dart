import 'package:app/utils/fit_parser/fit_parser.dart';
import 'package:app/utils/path_utils.dart';
import 'package:latlong2/latlong.dart' show LatLng;

class BestScore {
  double maxSpeed = 0.0;
  double maxAltitude = 0.0;
  double maxClimb = 0.0;
  Map<int, double> bestSpeedByDistance = {}; // 里程（米）对应的最佳速度
  Map<int, double> bestPowerByTime = {}; // 时间段（秒）对应的最大功率

  void updateRecord(DataMessage record) {
    final speed = record.get('speed') ?? 0.0;
    final altitude = record.get('altitude') ?? 0.0;
    final power = record.get('power') ?? 0.0;
    final distance = record.get('distance') ?? 0.0;

    // 更新最大速度
    if (speed > maxSpeed) {
      maxSpeed = speed;
    }

    // 更新最大海拔
    if (altitude > maxAltitude) {
      maxAltitude = altitude;
    }

    // 更新最大爬坡
    if (record.get('grade') != null && record.get('grade') > maxClimb) {
      maxClimb = record.get('grade');
    }
  }

  BestScore update(List<DataMessage> records) {
    for (var record in records) {
      updateRecord(record);
    }
    // 更新各个里程的最佳速度
    for (var distanceKey in [
      1000,
      2000,
      3000,
      4000,
      5000,
      10000,
      20000,
      30000,
      50000,
      80000,
      100000,
      150000,
      160000,
      180000,
      200000,
      300000,
      400000,
      500000
    ]) {
      double maxAvgSpeed = 0.0;

      for (int i = 0; i < records.length;) {
        double segmentDistance = 0.0;

        for (int k = i + 1; k < records.length; k++) {
          segmentDistance += latlngToDistance([
            LatLng(
              records[k - 1].get('position_lat') / 1e7,
              records[k - 1].get('position_long') / 1e7,
            ),
            LatLng(
              records[k].get('position_lat') / 1e7,
              records[k].get('position_long') / 1e7,
            ),
          ]);

          if (segmentDistance >= 1000) {
            i = k; // 更新起点为当前步长的终点
            break;
          }
        }

        if (segmentDistance < 1000) {
          break; // 如果剩余距离不足1km，退出循环
        }
        double totalDistance = 0.0;

        for (int j = i; j < records.length; j++) {
          if (j > i) {
            totalDistance += latlngToDistance([
              LatLng(
                records[j - 1].get('position_lat') / 1e7,
                records[j - 1].get('position_long') / 1e7,
              ),
              LatLng(
                records[j].get('position_lat') / 1e7,
                records[j].get('position_long') / 1e7,
              ),
            ]);
          }

          if (totalDistance >= distanceKey) {
            double totalTime =
                records[j].get('timestamp') - records[i].get('timestamp');
            double avgSpeed = totalDistance / (totalTime / 1000);
            if (avgSpeed > maxAvgSpeed) {
              maxAvgSpeed = avgSpeed;
            }
            break;
          }
        }
      }

      bestSpeedByDistance[distanceKey] = maxAvgSpeed;
    }

    // // 更新各个时间段的最大功率
    // for (var timeKey in [5, 10, 30, 60, 300, 600]) {}

    return this;
  }

  Map<String, dynamic> getBestData() {
    return {
      'maxSpeed': maxSpeed,
      'maxAltitude': maxAltitude,
      'maxClimb': maxClimb,
      'bestSpeedByDistance': bestSpeedByDistance,
      'bestPowerByTime': bestPowerByTime,
    };
  }
}
