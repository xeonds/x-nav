import 'package:app/utils/fit_parser.dart';
import 'package:app/utils/fit_parser/fit_parser.dart';
import 'package:app/utils/path_utils.dart';

// 最佳成绩统计类
// 有两种使用方法，一是计算本次运动最佳数据
// 二是用作数据类，用于存储最佳数据和进行同类之间的diff比较
class BestScore {
  double maxSpeed = 0.0;
  double maxAltitude = 0.0;
  double maxClimb = 0.0;
  Map<int, double> bestSpeedByDistance = {}; // 里程（米）对应的最佳速度
  Map<int, double> bestPowerByTime = {}; // 时间段（秒）对应的最大功率

  void updateRecord(DataMessage record) {
    final speed = record.get('speed') ?? 0.0;
    final altitude = record.get('altitude') ?? 0.0;
    // TODO:实现可选的数据项展示
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
    List<int> integerKmIndices = [];

    // 找到所有里程为1km整数倍附近的点
    double accumulatedDistance = 0.0;
    for (int i = 1; i < records.length; i++) {
      accumulatedDistance += latlngToDistance([
        latlngFromFitData(records[i - 1].get('position_lat'),
            records[i - 1].get('position_long')),
        latlngFromFitData(
            records[i].get('position_lat'), records[i].get('position_long')),
      ]);

      if (accumulatedDistance >= 1000) {
        integerKmIndices.add(i);
        accumulatedDistance -= 1000; // 重置为0同时保留多余的部分，保证值都在整数位置上
      }
    }

    // 滑动窗口计算各个长度区间的最小用时
    for (var distanceKey in [
      // 1000,
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
      250000,
      300000,
      400000,
      500000,
    ]) {
      double maxAvgSpeed = 0.0;

      int windowSize = distanceKey ~/ 1000; // 滑动窗口大小，以整数公里为单位
      for (int start = 0;
          start + windowSize < integerKmIndices.length;
          start++) {
        int end = start + windowSize;
        double segmentDistance = distanceKey.toDouble();
        double totalTime = records[integerKmIndices[end]].get('timestamp') -
            records[integerKmIndices[start]].get('timestamp'); // 单位 秒
        if (totalTime > 0) {
          double avgSpeed = segmentDistance / totalTime; // 单位 米/秒
          if (avgSpeed > maxAvgSpeed) {
            maxAvgSpeed = avgSpeed;
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
    final expandedBestSpeed = bestSpeedByDistance.entries
        .where((entry) => entry.value > 0)
        .map((entry) => MapEntry((entry.key / 1000).toInt(), entry.value));

    return {
      '最大速度': '${(maxSpeed * 3.6).toStringAsFixed(2)} km/h', // 转换为 km/h
      '最大海拔': '${maxAltitude.toStringAsFixed(2)} m', // 保持单位为米
      '最大爬坡': '${maxClimb.toStringAsFixed(2)} %', // 爬坡百分比
      ...expandedBestSpeed.toList().asMap().map((index, entry) {
        return MapEntry(
          "${entry.key} km",
          '${(entry.value * 3.6).toStringAsFixed(2)} km/h'
              ' ${secondToFormatTime(entry.key * 1000.0 / entry.value)}',
        );
      }),
    };
  }

  // 将当期数据和其他数据进行比较，返回其他数据比当前数据更好的部分
  Map<String, dynamic> getBetterDataDiff(BestScore other) {
    final betterData = <String, dynamic>{};

    // 比较最大速度
    if (other.maxSpeed > maxSpeed) {
      betterData['最大速度'] = '${(other.maxSpeed * 3.6).toStringAsFixed(2)} km/h';
    }

    // 比较最大海拔
    if (other.maxAltitude > maxAltitude) {
      betterData['最大海拔'] = '${other.maxAltitude.toStringAsFixed(2)} m';
    }

    // 比较最大爬坡
    if (other.maxClimb > maxClimb) {
      betterData['最大爬坡'] = '${other.maxClimb.toStringAsFixed(2)} %';
    }

    // 比较各个里程的最佳速度
    other.bestSpeedByDistance.forEach((distance, otherSpeed) {
      if (!bestSpeedByDistance.containsKey(distance) ||
          otherSpeed > bestSpeedByDistance[distance]!) {
        betterData['${(distance / 1000).toInt()} km'] =
            '${(otherSpeed * 3.6).toStringAsFixed(2)} km/h'
            ' ${secondToFormatTime(distance / otherSpeed)}';
      }
    });

    return betterData;
  }

  // 将其他数据项合并到当前实例，合并策略：直接使用其他实例的成员变量更新当前实例的成员变量，
  // 对于当前不存在的kv对，直接加入结果；对于当前存在的kv对，取二者最大值。
  void merge(BestScore other) {
    maxSpeed = maxSpeed > other.maxSpeed ? maxSpeed : other.maxSpeed;
    maxAltitude =
        maxAltitude > other.maxAltitude ? maxAltitude : other.maxAltitude;
    maxClimb = maxClimb > other.maxClimb ? maxClimb : other.maxClimb;

    other.bestSpeedByDistance.forEach((distance, otherSpeed) {
      if (bestSpeedByDistance.containsKey(distance)) {
        bestSpeedByDistance[distance] =
            bestSpeedByDistance[distance]! > otherSpeed
                ? bestSpeedByDistance[distance]!
                : otherSpeed;
      } else {
        bestSpeedByDistance[distance] = otherSpeed;
      }
    });
  }
}

String secondToFormatTime(double seconds) {
  if (seconds.isInfinite || seconds.isNaN) {
    return '00:00';
  }
  int hours = seconds ~/ 3600;
  int minutes = (seconds % 3600) ~/ 60;
  int secs = seconds.toInt() % 60;

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  } else {
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
