// 最佳成绩统计类
// 有两种使用方法，一是计算本次运动最佳数据
// 二是用作数据类，用于存储最佳数据和进行同类之间的diff比较
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';

import 'package:app/utils/analysis_utils.dart';
import 'package:app/utils/fit.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:gpx/gpx.dart';

class BestScore {
  double maxSpeed = 0.0;
  double maxAltitude = 0.0;
  double maxClimb = 0.0;
  double maxPower = 0.0;
  double maxDistance = 0.0;
  int maxTime = 0; // 最大时间
  Map<int, double> bestSpeedByDistance = {}; // 里程（米）对应的最佳速度
  Map<int, double> bestPowerByTime = {}; // 时间段（秒）对应的最大功率
  Map<int, double> bestHRByTime = {}; // 时间段（秒）对应的最大功率

  void updateRecord(SessionMessage record) {
    maxSpeed = max(record.maxSpeed!, maxSpeed);
    maxAltitude = max(record.maxAltitude!, maxAltitude);
    maxPower = max(record.maxPower!.toDouble(), maxPower);
    maxTime = max(record.totalMovingTime!.toInt(), maxTime);
    maxClimb = max(record.totalAscent!.toDouble(), maxClimb);
  }

  BestScore update(List<Message> records) {
    final sessionMsg = records.whereType<SessionMessage>().first;
    final recordMsg = records.whereType<RecordMessage>().toList();
    List<int> alignedPoints = []; // 以1000m为间隔的点列表

    updateRecord(sessionMsg);

    for (int dist = 0, i = 0;
        dist.toDouble() < sessionMsg.totalDistance! && i < recordMsg.length;
        i++) {
      if (dist.toDouble() < recordMsg[i].distance!) {
        alignedPoints.add(timestampWithOffset(recordMsg[i].timestamp!));
        dist += 1000;
      }
    }

    // /*
    bestSpeedByDistance = calculateMaxRangeAvgs(
        [1, 5, 10, 20, 30, 50, 80, 100, 150, 160, 180, 200, 250, 300, 400, 500],
        alignedPoints, (key, range) {
      final accumulate = key * 1000; // in this case is range's length
      final timeSpent = range.last - range.first;
      return timeSpent > 0 ? accumulate / timeSpent : 0.0; // in case of div 0
    });

    // ensure points are aligned to seconds
    // here for performance reason assume points are aligned as seconds
    final alignedPower = recordMsg.map((e) => e.power!).toList();
    bestPowerByTime = calculateMaxRangeAvgs(
        [5, 10, 30, 60, 300, 480, 1200, 1800, 3600], alignedPower,
        (key, range) {
      final accumulate = range.fold(0, (a, b) => a + b);
      return accumulate / key;
    });

    final alignedHR = recordMsg.map((e) => e.heartRate ?? 0).toList();
    bestHRByTime = calculateMaxRangeAvgs(
        [5, 10, 30, 60, 300, 480, 1200, 1800, 3600], alignedHR, (key, range) {
      final accumulate = range.fold(0, (a, b) => a + b);
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

extension Route on Gpx {
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'creator': creator,
      'metadata': metadata,
      'wpts': wpts,
      'rtes': rtes,
      'trks': trks,
      'extensions': extensions
    };
  }
}

extension History on List<Message> {
  Map<String, dynamic> toJson() {
    return {
      'record_message': whereType<RecordMessage>().toList(),
      'session_message': whereType<SessionMessage>().toList(),
    };
  }
}
