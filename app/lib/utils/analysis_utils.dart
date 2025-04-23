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
  double maxPower = 0.0;
  double maxDistance = 0.0;
  int maxTime = 0; // 最大时间
  Map<int, double> bestSpeedByDistance = {}; // 里程（米）对应的最佳速度
  Map<int, double> bestPowerByTime = {}; // 时间段（秒）对应的最大功率

  void updateRecord(DataMessage record) {
    final speed = record.get('speed') ?? 0.0;
    final altitude = record.get('altitude') ?? 0.0;
    final grade = record.get('grade') ?? 0.0;
    final power = record.get('power') ?? 0.0;

    // 更新最大速度
    if (speed > maxSpeed) {
      maxSpeed = speed;
    }

    // 更新最大海拔
    if (altitude > maxAltitude) {
      maxAltitude = altitude;
    }

    // 更新最大爬坡
    if (grade > maxClimb) {
      maxClimb = grade;
    }

    if (power > maxPower) {
      maxPower = power;
    }
  }

  BestScore update(List<DataMessage> records) {
    for (var record in records) {
      updateRecord(record);
    }
    final distance = records.last.get('distance') ?? 0.0;
    maxDistance = maxDistance > distance ? maxDistance : distance;

    final time = getTimestampFromDataMessage(records.last) -
        getTimestampFromDataMessage(records.first);
    maxTime = maxTime > time ? maxTime : time;

    List<dynamic> alignedPoints = []; // 以1000m为间隔的点列表
    double accu = 0.0;

    for (int i = 1; i < records.length; i++) {
      accu += latlngToDistance([
        getLatlngFromDataMessage(records[i - 1]),
        getLatlngFromDataMessage(records[i]),
      ]);
      if (accu >= 1000) {
        alignedPoints.add({
          'timestamp': records[i].get("timestamp"),
          'pos': getLatlngFromDataMessage(records[i]),
        });
        accu -= 1000; // 重置为0同时保留多余的部分，保证值都在整数位置上
      }
    }

    // /*
    bestSpeedByDistance = calculateMaxRangeAvgs([
      1000,
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
    ], alignedPoints, (key, range) {
      final accumulate = key; // in this case is range's length
      final timeSpent = range.last['timestamp'] - range.first['timestamp'];
      return timeSpent > 0 ? accumulate / timeSpent : 0; // in case of div 0
    });

    // ensure points are aligned to seconds
    // here for performance reason assume points are aligned as seconds
    final alignedPower = records
        .map((e) => {
              'power': e.get('power') ?? 0,
              'timestamp': e.get('timestamp'),
            })
        .toList();
    bestPowerByTime = calculateMaxRangeAvgs(
        [5, 10, 30, 60, 300, 480, 1200, 1800, 3600], alignedPower,
        (key, range) {
      final accumulate = range.fold(0, (a, b) => a + b['power']);
      return accumulate / key;
    });

    return this;
  }

  Map<String, String> getBestData() {
    return {
      '最大速度': '${(maxSpeed * 3.6).toStringAsFixed(2)} km/h', // 转换为 km/h
      '最大海拔': '${maxAltitude.toStringAsFixed(2)} m', // 保持单位为米
      '最大爬坡': '${maxClimb.toStringAsFixed(2)} %', // 爬坡百分比
      '最大功率': '${maxPower.toStringAsFixed(2)} w', // 功率单位为瓦特
      '最大里程': '${(maxDistance / 1000).toInt()} km', // 转换为公里
      '最长时间': secondToFormatTime(maxTime.toDouble()), // 转换为时分秒格式
      ...Map.fromEntries(
        bestSpeedByDistance.entries.where((e) => e.value > 0).map(
              (e) => MapEntry(
                  "${(e.key / 1000).toInt()} km",
                  '${(e.value * 3.6).toStringAsFixed(2)} km/h'
                      ' ${secondToFormatTime(e.key * 1000.0 / e.value)}'),
            ),
      ),
      ...Map.fromEntries(
          bestPowerByTime.entries.where((e) => e.value > 0).map((e) => MapEntry(
                "功率： ${secondToFormatTime(e.key.toDouble())}",
                "${e.value} w",
              )))
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

// 计算给定滑动窗口尺寸列表的最大平均值算法
Map<int, double> calculateMaxRangeAvgs(
    List<int> keys, List<dynamic> values, Function calcRangeAvg) {
  Map<int, double> res = {}; // 结果数组，key为keys, value为最大均值
  for (var key in keys) {
    // 处理不同区间长度
    double maxAvg = 0.0; // 当前区间最大长度
    for (int start = 0; start + key < values.length; start++) {
      // 遍历所有可能的开头点
      final range = values.sublist(start, start + key);
      double avg = calcRangeAvg(key, range);
      maxAvg = maxAvg > avg ? maxAvg : avg;
    }
    res[key] = maxAvg;
  }
  return res;
}
