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
    final power = record.get('power') ?? 0.0;

    maxSpeed = speed > maxSpeed ? speed : maxSpeed;
    maxAltitude = altitude > maxAltitude ? altitude : maxAltitude;
    maxPower = power > maxPower ? power : maxPower;
  }

  BestScore update(List<DataMessage> records) {
    for (var record in records) {
      updateRecord(record);
    }
    final time = getTimestampFromDataMessage(records.last) -
        getTimestampFromDataMessage(records.first);
    final distance = records.last.get('distance') ?? 0.0;
    var ascent = 0.0;
    final altitudes = records
        .map((e) => e.get('altitude') ?? double.negativeInfinity)
        .where((e) => e != double.negativeInfinity);
    altitudes.fold(altitudes.first, (a, b) {
      ascent += (a < b ? b - a : 0.0);
      return b;
    });

    maxTime = maxTime > time ? maxTime : time;
    maxDistance = maxDistance > distance ? maxDistance : distance;
    maxClimb = ascent > maxClimb ? ascent : maxClimb;

    List<dynamic> alignedPoints = []; // 以1000m为间隔的点列表
    double accu = 0.0;

    for (int i = 1; i < records.length; i++) {
      accu += latlngToDistance([
        getLatlngFromDataMessage(records[i - 1]),
        getLatlngFromDataMessage(records[i]),
      ]);
      if (accu >= 1000) {
        alignedPoints.add({
          'timestamp': getTimestampFromDataMessage(records[i]),
          'pos': getLatlngFromDataMessage(records[i]),
        });
        accu -= 1000; // 重置为0同时保留多余的部分，保证值都在整数位置上
      }
    }

    // /*
    bestSpeedByDistance = calculateMaxRangeAvgs(
        [1, 5, 10, 20, 30, 50, 80, 100, 150, 160, 180, 200, 250, 300, 400, 500],
        alignedPoints, (key, range) {
      final accumulate = key * 1000; // in this case is range's length
      final timeSpent = range.last['timestamp'] - range.first['timestamp'];
      return timeSpent > 0 ? accumulate / timeSpent : 0.0; // in case of div 0
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
      '最大爬升': '${maxClimb.toStringAsFixed(2)} m', // 爬坡百分比
      '最大功率': '${maxPower.toStringAsFixed(2)} w', // 功率单位为瓦特
      '最大里程': '${(maxDistance / 1000).toInt()} km', // 转换为公里
      '最长时间': secondToFormatTime(maxTime.toDouble()), // 转换为时分秒格式
      ...Map.fromEntries(
        bestSpeedByDistance.entries.where((e) => e.value > 0).map(
              (e) => MapEntry(
                  "${e.key} km",
                  '${(e.value * 3.6).toStringAsFixed(2)} km/h'
                      ' ${secondToFormatTime(e.key * 1000.0 / e.value)}'),
            ),
      ),
      ...Map.fromEntries(
          bestPowerByTime.entries.where((e) => e.value > 0).map((e) => MapEntry(
                "功率： ${secondToFormatTime(e.key.toDouble())}",
                "${e.value.toStringAsFixed(2)} w",
              )))
    };
  }

  // 将当期数据和其他数据进行比较，返回其他数据比当前数据更好的部分
  Map<String, dynamic> getBetterDataDiff(BestScore other) {
    final betterData = <String, dynamic>{};

    // 比较最大速度
    if (other.maxSpeed >= maxSpeed) {
      betterData['最大速度'] = '${(other.maxSpeed * 3.6).toStringAsFixed(2)} km/h';
    }

    // 比较最大海拔
    if (other.maxAltitude >= maxAltitude) {
      betterData['最大海拔'] = '${other.maxAltitude.toStringAsFixed(2)} m';
    }

    // 比较最大爬坡
    if (other.maxClimb >= maxClimb) {
      betterData['最大爬升'] = '${other.maxClimb.toStringAsFixed(2)} m';
    }

    if (other.maxPower >= maxPower) {
      betterData['最大功率'] = '${other.maxPower.toStringAsFixed(2)} w';
    }

    if (other.maxDistance >= maxDistance) {
      betterData['最大里程'] = '${(other.maxDistance / 1000).toInt()} km';
    }
    if (other.maxTime >= maxTime) {
      betterData['最长时间'] = secondToFormatTime(other.maxTime.toDouble());
    }

    // 比较各个里程的最佳速度
    other.bestSpeedByDistance.forEach((distance, otherSpeed) {
      if (!bestSpeedByDistance.containsKey(distance) ||
          otherSpeed >= bestSpeedByDistance[distance]!) {
        betterData['$distance km'] =
            '${(otherSpeed * 3.6).toStringAsFixed(2)} km/h'
            ' ${secondToFormatTime(distance / otherSpeed)}';
      }
    });

    other.bestPowerByTime.forEach((time, otherPower) {
      if (!bestPowerByTime.containsKey(time) ||
          otherPower >= bestPowerByTime[time]!) {
        betterData['功率： ${secondToFormatTime(time.toDouble())}'] =
            '${otherPower.toStringAsFixed(2)} w';
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
    maxPower = maxPower > other.maxPower ? maxPower : other.maxPower;
    maxDistance =
        maxDistance > other.maxDistance ? maxDistance : other.maxDistance;
    maxTime = maxTime > other.maxTime ? maxTime : other.maxTime;
    other.bestPowerByTime.forEach((time, otherPower) {
      if (bestPowerByTime.containsKey(time)) {
        bestPowerByTime[time] = bestPowerByTime[time]! > otherPower
            ? bestPowerByTime[time]!
            : otherPower;
      } else {
        bestPowerByTime[time] = otherPower;
      }
    });

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

class SortManager<T, K> {
  final bool Function(T a, T b) _comparator;
  final List<Entry<T, K>> dataList = [];

  SortManager(this._comparator);

  void append(T item, K key) {
    dataList.add(Entry(item, key));
  }

  int getPositionTillCurrentIndex(K index) {
    final tIndex = dataList.indexWhere((entry) => entry.key == index);
    if (tIndex == -1) {
      return -1;
    }
    final target = dataList[tIndex];
    final subList = dataList.sublist(0, tIndex + 1);
    subList.sort((a, b) => _comparator(a.item, b.item)
        ? 1
        : _comparator(b.item, a.item)
            ? -1
            : 0);
    for (int i = 0; i < subList.length; i++) {
      if (identical(subList[i], target)) {
        return i;
      }
    }
    return -1;
  }

  int getPositionOfFullList(K index) {
    final tIndex = dataList.indexWhere((entry) => entry.key == index);
    if (tIndex == -1) {
      return -1;
    }
    final target = dataList[tIndex];
    final subList = dataList.sublist(0, dataList.length);
    subList.sort((a, b) => _comparator(a.item, b.item)
        ? 1
        : _comparator(b.item, a.item)
            ? -1
            : 0);
    for (int i = 0; i < subList.length; i++) {
      if (identical(subList[i], target)) {
        return i;
      }
    }
    return -1;
  }
}

class Entry<T, K> {
  final T item;
  final K key;

  Entry(this.item, this.key);
}

// 计算给定滑动窗口尺寸列表的最大平均值算法
Map<int, double> calculateMaxRangeAvgs(
    List<int> keys, List<dynamic> values, Function calcRangeAvg) {
  Map<int, double> res = {}; // 结果数组，key为keys, value为最大均值
  for (var key in keys.where((e) => e <= values.length)) {
    // 处理不同区间长度
    double maxAvg = 0.0; // 当前区间最大长度
    for (int start = 0; start + key < values.length; start++) {
      // 遍历所有可能的开头点
      final range = values.sublist(start, start + key);
      final avg = calcRangeAvg(key, range);
      maxAvg = maxAvg > avg ? maxAvg : avg;
    }
    res[key] = maxAvg;
  }
  return res;
}

String secondToFormatTime(num seconds) {
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
