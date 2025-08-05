import 'dart:convert';
import 'dart:typed_data';

import 'package:app/database.dart';
import 'package:drift/drift.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:latlong2/latlong.dart';

// 赛段在路径中的匹配信息
class SegmentMatch {
  final List<LatLng> segmentPoints;
  final int startIndex; // 骑行记录中匹配到赛段的起始点索引
  final int endIndex; // 骑行记录中匹配到赛段的结束点索引
  final double matchPercentage; // 匹配度百分比
  final int segmentId; // 赛段在所有赛段中的索引

  SegmentMatch(this.segmentPoints, this.startIndex, this.endIndex,
      this.matchPercentage, this.segmentId);
}

// data class for segment records
// Drift table for segment records
class Segments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routeId => integer()(); // 关联Routes的id
  IntColumn get historyId => integer()(); // 关联History的id
  IntColumn get bestScoreId => integer()();
  IntColumn get startIndex => integer()(); // 骑行记录中匹配到赛段的起始点索引
  IntColumn get endIndex => integer()(); // 骑行记录中匹配到赛段的结束点索引
  RealColumn get matchPercentage => real()(); // 匹配度百分比
}

// data class for routes
// Drift table for routes
class Routes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()(); // 路径文件
  RealColumn get distance => real()(); // 路线距离
  TextColumn get route => text().map(LatlngListConverter())(); // 路线点序列化为json字符串
}

// data class for ride histories
// Drift table for ride histories
class Historys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()(); // 路径文件
  DateTimeColumn get createdAt => dateTime().nullable()(); // 创建时间
  TextColumn get route => text().map(LatlngListConverter())(); // 路线点序列化为json字符串
  IntColumn get summaryId => integer().nullable()(); // 关联Summary的id
}

// data class for each ride's analysis
class Summarys extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timestamp => integer().nullable()();
  DateTimeColumn get startTime => dateTime().nullable()();
  TextColumn get sport => text().nullable()();
  RealColumn get maxTemperature => real().nullable()();
  RealColumn get avgTemperature => real().nullable()();
  RealColumn get totalAscent => real().nullable()();
  RealColumn get totalDescent => real().nullable()();
  RealColumn get totalDistance => real().nullable()();
  RealColumn get totalElapsedTime => real().nullable()();
  RealColumn get totalTimerTime => real().nullable()();
  RealColumn get totalMovingTime => real().nullable()();
  RealColumn get totalCalories => real().nullable()();
  RealColumn get totalWork => real().nullable()();
  RealColumn get maxPower => real().nullable()();
  RealColumn get enhancedMaxSpeed => real().nullable()();
  RealColumn get maxSpeed => real().nullable()();
  RealColumn get maxCadence => real().nullable()();
  RealColumn get maxHeartRate => real().nullable()();
  RealColumn get avgPower => real().nullable()();
  RealColumn get enhancedAvgSpeed => real().nullable()();
  RealColumn get avgSpeed => real().nullable()();
  RealColumn get avgCadence => real().nullable()();
  RealColumn get avgHeartRate => real().nullable()();
  RealColumn get enhancedAvgAltitude => real().nullable()();
  RealColumn get avgAltitude => real().nullable()();
  RealColumn get enhancedMaxAltitude => real().nullable()();
  RealColumn get maxAltitude => real().nullable()();
  RealColumn get avgGrade => real().nullable()();
  RealColumn get thresholdPower => real().nullable()();
}

// data class for each data entry's best score, like speed, ride distance
class BestScores extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get maxSpeed => real().withDefault(const Constant(0.0))();
  RealColumn get maxAltitude => real().withDefault(const Constant(0.0))();
  RealColumn get maxClimb => real().withDefault(const Constant(0.0))();
  RealColumn get maxPower => real().withDefault(const Constant(0.0))();
  RealColumn get maxDistance => real().withDefault(const Constant(0.0))();
  IntColumn get maxTime => integer().withDefault(const Constant(0))();
  TextColumn get bestSpeedByDistanceJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get bestPowerByTimeJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get bestHRByTimeJson => text().withDefault(const Constant('{}'))();
  IntColumn get historyId => integer().nullable()(); // 可选：关联历史记录

  // Map<String, String> getBestData() {
  //   return {
  //     '最大速度': '${(maxSpeed * 3.6).toStringAsFixed(2)} km/h', // 转换为 km/h
  //     '最大海拔': '${maxAltitude.toStringAsFixed(2)} m', // 保持单位为米
  //     '最大爬升': '${maxClimb.toStringAsFixed(2)} m', // 爬坡百分比
  //     '最大功率': '${maxPower.toStringAsFixed(2)} w', // 功率单位为瓦特
  //     '最大里程': '${(maxDistance / 1000).toInt()} km', // 转换为公里
  //     '最长时间': secondToFormatTime(maxTime.toDouble()), // 转换为时分秒格式
  //     ...Map.fromEntries(
  //       bestSpeedByDistance.entries.where((e) => e.value > 0).map(
  //             (e) => MapEntry(
  //                 "${e.key} km",
  //                 '${(e.value * 3.6).toStringAsFixed(2)} km/h'
  //                     ' ${secondToFormatTime(e.key * 1000.0 / e.value)}'),
  //           ),
  //     ),
  //     ...Map.fromEntries(
  //         bestPowerByTime.entries.where((e) => e.value > 0).map((e) => MapEntry(
  //               "功率： ${secondToFormatTime(e.key.toDouble())}",
  //               "${e.value.toStringAsFixed(2)} w",
  //             )))
  //   };
  // }

  // // 将当期数据和其他数据进行比较，返回其他数据比当前数据更好的部分
  // Map<String, dynamic> getBetterDataDiff(BestScore other) {
  //   final betterData = <String, dynamic>{};

  //   // 比较最大速度
  //   if (other.maxSpeed >= maxSpeed) {
  //     betterData['最大速度'] = '${(other.maxSpeed * 3.6).toStringAsFixed(2)} km/h';
  //   }

  //   // 比较最大海拔
  //   if (other.maxAltitude >= maxAltitude) {
  //     betterData['最大海拔'] = '${other.maxAltitude.toStringAsFixed(2)} m';
  //   }

  //   // 比较最大爬坡
  //   if (other.maxClimb >= maxClimb) {
  //     betterData['最大爬升'] = '${other.maxClimb.toStringAsFixed(2)} m';
  //   }

  //   if (other.maxPower >= maxPower) {
  //     betterData['最大功率'] = '${other.maxPower.toStringAsFixed(2)} w';
  //   }

  //   if (other.maxDistance >= maxDistance) {
  //     betterData['最大里程'] = '${(other.maxDistance / 1000).toInt()} km';
  //   }
  //   if (other.maxTime >= maxTime) {
  //     betterData['最长时间'] = secondToFormatTime(other.maxTime.toDouble());
  //   }

  //   // 比较各个里程的最佳速度
  //   other.bestSpeedByDistance.forEach((distance, otherSpeed) {
  //     if (!bestSpeedByDistance.containsKey(distance) ||
  //         otherSpeed >= bestSpeedByDistance[distance]!) {
  //       betterData['$distance km'] =
  //           '${(otherSpeed * 3.6).toStringAsFixed(2)} km/h'
  //           ' ${secondToFormatTime(distance / otherSpeed)}';
  //     }
  //   });

  //   other.bestPowerByTime.forEach((time, otherPower) {
  //     if (!bestPowerByTime.containsKey(time) ||
  //         otherPower >= bestPowerByTime[time]!) {
  //       betterData['功率： ${secondToFormatTime(time.toDouble())}'] =
  //           '${otherPower.toStringAsFixed(2)} w';
  //     }
  //   });

  //   return betterData;
  // }

  // 将其他数据项合并到当前实例，合并策略：直接使用其他实例的成员变量更新当前实例的成员变量，
  // 对于当前不存在的kv对，直接加入结果；对于当前存在的kv对，取二者最大值。
  // void merge(BestScore other) {
  //   maxSpeed = maxSpeed > other.maxSpeed ? maxSpeed : other.maxSpeed;
  //   maxAltitude =
  //       maxAltitude > other.maxAltitude ? maxAltitude : other.maxAltitude;
  //   maxClimb = maxClimb > other.maxClimb ? maxClimb : other.maxClimb;
  //   maxPower = maxPower > other.maxPower ? maxPower : other.maxPower;
  //   maxDistance =
  //       maxDistance > other.maxDistance ? maxDistance : other.maxDistance;
  //   maxTime = maxTime > other.maxTime ? maxTime : other.maxTime;
  //   other.bestPowerByTime.forEach((time, otherPower) {
  //     if (bestPowerByTime.containsKey(time)) {
  //       bestPowerByTime[time] = bestPowerByTime[time]! > otherPower
  //           ? bestPowerByTime[time]!
  //           : otherPower;
  //     } else {
  //       bestPowerByTime[time] = otherPower;
  //     }
  //   });

  //   other.bestSpeedByDistance.forEach((distance, otherSpeed) {
  //     if (bestSpeedByDistance.containsKey(distance)) {
  //       bestSpeedByDistance[distance] =
  //           bestSpeedByDistance[distance]! > otherSpeed
  //               ? bestSpeedByDistance[distance]!
  //               : otherSpeed;
  //     } else {
  //       bestSpeedByDistance[distance] = otherSpeed;
  //     }
  //   });
  // }
}

// data class for each item in fit
class Records extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get historyId => integer()(); // 关联History的id
  BlobColumn get messages => blob().map(RecordMessageListBinaryConverter())();
}

class KVs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text()();
}

class RecordMessageListBinaryConverter
    extends TypeConverter<List<RecordMessage>, Uint8List> {
  @override
  List<RecordMessage> fromSql(Uint8List fromDb) {
    final data = ByteData.view(fromDb.buffer);
    int offset = 0;
    final defLength = data.getUint32(offset, Endian.little);
    offset += 4;
    final count = data.getUint32(offset, Endian.little);
    offset += 4;
    final defBytes = fromDb.sublist(offset, offset + defLength);
    offset += defLength;
    final definition = DefinitionMessage.fromBytes(defBytes);
    final messages = <RecordMessage>[];
    for (int i = 0; i < count; i++) {
      final msgLength = data.getUint32(offset, Endian.little);
      offset += 4;
      final msgBytes = fromDb.sublist(offset, offset + msgLength);
      offset += msgLength;
      messages.add(RecordMessage.fromBytes(definition, msgBytes));
    }
    return messages;
  }

  @override
  Uint8List toSql(List<RecordMessage> value) {
    final builder = BytesBuilder();
    final defBytes = DefinitionMessage.fromDataMessage(value.first).toBytes();
    final header = Uint8List(8);
    final headerData = ByteData.view(header.buffer);
    headerData.setUint32(0, defBytes.length, Endian.little);
    headerData.setUint32(4, value.length, Endian.little);
    builder.add(header);
    builder.add(defBytes);
    for (int i = 0; i < value.length; i++) {
      final msgBytes = value[i].toBytes();
      final lengthHeader = Uint8List(4);
      final lengthData = ByteData.view(lengthHeader.buffer);
      lengthData.setUint32(0, msgBytes.length, Endian.little);
      builder.add(lengthHeader);
      builder.add(msgBytes);
    }
    return builder.toBytes();
  }
}

class LatlngListConverter extends TypeConverter<List<LatLng>, String> {
  @override
  List<LatLng> fromSql(String data) {
    final arr = jsonDecode(data) as List;
    return arr.map((e) => LatLng(e[0], e[1])).toList();
  }

  @override
  String toSql(List<LatLng> pts) {
    return jsonEncode(pts.map((p) => [p.latitude, p.longitude]).toList());
  }
}
