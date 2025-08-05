import 'dart:io';

import 'package:app/constants.dart';
import 'package:app/utils/model.dart';
import 'package:app/utils/storage.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fit_tool/fit_tool.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DriftDatabase(
    tables: [Historys, Routes, Segments, Summarys, Records, BestScores, KVs])
class Database extends _$Database {
  Database() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // @override
  // MigrationStrategy get migration => MigrationStrategy();

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = Storage.appDocPath!;
      final file = File(p.join(dbFolder, sqliteDBName));
      return NativeDatabase(file);
    });
  }
}
