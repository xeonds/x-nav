// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HistorysTable extends Historys with TableInfo<$HistorysTable, History> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistorysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<List<LatLng>, String> route =
      GeneratedColumn<String>('route', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<LatLng>>($HistorysTable.$converterroute);
  static const VerificationMeta _summaryIdMeta =
      const VerificationMeta('summaryId');
  @override
  late final GeneratedColumn<int> summaryId = GeneratedColumn<int>(
      'summary_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bestScoreIdMeta =
      const VerificationMeta('bestScoreId');
  @override
  late final GeneratedColumn<int> bestScoreId = GeneratedColumn<int>(
      'best_score_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, filePath, createdAt, route, summaryId, bestScoreId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'historys';
  @override
  VerificationContext validateIntegrity(Insertable<History> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('summary_id')) {
      context.handle(_summaryIdMeta,
          summaryId.isAcceptableOrUnknown(data['summary_id']!, _summaryIdMeta));
    }
    if (data.containsKey('best_score_id')) {
      context.handle(
          _bestScoreIdMeta,
          bestScoreId.isAcceptableOrUnknown(
              data['best_score_id']!, _bestScoreIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  History map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return History(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at']),
      route: $HistorysTable.$converterroute.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route'])!),
      summaryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}summary_id']),
      bestScoreId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}best_score_id']),
    );
  }

  @override
  $HistorysTable createAlias(String alias) {
    return $HistorysTable(attachedDatabase, alias);
  }

  static TypeConverter<List<LatLng>, String> $converterroute =
      LatlngListConverter();
}

class History extends DataClass implements Insertable<History> {
  final int id;
  final String filePath;
  final DateTime? createdAt;
  final List<LatLng> route;
  final int? summaryId;
  final int? bestScoreId;
  const History(
      {required this.id,
      required this.filePath,
      this.createdAt,
      required this.route,
      this.summaryId,
      this.bestScoreId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    {
      map['route'] =
          Variable<String>($HistorysTable.$converterroute.toSql(route));
    }
    if (!nullToAbsent || summaryId != null) {
      map['summary_id'] = Variable<int>(summaryId);
    }
    if (!nullToAbsent || bestScoreId != null) {
      map['best_score_id'] = Variable<int>(bestScoreId);
    }
    return map;
  }

  HistorysCompanion toCompanion(bool nullToAbsent) {
    return HistorysCompanion(
      id: Value(id),
      filePath: Value(filePath),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      route: Value(route),
      summaryId: summaryId == null && nullToAbsent
          ? const Value.absent()
          : Value(summaryId),
      bestScoreId: bestScoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(bestScoreId),
    );
  }

  factory History.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return History(
      id: serializer.fromJson<int>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      route: serializer.fromJson<List<LatLng>>(json['route']),
      summaryId: serializer.fromJson<int?>(json['summaryId']),
      bestScoreId: serializer.fromJson<int?>(json['bestScoreId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filePath': serializer.toJson<String>(filePath),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'route': serializer.toJson<List<LatLng>>(route),
      'summaryId': serializer.toJson<int?>(summaryId),
      'bestScoreId': serializer.toJson<int?>(bestScoreId),
    };
  }

  History copyWith(
          {int? id,
          String? filePath,
          Value<DateTime?> createdAt = const Value.absent(),
          List<LatLng>? route,
          Value<int?> summaryId = const Value.absent(),
          Value<int?> bestScoreId = const Value.absent()}) =>
      History(
        id: id ?? this.id,
        filePath: filePath ?? this.filePath,
        createdAt: createdAt.present ? createdAt.value : this.createdAt,
        route: route ?? this.route,
        summaryId: summaryId.present ? summaryId.value : this.summaryId,
        bestScoreId: bestScoreId.present ? bestScoreId.value : this.bestScoreId,
      );
  History copyWithCompanion(HistorysCompanion data) {
    return History(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      route: data.route.present ? data.route.value : this.route,
      summaryId: data.summaryId.present ? data.summaryId.value : this.summaryId,
      bestScoreId:
          data.bestScoreId.present ? data.bestScoreId.value : this.bestScoreId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('History(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('route: $route, ')
          ..write('summaryId: $summaryId, ')
          ..write('bestScoreId: $bestScoreId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, filePath, createdAt, route, summaryId, bestScoreId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is History &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.createdAt == this.createdAt &&
          other.route == this.route &&
          other.summaryId == this.summaryId &&
          other.bestScoreId == this.bestScoreId);
}

class HistorysCompanion extends UpdateCompanion<History> {
  final Value<int> id;
  final Value<String> filePath;
  final Value<DateTime?> createdAt;
  final Value<List<LatLng>> route;
  final Value<int?> summaryId;
  final Value<int?> bestScoreId;
  const HistorysCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.route = const Value.absent(),
    this.summaryId = const Value.absent(),
    this.bestScoreId = const Value.absent(),
  });
  HistorysCompanion.insert({
    this.id = const Value.absent(),
    required String filePath,
    this.createdAt = const Value.absent(),
    required List<LatLng> route,
    this.summaryId = const Value.absent(),
    this.bestScoreId = const Value.absent(),
  })  : filePath = Value(filePath),
        route = Value(route);
  static Insertable<History> custom({
    Expression<int>? id,
    Expression<String>? filePath,
    Expression<DateTime>? createdAt,
    Expression<String>? route,
    Expression<int>? summaryId,
    Expression<int>? bestScoreId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (createdAt != null) 'created_at': createdAt,
      if (route != null) 'route': route,
      if (summaryId != null) 'summary_id': summaryId,
      if (bestScoreId != null) 'best_score_id': bestScoreId,
    });
  }

  HistorysCompanion copyWith(
      {Value<int>? id,
      Value<String>? filePath,
      Value<DateTime?>? createdAt,
      Value<List<LatLng>>? route,
      Value<int?>? summaryId,
      Value<int?>? bestScoreId}) {
    return HistorysCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      route: route ?? this.route,
      summaryId: summaryId ?? this.summaryId,
      bestScoreId: bestScoreId ?? this.bestScoreId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (route.present) {
      map['route'] =
          Variable<String>($HistorysTable.$converterroute.toSql(route.value));
    }
    if (summaryId.present) {
      map['summary_id'] = Variable<int>(summaryId.value);
    }
    if (bestScoreId.present) {
      map['best_score_id'] = Variable<int>(bestScoreId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistorysCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('route: $route, ')
          ..write('summaryId: $summaryId, ')
          ..write('bestScoreId: $bestScoreId')
          ..write(')'))
        .toString();
  }
}

class $RoutesTable extends Routes with TableInfo<$RoutesTable, Route> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _distanceMeta =
      const VerificationMeta('distance');
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
      'distance', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<LatLng>, String> route =
      GeneratedColumn<String>('route', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<LatLng>>($RoutesTable.$converterroute);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, filePath, distance, route, data];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routes';
  @override
  VerificationContext validateIntegrity(Insertable<Route> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(_distanceMeta,
          distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta));
    } else if (isInserting) {
      context.missing(_distanceMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Route map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Route(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      distance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}distance'])!,
      route: $RoutesTable.$converterroute.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route'])!),
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
    );
  }

  @override
  $RoutesTable createAlias(String alias) {
    return $RoutesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<LatLng>, String> $converterroute =
      LatlngListConverter();
}

class Route extends DataClass implements Insertable<Route> {
  final int id;
  final String filePath;
  final double distance;
  final List<LatLng> route;
  final String data;
  const Route(
      {required this.id,
      required this.filePath,
      required this.distance,
      required this.route,
      required this.data});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_path'] = Variable<String>(filePath);
    map['distance'] = Variable<double>(distance);
    {
      map['route'] =
          Variable<String>($RoutesTable.$converterroute.toSql(route));
    }
    map['data'] = Variable<String>(data);
    return map;
  }

  RoutesCompanion toCompanion(bool nullToAbsent) {
    return RoutesCompanion(
      id: Value(id),
      filePath: Value(filePath),
      distance: Value(distance),
      route: Value(route),
      data: Value(data),
    );
  }

  factory Route.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Route(
      id: serializer.fromJson<int>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      distance: serializer.fromJson<double>(json['distance']),
      route: serializer.fromJson<List<LatLng>>(json['route']),
      data: serializer.fromJson<String>(json['data']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filePath': serializer.toJson<String>(filePath),
      'distance': serializer.toJson<double>(distance),
      'route': serializer.toJson<List<LatLng>>(route),
      'data': serializer.toJson<String>(data),
    };
  }

  Route copyWith(
          {int? id,
          String? filePath,
          double? distance,
          List<LatLng>? route,
          String? data}) =>
      Route(
        id: id ?? this.id,
        filePath: filePath ?? this.filePath,
        distance: distance ?? this.distance,
        route: route ?? this.route,
        data: data ?? this.data,
      );
  Route copyWithCompanion(RoutesCompanion data) {
    return Route(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      distance: data.distance.present ? data.distance.value : this.distance,
      route: data.route.present ? data.route.value : this.route,
      data: data.data.present ? data.data.value : this.data,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Route(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('distance: $distance, ')
          ..write('route: $route, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, filePath, distance, route, data);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Route &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.distance == this.distance &&
          other.route == this.route &&
          other.data == this.data);
}

class RoutesCompanion extends UpdateCompanion<Route> {
  final Value<int> id;
  final Value<String> filePath;
  final Value<double> distance;
  final Value<List<LatLng>> route;
  final Value<String> data;
  const RoutesCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.distance = const Value.absent(),
    this.route = const Value.absent(),
    this.data = const Value.absent(),
  });
  RoutesCompanion.insert({
    this.id = const Value.absent(),
    required String filePath,
    required double distance,
    required List<LatLng> route,
    required String data,
  })  : filePath = Value(filePath),
        distance = Value(distance),
        route = Value(route),
        data = Value(data);
  static Insertable<Route> custom({
    Expression<int>? id,
    Expression<String>? filePath,
    Expression<double>? distance,
    Expression<String>? route,
    Expression<String>? data,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (distance != null) 'distance': distance,
      if (route != null) 'route': route,
      if (data != null) 'data': data,
    });
  }

  RoutesCompanion copyWith(
      {Value<int>? id,
      Value<String>? filePath,
      Value<double>? distance,
      Value<List<LatLng>>? route,
      Value<String>? data}) {
    return RoutesCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      distance: distance ?? this.distance,
      route: route ?? this.route,
      data: data ?? this.data,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (route.present) {
      map['route'] =
          Variable<String>($RoutesTable.$converterroute.toSql(route.value));
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutesCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('distance: $distance, ')
          ..write('route: $route, ')
          ..write('data: $data')
          ..write(')'))
        .toString();
  }
}

class $SegmentsTable extends Segments with TableInfo<$SegmentsTable, Segment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _routeIdMeta =
      const VerificationMeta('routeId');
  @override
  late final GeneratedColumn<int> routeId = GeneratedColumn<int>(
      'route_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _historyIdMeta =
      const VerificationMeta('historyId');
  @override
  late final GeneratedColumn<int> historyId = GeneratedColumn<int>(
      'history_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bestScoreIdMeta =
      const VerificationMeta('bestScoreId');
  @override
  late final GeneratedColumn<int> bestScoreId = GeneratedColumn<int>(
      'best_score_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startIndexMeta =
      const VerificationMeta('startIndex');
  @override
  late final GeneratedColumn<int> startIndex = GeneratedColumn<int>(
      'start_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endIndexMeta =
      const VerificationMeta('endIndex');
  @override
  late final GeneratedColumn<int> endIndex = GeneratedColumn<int>(
      'end_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _matchPercentageMeta =
      const VerificationMeta('matchPercentage');
  @override
  late final GeneratedColumn<double> matchPercentage = GeneratedColumn<double>(
      'match_percentage', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        routeId,
        historyId,
        bestScoreId,
        startIndex,
        endIndex,
        matchPercentage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segments';
  @override
  VerificationContext validateIntegrity(Insertable<Segment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('route_id')) {
      context.handle(_routeIdMeta,
          routeId.isAcceptableOrUnknown(data['route_id']!, _routeIdMeta));
    } else if (isInserting) {
      context.missing(_routeIdMeta);
    }
    if (data.containsKey('history_id')) {
      context.handle(_historyIdMeta,
          historyId.isAcceptableOrUnknown(data['history_id']!, _historyIdMeta));
    } else if (isInserting) {
      context.missing(_historyIdMeta);
    }
    if (data.containsKey('best_score_id')) {
      context.handle(
          _bestScoreIdMeta,
          bestScoreId.isAcceptableOrUnknown(
              data['best_score_id']!, _bestScoreIdMeta));
    } else if (isInserting) {
      context.missing(_bestScoreIdMeta);
    }
    if (data.containsKey('start_index')) {
      context.handle(
          _startIndexMeta,
          startIndex.isAcceptableOrUnknown(
              data['start_index']!, _startIndexMeta));
    } else if (isInserting) {
      context.missing(_startIndexMeta);
    }
    if (data.containsKey('end_index')) {
      context.handle(_endIndexMeta,
          endIndex.isAcceptableOrUnknown(data['end_index']!, _endIndexMeta));
    } else if (isInserting) {
      context.missing(_endIndexMeta);
    }
    if (data.containsKey('match_percentage')) {
      context.handle(
          _matchPercentageMeta,
          matchPercentage.isAcceptableOrUnknown(
              data['match_percentage']!, _matchPercentageMeta));
    } else if (isInserting) {
      context.missing(_matchPercentageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Segment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Segment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      routeId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}route_id'])!,
      historyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}history_id'])!,
      bestScoreId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}best_score_id'])!,
      startIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_index'])!,
      endIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_index'])!,
      matchPercentage: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}match_percentage'])!,
    );
  }

  @override
  $SegmentsTable createAlias(String alias) {
    return $SegmentsTable(attachedDatabase, alias);
  }
}

class Segment extends DataClass implements Insertable<Segment> {
  final int id;
  final int routeId;
  final int historyId;
  final int bestScoreId;
  final int startIndex;
  final int endIndex;
  final double matchPercentage;
  const Segment(
      {required this.id,
      required this.routeId,
      required this.historyId,
      required this.bestScoreId,
      required this.startIndex,
      required this.endIndex,
      required this.matchPercentage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['route_id'] = Variable<int>(routeId);
    map['history_id'] = Variable<int>(historyId);
    map['best_score_id'] = Variable<int>(bestScoreId);
    map['start_index'] = Variable<int>(startIndex);
    map['end_index'] = Variable<int>(endIndex);
    map['match_percentage'] = Variable<double>(matchPercentage);
    return map;
  }

  SegmentsCompanion toCompanion(bool nullToAbsent) {
    return SegmentsCompanion(
      id: Value(id),
      routeId: Value(routeId),
      historyId: Value(historyId),
      bestScoreId: Value(bestScoreId),
      startIndex: Value(startIndex),
      endIndex: Value(endIndex),
      matchPercentage: Value(matchPercentage),
    );
  }

  factory Segment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Segment(
      id: serializer.fromJson<int>(json['id']),
      routeId: serializer.fromJson<int>(json['routeId']),
      historyId: serializer.fromJson<int>(json['historyId']),
      bestScoreId: serializer.fromJson<int>(json['bestScoreId']),
      startIndex: serializer.fromJson<int>(json['startIndex']),
      endIndex: serializer.fromJson<int>(json['endIndex']),
      matchPercentage: serializer.fromJson<double>(json['matchPercentage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'routeId': serializer.toJson<int>(routeId),
      'historyId': serializer.toJson<int>(historyId),
      'bestScoreId': serializer.toJson<int>(bestScoreId),
      'startIndex': serializer.toJson<int>(startIndex),
      'endIndex': serializer.toJson<int>(endIndex),
      'matchPercentage': serializer.toJson<double>(matchPercentage),
    };
  }

  Segment copyWith(
          {int? id,
          int? routeId,
          int? historyId,
          int? bestScoreId,
          int? startIndex,
          int? endIndex,
          double? matchPercentage}) =>
      Segment(
        id: id ?? this.id,
        routeId: routeId ?? this.routeId,
        historyId: historyId ?? this.historyId,
        bestScoreId: bestScoreId ?? this.bestScoreId,
        startIndex: startIndex ?? this.startIndex,
        endIndex: endIndex ?? this.endIndex,
        matchPercentage: matchPercentage ?? this.matchPercentage,
      );
  Segment copyWithCompanion(SegmentsCompanion data) {
    return Segment(
      id: data.id.present ? data.id.value : this.id,
      routeId: data.routeId.present ? data.routeId.value : this.routeId,
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      bestScoreId:
          data.bestScoreId.present ? data.bestScoreId.value : this.bestScoreId,
      startIndex:
          data.startIndex.present ? data.startIndex.value : this.startIndex,
      endIndex: data.endIndex.present ? data.endIndex.value : this.endIndex,
      matchPercentage: data.matchPercentage.present
          ? data.matchPercentage.value
          : this.matchPercentage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Segment(')
          ..write('id: $id, ')
          ..write('routeId: $routeId, ')
          ..write('historyId: $historyId, ')
          ..write('bestScoreId: $bestScoreId, ')
          ..write('startIndex: $startIndex, ')
          ..write('endIndex: $endIndex, ')
          ..write('matchPercentage: $matchPercentage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, routeId, historyId, bestScoreId,
      startIndex, endIndex, matchPercentage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Segment &&
          other.id == this.id &&
          other.routeId == this.routeId &&
          other.historyId == this.historyId &&
          other.bestScoreId == this.bestScoreId &&
          other.startIndex == this.startIndex &&
          other.endIndex == this.endIndex &&
          other.matchPercentage == this.matchPercentage);
}

class SegmentsCompanion extends UpdateCompanion<Segment> {
  final Value<int> id;
  final Value<int> routeId;
  final Value<int> historyId;
  final Value<int> bestScoreId;
  final Value<int> startIndex;
  final Value<int> endIndex;
  final Value<double> matchPercentage;
  const SegmentsCompanion({
    this.id = const Value.absent(),
    this.routeId = const Value.absent(),
    this.historyId = const Value.absent(),
    this.bestScoreId = const Value.absent(),
    this.startIndex = const Value.absent(),
    this.endIndex = const Value.absent(),
    this.matchPercentage = const Value.absent(),
  });
  SegmentsCompanion.insert({
    this.id = const Value.absent(),
    required int routeId,
    required int historyId,
    required int bestScoreId,
    required int startIndex,
    required int endIndex,
    required double matchPercentage,
  })  : routeId = Value(routeId),
        historyId = Value(historyId),
        bestScoreId = Value(bestScoreId),
        startIndex = Value(startIndex),
        endIndex = Value(endIndex),
        matchPercentage = Value(matchPercentage);
  static Insertable<Segment> custom({
    Expression<int>? id,
    Expression<int>? routeId,
    Expression<int>? historyId,
    Expression<int>? bestScoreId,
    Expression<int>? startIndex,
    Expression<int>? endIndex,
    Expression<double>? matchPercentage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (routeId != null) 'route_id': routeId,
      if (historyId != null) 'history_id': historyId,
      if (bestScoreId != null) 'best_score_id': bestScoreId,
      if (startIndex != null) 'start_index': startIndex,
      if (endIndex != null) 'end_index': endIndex,
      if (matchPercentage != null) 'match_percentage': matchPercentage,
    });
  }

  SegmentsCompanion copyWith(
      {Value<int>? id,
      Value<int>? routeId,
      Value<int>? historyId,
      Value<int>? bestScoreId,
      Value<int>? startIndex,
      Value<int>? endIndex,
      Value<double>? matchPercentage}) {
    return SegmentsCompanion(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      historyId: historyId ?? this.historyId,
      bestScoreId: bestScoreId ?? this.bestScoreId,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      matchPercentage: matchPercentage ?? this.matchPercentage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (routeId.present) {
      map['route_id'] = Variable<int>(routeId.value);
    }
    if (historyId.present) {
      map['history_id'] = Variable<int>(historyId.value);
    }
    if (bestScoreId.present) {
      map['best_score_id'] = Variable<int>(bestScoreId.value);
    }
    if (startIndex.present) {
      map['start_index'] = Variable<int>(startIndex.value);
    }
    if (endIndex.present) {
      map['end_index'] = Variable<int>(endIndex.value);
    }
    if (matchPercentage.present) {
      map['match_percentage'] = Variable<double>(matchPercentage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentsCompanion(')
          ..write('id: $id, ')
          ..write('routeId: $routeId, ')
          ..write('historyId: $historyId, ')
          ..write('bestScoreId: $bestScoreId, ')
          ..write('startIndex: $startIndex, ')
          ..write('endIndex: $endIndex, ')
          ..write('matchPercentage: $matchPercentage')
          ..write(')'))
        .toString();
  }
}

class $SummarysTable extends Summarys with TableInfo<$SummarysTable, Summary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SummarysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _historyIdMeta =
      const VerificationMeta('historyId');
  @override
  late final GeneratedColumn<int> historyId = GeneratedColumn<int>(
      'history_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
      'timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _sportMeta = const VerificationMeta('sport');
  @override
  late final GeneratedColumn<String> sport = GeneratedColumn<String>(
      'sport', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _maxTemperatureMeta =
      const VerificationMeta('maxTemperature');
  @override
  late final GeneratedColumn<double> maxTemperature = GeneratedColumn<double>(
      'max_temperature', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgTemperatureMeta =
      const VerificationMeta('avgTemperature');
  @override
  late final GeneratedColumn<double> avgTemperature = GeneratedColumn<double>(
      'avg_temperature', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalAscentMeta =
      const VerificationMeta('totalAscent');
  @override
  late final GeneratedColumn<double> totalAscent = GeneratedColumn<double>(
      'total_ascent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalDescentMeta =
      const VerificationMeta('totalDescent');
  @override
  late final GeneratedColumn<double> totalDescent = GeneratedColumn<double>(
      'total_descent', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalDistanceMeta =
      const VerificationMeta('totalDistance');
  @override
  late final GeneratedColumn<double> totalDistance = GeneratedColumn<double>(
      'total_distance', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalElapsedTimeMeta =
      const VerificationMeta('totalElapsedTime');
  @override
  late final GeneratedColumn<double> totalElapsedTime = GeneratedColumn<double>(
      'total_elapsed_time', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalTimerTimeMeta =
      const VerificationMeta('totalTimerTime');
  @override
  late final GeneratedColumn<double> totalTimerTime = GeneratedColumn<double>(
      'total_timer_time', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalMovingTimeMeta =
      const VerificationMeta('totalMovingTime');
  @override
  late final GeneratedColumn<double> totalMovingTime = GeneratedColumn<double>(
      'total_moving_time', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalCaloriesMeta =
      const VerificationMeta('totalCalories');
  @override
  late final GeneratedColumn<double> totalCalories = GeneratedColumn<double>(
      'total_calories', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _totalWorkMeta =
      const VerificationMeta('totalWork');
  @override
  late final GeneratedColumn<double> totalWork = GeneratedColumn<double>(
      'total_work', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxPowerMeta =
      const VerificationMeta('maxPower');
  @override
  late final GeneratedColumn<double> maxPower = GeneratedColumn<double>(
      'max_power', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _enhancedMaxSpeedMeta =
      const VerificationMeta('enhancedMaxSpeed');
  @override
  late final GeneratedColumn<double> enhancedMaxSpeed = GeneratedColumn<double>(
      'enhanced_max_speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxSpeedMeta =
      const VerificationMeta('maxSpeed');
  @override
  late final GeneratedColumn<double> maxSpeed = GeneratedColumn<double>(
      'max_speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxCadenceMeta =
      const VerificationMeta('maxCadence');
  @override
  late final GeneratedColumn<double> maxCadence = GeneratedColumn<double>(
      'max_cadence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxHeartRateMeta =
      const VerificationMeta('maxHeartRate');
  @override
  late final GeneratedColumn<double> maxHeartRate = GeneratedColumn<double>(
      'max_heart_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgPowerMeta =
      const VerificationMeta('avgPower');
  @override
  late final GeneratedColumn<double> avgPower = GeneratedColumn<double>(
      'avg_power', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _enhancedAvgSpeedMeta =
      const VerificationMeta('enhancedAvgSpeed');
  @override
  late final GeneratedColumn<double> enhancedAvgSpeed = GeneratedColumn<double>(
      'enhanced_avg_speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgSpeedMeta =
      const VerificationMeta('avgSpeed');
  @override
  late final GeneratedColumn<double> avgSpeed = GeneratedColumn<double>(
      'avg_speed', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgCadenceMeta =
      const VerificationMeta('avgCadence');
  @override
  late final GeneratedColumn<double> avgCadence = GeneratedColumn<double>(
      'avg_cadence', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgHeartRateMeta =
      const VerificationMeta('avgHeartRate');
  @override
  late final GeneratedColumn<double> avgHeartRate = GeneratedColumn<double>(
      'avg_heart_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _enhancedAvgAltitudeMeta =
      const VerificationMeta('enhancedAvgAltitude');
  @override
  late final GeneratedColumn<double> enhancedAvgAltitude =
      GeneratedColumn<double>('enhanced_avg_altitude', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgAltitudeMeta =
      const VerificationMeta('avgAltitude');
  @override
  late final GeneratedColumn<double> avgAltitude = GeneratedColumn<double>(
      'avg_altitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _enhancedMaxAltitudeMeta =
      const VerificationMeta('enhancedMaxAltitude');
  @override
  late final GeneratedColumn<double> enhancedMaxAltitude =
      GeneratedColumn<double>('enhanced_max_altitude', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxAltitudeMeta =
      const VerificationMeta('maxAltitude');
  @override
  late final GeneratedColumn<double> maxAltitude = GeneratedColumn<double>(
      'max_altitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _avgGradeMeta =
      const VerificationMeta('avgGrade');
  @override
  late final GeneratedColumn<double> avgGrade = GeneratedColumn<double>(
      'avg_grade', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _thresholdPowerMeta =
      const VerificationMeta('thresholdPower');
  @override
  late final GeneratedColumn<double> thresholdPower = GeneratedColumn<double>(
      'threshold_power', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        historyId,
        timestamp,
        startTime,
        sport,
        maxTemperature,
        avgTemperature,
        totalAscent,
        totalDescent,
        totalDistance,
        totalElapsedTime,
        totalTimerTime,
        totalMovingTime,
        totalCalories,
        totalWork,
        maxPower,
        enhancedMaxSpeed,
        maxSpeed,
        maxCadence,
        maxHeartRate,
        avgPower,
        enhancedAvgSpeed,
        avgSpeed,
        avgCadence,
        avgHeartRate,
        enhancedAvgAltitude,
        avgAltitude,
        enhancedMaxAltitude,
        maxAltitude,
        avgGrade,
        thresholdPower
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'summarys';
  @override
  VerificationContext validateIntegrity(Insertable<Summary> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('history_id')) {
      context.handle(_historyIdMeta,
          historyId.isAcceptableOrUnknown(data['history_id']!, _historyIdMeta));
    } else if (isInserting) {
      context.missing(_historyIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    }
    if (data.containsKey('sport')) {
      context.handle(
          _sportMeta, sport.isAcceptableOrUnknown(data['sport']!, _sportMeta));
    }
    if (data.containsKey('max_temperature')) {
      context.handle(
          _maxTemperatureMeta,
          maxTemperature.isAcceptableOrUnknown(
              data['max_temperature']!, _maxTemperatureMeta));
    }
    if (data.containsKey('avg_temperature')) {
      context.handle(
          _avgTemperatureMeta,
          avgTemperature.isAcceptableOrUnknown(
              data['avg_temperature']!, _avgTemperatureMeta));
    }
    if (data.containsKey('total_ascent')) {
      context.handle(
          _totalAscentMeta,
          totalAscent.isAcceptableOrUnknown(
              data['total_ascent']!, _totalAscentMeta));
    }
    if (data.containsKey('total_descent')) {
      context.handle(
          _totalDescentMeta,
          totalDescent.isAcceptableOrUnknown(
              data['total_descent']!, _totalDescentMeta));
    }
    if (data.containsKey('total_distance')) {
      context.handle(
          _totalDistanceMeta,
          totalDistance.isAcceptableOrUnknown(
              data['total_distance']!, _totalDistanceMeta));
    }
    if (data.containsKey('total_elapsed_time')) {
      context.handle(
          _totalElapsedTimeMeta,
          totalElapsedTime.isAcceptableOrUnknown(
              data['total_elapsed_time']!, _totalElapsedTimeMeta));
    }
    if (data.containsKey('total_timer_time')) {
      context.handle(
          _totalTimerTimeMeta,
          totalTimerTime.isAcceptableOrUnknown(
              data['total_timer_time']!, _totalTimerTimeMeta));
    }
    if (data.containsKey('total_moving_time')) {
      context.handle(
          _totalMovingTimeMeta,
          totalMovingTime.isAcceptableOrUnknown(
              data['total_moving_time']!, _totalMovingTimeMeta));
    }
    if (data.containsKey('total_calories')) {
      context.handle(
          _totalCaloriesMeta,
          totalCalories.isAcceptableOrUnknown(
              data['total_calories']!, _totalCaloriesMeta));
    }
    if (data.containsKey('total_work')) {
      context.handle(_totalWorkMeta,
          totalWork.isAcceptableOrUnknown(data['total_work']!, _totalWorkMeta));
    }
    if (data.containsKey('max_power')) {
      context.handle(_maxPowerMeta,
          maxPower.isAcceptableOrUnknown(data['max_power']!, _maxPowerMeta));
    }
    if (data.containsKey('enhanced_max_speed')) {
      context.handle(
          _enhancedMaxSpeedMeta,
          enhancedMaxSpeed.isAcceptableOrUnknown(
              data['enhanced_max_speed']!, _enhancedMaxSpeedMeta));
    }
    if (data.containsKey('max_speed')) {
      context.handle(_maxSpeedMeta,
          maxSpeed.isAcceptableOrUnknown(data['max_speed']!, _maxSpeedMeta));
    }
    if (data.containsKey('max_cadence')) {
      context.handle(
          _maxCadenceMeta,
          maxCadence.isAcceptableOrUnknown(
              data['max_cadence']!, _maxCadenceMeta));
    }
    if (data.containsKey('max_heart_rate')) {
      context.handle(
          _maxHeartRateMeta,
          maxHeartRate.isAcceptableOrUnknown(
              data['max_heart_rate']!, _maxHeartRateMeta));
    }
    if (data.containsKey('avg_power')) {
      context.handle(_avgPowerMeta,
          avgPower.isAcceptableOrUnknown(data['avg_power']!, _avgPowerMeta));
    }
    if (data.containsKey('enhanced_avg_speed')) {
      context.handle(
          _enhancedAvgSpeedMeta,
          enhancedAvgSpeed.isAcceptableOrUnknown(
              data['enhanced_avg_speed']!, _enhancedAvgSpeedMeta));
    }
    if (data.containsKey('avg_speed')) {
      context.handle(_avgSpeedMeta,
          avgSpeed.isAcceptableOrUnknown(data['avg_speed']!, _avgSpeedMeta));
    }
    if (data.containsKey('avg_cadence')) {
      context.handle(
          _avgCadenceMeta,
          avgCadence.isAcceptableOrUnknown(
              data['avg_cadence']!, _avgCadenceMeta));
    }
    if (data.containsKey('avg_heart_rate')) {
      context.handle(
          _avgHeartRateMeta,
          avgHeartRate.isAcceptableOrUnknown(
              data['avg_heart_rate']!, _avgHeartRateMeta));
    }
    if (data.containsKey('enhanced_avg_altitude')) {
      context.handle(
          _enhancedAvgAltitudeMeta,
          enhancedAvgAltitude.isAcceptableOrUnknown(
              data['enhanced_avg_altitude']!, _enhancedAvgAltitudeMeta));
    }
    if (data.containsKey('avg_altitude')) {
      context.handle(
          _avgAltitudeMeta,
          avgAltitude.isAcceptableOrUnknown(
              data['avg_altitude']!, _avgAltitudeMeta));
    }
    if (data.containsKey('enhanced_max_altitude')) {
      context.handle(
          _enhancedMaxAltitudeMeta,
          enhancedMaxAltitude.isAcceptableOrUnknown(
              data['enhanced_max_altitude']!, _enhancedMaxAltitudeMeta));
    }
    if (data.containsKey('max_altitude')) {
      context.handle(
          _maxAltitudeMeta,
          maxAltitude.isAcceptableOrUnknown(
              data['max_altitude']!, _maxAltitudeMeta));
    }
    if (data.containsKey('avg_grade')) {
      context.handle(_avgGradeMeta,
          avgGrade.isAcceptableOrUnknown(data['avg_grade']!, _avgGradeMeta));
    }
    if (data.containsKey('threshold_power')) {
      context.handle(
          _thresholdPowerMeta,
          thresholdPower.isAcceptableOrUnknown(
              data['threshold_power']!, _thresholdPowerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Summary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Summary(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      historyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}history_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp']),
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time']),
      sport: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sport']),
      maxTemperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_temperature']),
      avgTemperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_temperature']),
      totalAscent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_ascent']),
      totalDescent: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_descent']),
      totalDistance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_distance']),
      totalElapsedTime: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_elapsed_time']),
      totalTimerTime: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_timer_time']),
      totalMovingTime: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}total_moving_time']),
      totalCalories: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_calories']),
      totalWork: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_work']),
      maxPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_power']),
      enhancedMaxSpeed: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}enhanced_max_speed']),
      maxSpeed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_speed']),
      maxCadence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_cadence']),
      maxHeartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_heart_rate']),
      avgPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_power']),
      enhancedAvgSpeed: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}enhanced_avg_speed']),
      avgSpeed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_speed']),
      avgCadence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_cadence']),
      avgHeartRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_heart_rate']),
      enhancedAvgAltitude: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}enhanced_avg_altitude']),
      avgAltitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_altitude']),
      enhancedMaxAltitude: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}enhanced_max_altitude']),
      maxAltitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_altitude']),
      avgGrade: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_grade']),
      thresholdPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}threshold_power']),
    );
  }

  @override
  $SummarysTable createAlias(String alias) {
    return $SummarysTable(attachedDatabase, alias);
  }
}

class Summary extends DataClass implements Insertable<Summary> {
  final int id;
  final int historyId;
  final int? timestamp;
  final DateTime? startTime;
  final String? sport;
  final double? maxTemperature;
  final double? avgTemperature;
  final double? totalAscent;
  final double? totalDescent;
  final double? totalDistance;
  final double? totalElapsedTime;
  final double? totalTimerTime;
  final double? totalMovingTime;
  final double? totalCalories;
  final double? totalWork;
  final double? maxPower;
  final double? enhancedMaxSpeed;
  final double? maxSpeed;
  final double? maxCadence;
  final double? maxHeartRate;
  final double? avgPower;
  final double? enhancedAvgSpeed;
  final double? avgSpeed;
  final double? avgCadence;
  final double? avgHeartRate;
  final double? enhancedAvgAltitude;
  final double? avgAltitude;
  final double? enhancedMaxAltitude;
  final double? maxAltitude;
  final double? avgGrade;
  final double? thresholdPower;
  const Summary(
      {required this.id,
      required this.historyId,
      this.timestamp,
      this.startTime,
      this.sport,
      this.maxTemperature,
      this.avgTemperature,
      this.totalAscent,
      this.totalDescent,
      this.totalDistance,
      this.totalElapsedTime,
      this.totalTimerTime,
      this.totalMovingTime,
      this.totalCalories,
      this.totalWork,
      this.maxPower,
      this.enhancedMaxSpeed,
      this.maxSpeed,
      this.maxCadence,
      this.maxHeartRate,
      this.avgPower,
      this.enhancedAvgSpeed,
      this.avgSpeed,
      this.avgCadence,
      this.avgHeartRate,
      this.enhancedAvgAltitude,
      this.avgAltitude,
      this.enhancedMaxAltitude,
      this.maxAltitude,
      this.avgGrade,
      this.thresholdPower});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['history_id'] = Variable<int>(historyId);
    if (!nullToAbsent || timestamp != null) {
      map['timestamp'] = Variable<int>(timestamp);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<DateTime>(startTime);
    }
    if (!nullToAbsent || sport != null) {
      map['sport'] = Variable<String>(sport);
    }
    if (!nullToAbsent || maxTemperature != null) {
      map['max_temperature'] = Variable<double>(maxTemperature);
    }
    if (!nullToAbsent || avgTemperature != null) {
      map['avg_temperature'] = Variable<double>(avgTemperature);
    }
    if (!nullToAbsent || totalAscent != null) {
      map['total_ascent'] = Variable<double>(totalAscent);
    }
    if (!nullToAbsent || totalDescent != null) {
      map['total_descent'] = Variable<double>(totalDescent);
    }
    if (!nullToAbsent || totalDistance != null) {
      map['total_distance'] = Variable<double>(totalDistance);
    }
    if (!nullToAbsent || totalElapsedTime != null) {
      map['total_elapsed_time'] = Variable<double>(totalElapsedTime);
    }
    if (!nullToAbsent || totalTimerTime != null) {
      map['total_timer_time'] = Variable<double>(totalTimerTime);
    }
    if (!nullToAbsent || totalMovingTime != null) {
      map['total_moving_time'] = Variable<double>(totalMovingTime);
    }
    if (!nullToAbsent || totalCalories != null) {
      map['total_calories'] = Variable<double>(totalCalories);
    }
    if (!nullToAbsent || totalWork != null) {
      map['total_work'] = Variable<double>(totalWork);
    }
    if (!nullToAbsent || maxPower != null) {
      map['max_power'] = Variable<double>(maxPower);
    }
    if (!nullToAbsent || enhancedMaxSpeed != null) {
      map['enhanced_max_speed'] = Variable<double>(enhancedMaxSpeed);
    }
    if (!nullToAbsent || maxSpeed != null) {
      map['max_speed'] = Variable<double>(maxSpeed);
    }
    if (!nullToAbsent || maxCadence != null) {
      map['max_cadence'] = Variable<double>(maxCadence);
    }
    if (!nullToAbsent || maxHeartRate != null) {
      map['max_heart_rate'] = Variable<double>(maxHeartRate);
    }
    if (!nullToAbsent || avgPower != null) {
      map['avg_power'] = Variable<double>(avgPower);
    }
    if (!nullToAbsent || enhancedAvgSpeed != null) {
      map['enhanced_avg_speed'] = Variable<double>(enhancedAvgSpeed);
    }
    if (!nullToAbsent || avgSpeed != null) {
      map['avg_speed'] = Variable<double>(avgSpeed);
    }
    if (!nullToAbsent || avgCadence != null) {
      map['avg_cadence'] = Variable<double>(avgCadence);
    }
    if (!nullToAbsent || avgHeartRate != null) {
      map['avg_heart_rate'] = Variable<double>(avgHeartRate);
    }
    if (!nullToAbsent || enhancedAvgAltitude != null) {
      map['enhanced_avg_altitude'] = Variable<double>(enhancedAvgAltitude);
    }
    if (!nullToAbsent || avgAltitude != null) {
      map['avg_altitude'] = Variable<double>(avgAltitude);
    }
    if (!nullToAbsent || enhancedMaxAltitude != null) {
      map['enhanced_max_altitude'] = Variable<double>(enhancedMaxAltitude);
    }
    if (!nullToAbsent || maxAltitude != null) {
      map['max_altitude'] = Variable<double>(maxAltitude);
    }
    if (!nullToAbsent || avgGrade != null) {
      map['avg_grade'] = Variable<double>(avgGrade);
    }
    if (!nullToAbsent || thresholdPower != null) {
      map['threshold_power'] = Variable<double>(thresholdPower);
    }
    return map;
  }

  SummarysCompanion toCompanion(bool nullToAbsent) {
    return SummarysCompanion(
      id: Value(id),
      historyId: Value(historyId),
      timestamp: timestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(timestamp),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      sport:
          sport == null && nullToAbsent ? const Value.absent() : Value(sport),
      maxTemperature: maxTemperature == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTemperature),
      avgTemperature: avgTemperature == null && nullToAbsent
          ? const Value.absent()
          : Value(avgTemperature),
      totalAscent: totalAscent == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAscent),
      totalDescent: totalDescent == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDescent),
      totalDistance: totalDistance == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDistance),
      totalElapsedTime: totalElapsedTime == null && nullToAbsent
          ? const Value.absent()
          : Value(totalElapsedTime),
      totalTimerTime: totalTimerTime == null && nullToAbsent
          ? const Value.absent()
          : Value(totalTimerTime),
      totalMovingTime: totalMovingTime == null && nullToAbsent
          ? const Value.absent()
          : Value(totalMovingTime),
      totalCalories: totalCalories == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCalories),
      totalWork: totalWork == null && nullToAbsent
          ? const Value.absent()
          : Value(totalWork),
      maxPower: maxPower == null && nullToAbsent
          ? const Value.absent()
          : Value(maxPower),
      enhancedMaxSpeed: enhancedMaxSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(enhancedMaxSpeed),
      maxSpeed: maxSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(maxSpeed),
      maxCadence: maxCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(maxCadence),
      maxHeartRate: maxHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(maxHeartRate),
      avgPower: avgPower == null && nullToAbsent
          ? const Value.absent()
          : Value(avgPower),
      enhancedAvgSpeed: enhancedAvgSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(enhancedAvgSpeed),
      avgSpeed: avgSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(avgSpeed),
      avgCadence: avgCadence == null && nullToAbsent
          ? const Value.absent()
          : Value(avgCadence),
      avgHeartRate: avgHeartRate == null && nullToAbsent
          ? const Value.absent()
          : Value(avgHeartRate),
      enhancedAvgAltitude: enhancedAvgAltitude == null && nullToAbsent
          ? const Value.absent()
          : Value(enhancedAvgAltitude),
      avgAltitude: avgAltitude == null && nullToAbsent
          ? const Value.absent()
          : Value(avgAltitude),
      enhancedMaxAltitude: enhancedMaxAltitude == null && nullToAbsent
          ? const Value.absent()
          : Value(enhancedMaxAltitude),
      maxAltitude: maxAltitude == null && nullToAbsent
          ? const Value.absent()
          : Value(maxAltitude),
      avgGrade: avgGrade == null && nullToAbsent
          ? const Value.absent()
          : Value(avgGrade),
      thresholdPower: thresholdPower == null && nullToAbsent
          ? const Value.absent()
          : Value(thresholdPower),
    );
  }

  factory Summary.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Summary(
      id: serializer.fromJson<int>(json['id']),
      historyId: serializer.fromJson<int>(json['historyId']),
      timestamp: serializer.fromJson<int?>(json['timestamp']),
      startTime: serializer.fromJson<DateTime?>(json['startTime']),
      sport: serializer.fromJson<String?>(json['sport']),
      maxTemperature: serializer.fromJson<double?>(json['maxTemperature']),
      avgTemperature: serializer.fromJson<double?>(json['avgTemperature']),
      totalAscent: serializer.fromJson<double?>(json['totalAscent']),
      totalDescent: serializer.fromJson<double?>(json['totalDescent']),
      totalDistance: serializer.fromJson<double?>(json['totalDistance']),
      totalElapsedTime: serializer.fromJson<double?>(json['totalElapsedTime']),
      totalTimerTime: serializer.fromJson<double?>(json['totalTimerTime']),
      totalMovingTime: serializer.fromJson<double?>(json['totalMovingTime']),
      totalCalories: serializer.fromJson<double?>(json['totalCalories']),
      totalWork: serializer.fromJson<double?>(json['totalWork']),
      maxPower: serializer.fromJson<double?>(json['maxPower']),
      enhancedMaxSpeed: serializer.fromJson<double?>(json['enhancedMaxSpeed']),
      maxSpeed: serializer.fromJson<double?>(json['maxSpeed']),
      maxCadence: serializer.fromJson<double?>(json['maxCadence']),
      maxHeartRate: serializer.fromJson<double?>(json['maxHeartRate']),
      avgPower: serializer.fromJson<double?>(json['avgPower']),
      enhancedAvgSpeed: serializer.fromJson<double?>(json['enhancedAvgSpeed']),
      avgSpeed: serializer.fromJson<double?>(json['avgSpeed']),
      avgCadence: serializer.fromJson<double?>(json['avgCadence']),
      avgHeartRate: serializer.fromJson<double?>(json['avgHeartRate']),
      enhancedAvgAltitude:
          serializer.fromJson<double?>(json['enhancedAvgAltitude']),
      avgAltitude: serializer.fromJson<double?>(json['avgAltitude']),
      enhancedMaxAltitude:
          serializer.fromJson<double?>(json['enhancedMaxAltitude']),
      maxAltitude: serializer.fromJson<double?>(json['maxAltitude']),
      avgGrade: serializer.fromJson<double?>(json['avgGrade']),
      thresholdPower: serializer.fromJson<double?>(json['thresholdPower']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'historyId': serializer.toJson<int>(historyId),
      'timestamp': serializer.toJson<int?>(timestamp),
      'startTime': serializer.toJson<DateTime?>(startTime),
      'sport': serializer.toJson<String?>(sport),
      'maxTemperature': serializer.toJson<double?>(maxTemperature),
      'avgTemperature': serializer.toJson<double?>(avgTemperature),
      'totalAscent': serializer.toJson<double?>(totalAscent),
      'totalDescent': serializer.toJson<double?>(totalDescent),
      'totalDistance': serializer.toJson<double?>(totalDistance),
      'totalElapsedTime': serializer.toJson<double?>(totalElapsedTime),
      'totalTimerTime': serializer.toJson<double?>(totalTimerTime),
      'totalMovingTime': serializer.toJson<double?>(totalMovingTime),
      'totalCalories': serializer.toJson<double?>(totalCalories),
      'totalWork': serializer.toJson<double?>(totalWork),
      'maxPower': serializer.toJson<double?>(maxPower),
      'enhancedMaxSpeed': serializer.toJson<double?>(enhancedMaxSpeed),
      'maxSpeed': serializer.toJson<double?>(maxSpeed),
      'maxCadence': serializer.toJson<double?>(maxCadence),
      'maxHeartRate': serializer.toJson<double?>(maxHeartRate),
      'avgPower': serializer.toJson<double?>(avgPower),
      'enhancedAvgSpeed': serializer.toJson<double?>(enhancedAvgSpeed),
      'avgSpeed': serializer.toJson<double?>(avgSpeed),
      'avgCadence': serializer.toJson<double?>(avgCadence),
      'avgHeartRate': serializer.toJson<double?>(avgHeartRate),
      'enhancedAvgAltitude': serializer.toJson<double?>(enhancedAvgAltitude),
      'avgAltitude': serializer.toJson<double?>(avgAltitude),
      'enhancedMaxAltitude': serializer.toJson<double?>(enhancedMaxAltitude),
      'maxAltitude': serializer.toJson<double?>(maxAltitude),
      'avgGrade': serializer.toJson<double?>(avgGrade),
      'thresholdPower': serializer.toJson<double?>(thresholdPower),
    };
  }

  Summary copyWith(
          {int? id,
          int? historyId,
          Value<int?> timestamp = const Value.absent(),
          Value<DateTime?> startTime = const Value.absent(),
          Value<String?> sport = const Value.absent(),
          Value<double?> maxTemperature = const Value.absent(),
          Value<double?> avgTemperature = const Value.absent(),
          Value<double?> totalAscent = const Value.absent(),
          Value<double?> totalDescent = const Value.absent(),
          Value<double?> totalDistance = const Value.absent(),
          Value<double?> totalElapsedTime = const Value.absent(),
          Value<double?> totalTimerTime = const Value.absent(),
          Value<double?> totalMovingTime = const Value.absent(),
          Value<double?> totalCalories = const Value.absent(),
          Value<double?> totalWork = const Value.absent(),
          Value<double?> maxPower = const Value.absent(),
          Value<double?> enhancedMaxSpeed = const Value.absent(),
          Value<double?> maxSpeed = const Value.absent(),
          Value<double?> maxCadence = const Value.absent(),
          Value<double?> maxHeartRate = const Value.absent(),
          Value<double?> avgPower = const Value.absent(),
          Value<double?> enhancedAvgSpeed = const Value.absent(),
          Value<double?> avgSpeed = const Value.absent(),
          Value<double?> avgCadence = const Value.absent(),
          Value<double?> avgHeartRate = const Value.absent(),
          Value<double?> enhancedAvgAltitude = const Value.absent(),
          Value<double?> avgAltitude = const Value.absent(),
          Value<double?> enhancedMaxAltitude = const Value.absent(),
          Value<double?> maxAltitude = const Value.absent(),
          Value<double?> avgGrade = const Value.absent(),
          Value<double?> thresholdPower = const Value.absent()}) =>
      Summary(
        id: id ?? this.id,
        historyId: historyId ?? this.historyId,
        timestamp: timestamp.present ? timestamp.value : this.timestamp,
        startTime: startTime.present ? startTime.value : this.startTime,
        sport: sport.present ? sport.value : this.sport,
        maxTemperature:
            maxTemperature.present ? maxTemperature.value : this.maxTemperature,
        avgTemperature:
            avgTemperature.present ? avgTemperature.value : this.avgTemperature,
        totalAscent: totalAscent.present ? totalAscent.value : this.totalAscent,
        totalDescent:
            totalDescent.present ? totalDescent.value : this.totalDescent,
        totalDistance:
            totalDistance.present ? totalDistance.value : this.totalDistance,
        totalElapsedTime: totalElapsedTime.present
            ? totalElapsedTime.value
            : this.totalElapsedTime,
        totalTimerTime:
            totalTimerTime.present ? totalTimerTime.value : this.totalTimerTime,
        totalMovingTime: totalMovingTime.present
            ? totalMovingTime.value
            : this.totalMovingTime,
        totalCalories:
            totalCalories.present ? totalCalories.value : this.totalCalories,
        totalWork: totalWork.present ? totalWork.value : this.totalWork,
        maxPower: maxPower.present ? maxPower.value : this.maxPower,
        enhancedMaxSpeed: enhancedMaxSpeed.present
            ? enhancedMaxSpeed.value
            : this.enhancedMaxSpeed,
        maxSpeed: maxSpeed.present ? maxSpeed.value : this.maxSpeed,
        maxCadence: maxCadence.present ? maxCadence.value : this.maxCadence,
        maxHeartRate:
            maxHeartRate.present ? maxHeartRate.value : this.maxHeartRate,
        avgPower: avgPower.present ? avgPower.value : this.avgPower,
        enhancedAvgSpeed: enhancedAvgSpeed.present
            ? enhancedAvgSpeed.value
            : this.enhancedAvgSpeed,
        avgSpeed: avgSpeed.present ? avgSpeed.value : this.avgSpeed,
        avgCadence: avgCadence.present ? avgCadence.value : this.avgCadence,
        avgHeartRate:
            avgHeartRate.present ? avgHeartRate.value : this.avgHeartRate,
        enhancedAvgAltitude: enhancedAvgAltitude.present
            ? enhancedAvgAltitude.value
            : this.enhancedAvgAltitude,
        avgAltitude: avgAltitude.present ? avgAltitude.value : this.avgAltitude,
        enhancedMaxAltitude: enhancedMaxAltitude.present
            ? enhancedMaxAltitude.value
            : this.enhancedMaxAltitude,
        maxAltitude: maxAltitude.present ? maxAltitude.value : this.maxAltitude,
        avgGrade: avgGrade.present ? avgGrade.value : this.avgGrade,
        thresholdPower:
            thresholdPower.present ? thresholdPower.value : this.thresholdPower,
      );
  Summary copyWithCompanion(SummarysCompanion data) {
    return Summary(
      id: data.id.present ? data.id.value : this.id,
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      sport: data.sport.present ? data.sport.value : this.sport,
      maxTemperature: data.maxTemperature.present
          ? data.maxTemperature.value
          : this.maxTemperature,
      avgTemperature: data.avgTemperature.present
          ? data.avgTemperature.value
          : this.avgTemperature,
      totalAscent:
          data.totalAscent.present ? data.totalAscent.value : this.totalAscent,
      totalDescent: data.totalDescent.present
          ? data.totalDescent.value
          : this.totalDescent,
      totalDistance: data.totalDistance.present
          ? data.totalDistance.value
          : this.totalDistance,
      totalElapsedTime: data.totalElapsedTime.present
          ? data.totalElapsedTime.value
          : this.totalElapsedTime,
      totalTimerTime: data.totalTimerTime.present
          ? data.totalTimerTime.value
          : this.totalTimerTime,
      totalMovingTime: data.totalMovingTime.present
          ? data.totalMovingTime.value
          : this.totalMovingTime,
      totalCalories: data.totalCalories.present
          ? data.totalCalories.value
          : this.totalCalories,
      totalWork: data.totalWork.present ? data.totalWork.value : this.totalWork,
      maxPower: data.maxPower.present ? data.maxPower.value : this.maxPower,
      enhancedMaxSpeed: data.enhancedMaxSpeed.present
          ? data.enhancedMaxSpeed.value
          : this.enhancedMaxSpeed,
      maxSpeed: data.maxSpeed.present ? data.maxSpeed.value : this.maxSpeed,
      maxCadence:
          data.maxCadence.present ? data.maxCadence.value : this.maxCadence,
      maxHeartRate: data.maxHeartRate.present
          ? data.maxHeartRate.value
          : this.maxHeartRate,
      avgPower: data.avgPower.present ? data.avgPower.value : this.avgPower,
      enhancedAvgSpeed: data.enhancedAvgSpeed.present
          ? data.enhancedAvgSpeed.value
          : this.enhancedAvgSpeed,
      avgSpeed: data.avgSpeed.present ? data.avgSpeed.value : this.avgSpeed,
      avgCadence:
          data.avgCadence.present ? data.avgCadence.value : this.avgCadence,
      avgHeartRate: data.avgHeartRate.present
          ? data.avgHeartRate.value
          : this.avgHeartRate,
      enhancedAvgAltitude: data.enhancedAvgAltitude.present
          ? data.enhancedAvgAltitude.value
          : this.enhancedAvgAltitude,
      avgAltitude:
          data.avgAltitude.present ? data.avgAltitude.value : this.avgAltitude,
      enhancedMaxAltitude: data.enhancedMaxAltitude.present
          ? data.enhancedMaxAltitude.value
          : this.enhancedMaxAltitude,
      maxAltitude:
          data.maxAltitude.present ? data.maxAltitude.value : this.maxAltitude,
      avgGrade: data.avgGrade.present ? data.avgGrade.value : this.avgGrade,
      thresholdPower: data.thresholdPower.present
          ? data.thresholdPower.value
          : this.thresholdPower,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Summary(')
          ..write('id: $id, ')
          ..write('historyId: $historyId, ')
          ..write('timestamp: $timestamp, ')
          ..write('startTime: $startTime, ')
          ..write('sport: $sport, ')
          ..write('maxTemperature: $maxTemperature, ')
          ..write('avgTemperature: $avgTemperature, ')
          ..write('totalAscent: $totalAscent, ')
          ..write('totalDescent: $totalDescent, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('totalElapsedTime: $totalElapsedTime, ')
          ..write('totalTimerTime: $totalTimerTime, ')
          ..write('totalMovingTime: $totalMovingTime, ')
          ..write('totalCalories: $totalCalories, ')
          ..write('totalWork: $totalWork, ')
          ..write('maxPower: $maxPower, ')
          ..write('enhancedMaxSpeed: $enhancedMaxSpeed, ')
          ..write('maxSpeed: $maxSpeed, ')
          ..write('maxCadence: $maxCadence, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgPower: $avgPower, ')
          ..write('enhancedAvgSpeed: $enhancedAvgSpeed, ')
          ..write('avgSpeed: $avgSpeed, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('enhancedAvgAltitude: $enhancedAvgAltitude, ')
          ..write('avgAltitude: $avgAltitude, ')
          ..write('enhancedMaxAltitude: $enhancedMaxAltitude, ')
          ..write('maxAltitude: $maxAltitude, ')
          ..write('avgGrade: $avgGrade, ')
          ..write('thresholdPower: $thresholdPower')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        historyId,
        timestamp,
        startTime,
        sport,
        maxTemperature,
        avgTemperature,
        totalAscent,
        totalDescent,
        totalDistance,
        totalElapsedTime,
        totalTimerTime,
        totalMovingTime,
        totalCalories,
        totalWork,
        maxPower,
        enhancedMaxSpeed,
        maxSpeed,
        maxCadence,
        maxHeartRate,
        avgPower,
        enhancedAvgSpeed,
        avgSpeed,
        avgCadence,
        avgHeartRate,
        enhancedAvgAltitude,
        avgAltitude,
        enhancedMaxAltitude,
        maxAltitude,
        avgGrade,
        thresholdPower
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Summary &&
          other.id == this.id &&
          other.historyId == this.historyId &&
          other.timestamp == this.timestamp &&
          other.startTime == this.startTime &&
          other.sport == this.sport &&
          other.maxTemperature == this.maxTemperature &&
          other.avgTemperature == this.avgTemperature &&
          other.totalAscent == this.totalAscent &&
          other.totalDescent == this.totalDescent &&
          other.totalDistance == this.totalDistance &&
          other.totalElapsedTime == this.totalElapsedTime &&
          other.totalTimerTime == this.totalTimerTime &&
          other.totalMovingTime == this.totalMovingTime &&
          other.totalCalories == this.totalCalories &&
          other.totalWork == this.totalWork &&
          other.maxPower == this.maxPower &&
          other.enhancedMaxSpeed == this.enhancedMaxSpeed &&
          other.maxSpeed == this.maxSpeed &&
          other.maxCadence == this.maxCadence &&
          other.maxHeartRate == this.maxHeartRate &&
          other.avgPower == this.avgPower &&
          other.enhancedAvgSpeed == this.enhancedAvgSpeed &&
          other.avgSpeed == this.avgSpeed &&
          other.avgCadence == this.avgCadence &&
          other.avgHeartRate == this.avgHeartRate &&
          other.enhancedAvgAltitude == this.enhancedAvgAltitude &&
          other.avgAltitude == this.avgAltitude &&
          other.enhancedMaxAltitude == this.enhancedMaxAltitude &&
          other.maxAltitude == this.maxAltitude &&
          other.avgGrade == this.avgGrade &&
          other.thresholdPower == this.thresholdPower);
}

class SummarysCompanion extends UpdateCompanion<Summary> {
  final Value<int> id;
  final Value<int> historyId;
  final Value<int?> timestamp;
  final Value<DateTime?> startTime;
  final Value<String?> sport;
  final Value<double?> maxTemperature;
  final Value<double?> avgTemperature;
  final Value<double?> totalAscent;
  final Value<double?> totalDescent;
  final Value<double?> totalDistance;
  final Value<double?> totalElapsedTime;
  final Value<double?> totalTimerTime;
  final Value<double?> totalMovingTime;
  final Value<double?> totalCalories;
  final Value<double?> totalWork;
  final Value<double?> maxPower;
  final Value<double?> enhancedMaxSpeed;
  final Value<double?> maxSpeed;
  final Value<double?> maxCadence;
  final Value<double?> maxHeartRate;
  final Value<double?> avgPower;
  final Value<double?> enhancedAvgSpeed;
  final Value<double?> avgSpeed;
  final Value<double?> avgCadence;
  final Value<double?> avgHeartRate;
  final Value<double?> enhancedAvgAltitude;
  final Value<double?> avgAltitude;
  final Value<double?> enhancedMaxAltitude;
  final Value<double?> maxAltitude;
  final Value<double?> avgGrade;
  final Value<double?> thresholdPower;
  const SummarysCompanion({
    this.id = const Value.absent(),
    this.historyId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.startTime = const Value.absent(),
    this.sport = const Value.absent(),
    this.maxTemperature = const Value.absent(),
    this.avgTemperature = const Value.absent(),
    this.totalAscent = const Value.absent(),
    this.totalDescent = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.totalElapsedTime = const Value.absent(),
    this.totalTimerTime = const Value.absent(),
    this.totalMovingTime = const Value.absent(),
    this.totalCalories = const Value.absent(),
    this.totalWork = const Value.absent(),
    this.maxPower = const Value.absent(),
    this.enhancedMaxSpeed = const Value.absent(),
    this.maxSpeed = const Value.absent(),
    this.maxCadence = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.enhancedAvgSpeed = const Value.absent(),
    this.avgSpeed = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.enhancedAvgAltitude = const Value.absent(),
    this.avgAltitude = const Value.absent(),
    this.enhancedMaxAltitude = const Value.absent(),
    this.maxAltitude = const Value.absent(),
    this.avgGrade = const Value.absent(),
    this.thresholdPower = const Value.absent(),
  });
  SummarysCompanion.insert({
    this.id = const Value.absent(),
    required int historyId,
    this.timestamp = const Value.absent(),
    this.startTime = const Value.absent(),
    this.sport = const Value.absent(),
    this.maxTemperature = const Value.absent(),
    this.avgTemperature = const Value.absent(),
    this.totalAscent = const Value.absent(),
    this.totalDescent = const Value.absent(),
    this.totalDistance = const Value.absent(),
    this.totalElapsedTime = const Value.absent(),
    this.totalTimerTime = const Value.absent(),
    this.totalMovingTime = const Value.absent(),
    this.totalCalories = const Value.absent(),
    this.totalWork = const Value.absent(),
    this.maxPower = const Value.absent(),
    this.enhancedMaxSpeed = const Value.absent(),
    this.maxSpeed = const Value.absent(),
    this.maxCadence = const Value.absent(),
    this.maxHeartRate = const Value.absent(),
    this.avgPower = const Value.absent(),
    this.enhancedAvgSpeed = const Value.absent(),
    this.avgSpeed = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.avgHeartRate = const Value.absent(),
    this.enhancedAvgAltitude = const Value.absent(),
    this.avgAltitude = const Value.absent(),
    this.enhancedMaxAltitude = const Value.absent(),
    this.maxAltitude = const Value.absent(),
    this.avgGrade = const Value.absent(),
    this.thresholdPower = const Value.absent(),
  }) : historyId = Value(historyId);
  static Insertable<Summary> custom({
    Expression<int>? id,
    Expression<int>? historyId,
    Expression<int>? timestamp,
    Expression<DateTime>? startTime,
    Expression<String>? sport,
    Expression<double>? maxTemperature,
    Expression<double>? avgTemperature,
    Expression<double>? totalAscent,
    Expression<double>? totalDescent,
    Expression<double>? totalDistance,
    Expression<double>? totalElapsedTime,
    Expression<double>? totalTimerTime,
    Expression<double>? totalMovingTime,
    Expression<double>? totalCalories,
    Expression<double>? totalWork,
    Expression<double>? maxPower,
    Expression<double>? enhancedMaxSpeed,
    Expression<double>? maxSpeed,
    Expression<double>? maxCadence,
    Expression<double>? maxHeartRate,
    Expression<double>? avgPower,
    Expression<double>? enhancedAvgSpeed,
    Expression<double>? avgSpeed,
    Expression<double>? avgCadence,
    Expression<double>? avgHeartRate,
    Expression<double>? enhancedAvgAltitude,
    Expression<double>? avgAltitude,
    Expression<double>? enhancedMaxAltitude,
    Expression<double>? maxAltitude,
    Expression<double>? avgGrade,
    Expression<double>? thresholdPower,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (historyId != null) 'history_id': historyId,
      if (timestamp != null) 'timestamp': timestamp,
      if (startTime != null) 'start_time': startTime,
      if (sport != null) 'sport': sport,
      if (maxTemperature != null) 'max_temperature': maxTemperature,
      if (avgTemperature != null) 'avg_temperature': avgTemperature,
      if (totalAscent != null) 'total_ascent': totalAscent,
      if (totalDescent != null) 'total_descent': totalDescent,
      if (totalDistance != null) 'total_distance': totalDistance,
      if (totalElapsedTime != null) 'total_elapsed_time': totalElapsedTime,
      if (totalTimerTime != null) 'total_timer_time': totalTimerTime,
      if (totalMovingTime != null) 'total_moving_time': totalMovingTime,
      if (totalCalories != null) 'total_calories': totalCalories,
      if (totalWork != null) 'total_work': totalWork,
      if (maxPower != null) 'max_power': maxPower,
      if (enhancedMaxSpeed != null) 'enhanced_max_speed': enhancedMaxSpeed,
      if (maxSpeed != null) 'max_speed': maxSpeed,
      if (maxCadence != null) 'max_cadence': maxCadence,
      if (maxHeartRate != null) 'max_heart_rate': maxHeartRate,
      if (avgPower != null) 'avg_power': avgPower,
      if (enhancedAvgSpeed != null) 'enhanced_avg_speed': enhancedAvgSpeed,
      if (avgSpeed != null) 'avg_speed': avgSpeed,
      if (avgCadence != null) 'avg_cadence': avgCadence,
      if (avgHeartRate != null) 'avg_heart_rate': avgHeartRate,
      if (enhancedAvgAltitude != null)
        'enhanced_avg_altitude': enhancedAvgAltitude,
      if (avgAltitude != null) 'avg_altitude': avgAltitude,
      if (enhancedMaxAltitude != null)
        'enhanced_max_altitude': enhancedMaxAltitude,
      if (maxAltitude != null) 'max_altitude': maxAltitude,
      if (avgGrade != null) 'avg_grade': avgGrade,
      if (thresholdPower != null) 'threshold_power': thresholdPower,
    });
  }

  SummarysCompanion copyWith(
      {Value<int>? id,
      Value<int>? historyId,
      Value<int?>? timestamp,
      Value<DateTime?>? startTime,
      Value<String?>? sport,
      Value<double?>? maxTemperature,
      Value<double?>? avgTemperature,
      Value<double?>? totalAscent,
      Value<double?>? totalDescent,
      Value<double?>? totalDistance,
      Value<double?>? totalElapsedTime,
      Value<double?>? totalTimerTime,
      Value<double?>? totalMovingTime,
      Value<double?>? totalCalories,
      Value<double?>? totalWork,
      Value<double?>? maxPower,
      Value<double?>? enhancedMaxSpeed,
      Value<double?>? maxSpeed,
      Value<double?>? maxCadence,
      Value<double?>? maxHeartRate,
      Value<double?>? avgPower,
      Value<double?>? enhancedAvgSpeed,
      Value<double?>? avgSpeed,
      Value<double?>? avgCadence,
      Value<double?>? avgHeartRate,
      Value<double?>? enhancedAvgAltitude,
      Value<double?>? avgAltitude,
      Value<double?>? enhancedMaxAltitude,
      Value<double?>? maxAltitude,
      Value<double?>? avgGrade,
      Value<double?>? thresholdPower}) {
    return SummarysCompanion(
      id: id ?? this.id,
      historyId: historyId ?? this.historyId,
      timestamp: timestamp ?? this.timestamp,
      startTime: startTime ?? this.startTime,
      sport: sport ?? this.sport,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      avgTemperature: avgTemperature ?? this.avgTemperature,
      totalAscent: totalAscent ?? this.totalAscent,
      totalDescent: totalDescent ?? this.totalDescent,
      totalDistance: totalDistance ?? this.totalDistance,
      totalElapsedTime: totalElapsedTime ?? this.totalElapsedTime,
      totalTimerTime: totalTimerTime ?? this.totalTimerTime,
      totalMovingTime: totalMovingTime ?? this.totalMovingTime,
      totalCalories: totalCalories ?? this.totalCalories,
      totalWork: totalWork ?? this.totalWork,
      maxPower: maxPower ?? this.maxPower,
      enhancedMaxSpeed: enhancedMaxSpeed ?? this.enhancedMaxSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      maxCadence: maxCadence ?? this.maxCadence,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      avgPower: avgPower ?? this.avgPower,
      enhancedAvgSpeed: enhancedAvgSpeed ?? this.enhancedAvgSpeed,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      avgCadence: avgCadence ?? this.avgCadence,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      enhancedAvgAltitude: enhancedAvgAltitude ?? this.enhancedAvgAltitude,
      avgAltitude: avgAltitude ?? this.avgAltitude,
      enhancedMaxAltitude: enhancedMaxAltitude ?? this.enhancedMaxAltitude,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      avgGrade: avgGrade ?? this.avgGrade,
      thresholdPower: thresholdPower ?? this.thresholdPower,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (historyId.present) {
      map['history_id'] = Variable<int>(historyId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (sport.present) {
      map['sport'] = Variable<String>(sport.value);
    }
    if (maxTemperature.present) {
      map['max_temperature'] = Variable<double>(maxTemperature.value);
    }
    if (avgTemperature.present) {
      map['avg_temperature'] = Variable<double>(avgTemperature.value);
    }
    if (totalAscent.present) {
      map['total_ascent'] = Variable<double>(totalAscent.value);
    }
    if (totalDescent.present) {
      map['total_descent'] = Variable<double>(totalDescent.value);
    }
    if (totalDistance.present) {
      map['total_distance'] = Variable<double>(totalDistance.value);
    }
    if (totalElapsedTime.present) {
      map['total_elapsed_time'] = Variable<double>(totalElapsedTime.value);
    }
    if (totalTimerTime.present) {
      map['total_timer_time'] = Variable<double>(totalTimerTime.value);
    }
    if (totalMovingTime.present) {
      map['total_moving_time'] = Variable<double>(totalMovingTime.value);
    }
    if (totalCalories.present) {
      map['total_calories'] = Variable<double>(totalCalories.value);
    }
    if (totalWork.present) {
      map['total_work'] = Variable<double>(totalWork.value);
    }
    if (maxPower.present) {
      map['max_power'] = Variable<double>(maxPower.value);
    }
    if (enhancedMaxSpeed.present) {
      map['enhanced_max_speed'] = Variable<double>(enhancedMaxSpeed.value);
    }
    if (maxSpeed.present) {
      map['max_speed'] = Variable<double>(maxSpeed.value);
    }
    if (maxCadence.present) {
      map['max_cadence'] = Variable<double>(maxCadence.value);
    }
    if (maxHeartRate.present) {
      map['max_heart_rate'] = Variable<double>(maxHeartRate.value);
    }
    if (avgPower.present) {
      map['avg_power'] = Variable<double>(avgPower.value);
    }
    if (enhancedAvgSpeed.present) {
      map['enhanced_avg_speed'] = Variable<double>(enhancedAvgSpeed.value);
    }
    if (avgSpeed.present) {
      map['avg_speed'] = Variable<double>(avgSpeed.value);
    }
    if (avgCadence.present) {
      map['avg_cadence'] = Variable<double>(avgCadence.value);
    }
    if (avgHeartRate.present) {
      map['avg_heart_rate'] = Variable<double>(avgHeartRate.value);
    }
    if (enhancedAvgAltitude.present) {
      map['enhanced_avg_altitude'] =
          Variable<double>(enhancedAvgAltitude.value);
    }
    if (avgAltitude.present) {
      map['avg_altitude'] = Variable<double>(avgAltitude.value);
    }
    if (enhancedMaxAltitude.present) {
      map['enhanced_max_altitude'] =
          Variable<double>(enhancedMaxAltitude.value);
    }
    if (maxAltitude.present) {
      map['max_altitude'] = Variable<double>(maxAltitude.value);
    }
    if (avgGrade.present) {
      map['avg_grade'] = Variable<double>(avgGrade.value);
    }
    if (thresholdPower.present) {
      map['threshold_power'] = Variable<double>(thresholdPower.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SummarysCompanion(')
          ..write('id: $id, ')
          ..write('historyId: $historyId, ')
          ..write('timestamp: $timestamp, ')
          ..write('startTime: $startTime, ')
          ..write('sport: $sport, ')
          ..write('maxTemperature: $maxTemperature, ')
          ..write('avgTemperature: $avgTemperature, ')
          ..write('totalAscent: $totalAscent, ')
          ..write('totalDescent: $totalDescent, ')
          ..write('totalDistance: $totalDistance, ')
          ..write('totalElapsedTime: $totalElapsedTime, ')
          ..write('totalTimerTime: $totalTimerTime, ')
          ..write('totalMovingTime: $totalMovingTime, ')
          ..write('totalCalories: $totalCalories, ')
          ..write('totalWork: $totalWork, ')
          ..write('maxPower: $maxPower, ')
          ..write('enhancedMaxSpeed: $enhancedMaxSpeed, ')
          ..write('maxSpeed: $maxSpeed, ')
          ..write('maxCadence: $maxCadence, ')
          ..write('maxHeartRate: $maxHeartRate, ')
          ..write('avgPower: $avgPower, ')
          ..write('enhancedAvgSpeed: $enhancedAvgSpeed, ')
          ..write('avgSpeed: $avgSpeed, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('avgHeartRate: $avgHeartRate, ')
          ..write('enhancedAvgAltitude: $enhancedAvgAltitude, ')
          ..write('avgAltitude: $avgAltitude, ')
          ..write('enhancedMaxAltitude: $enhancedMaxAltitude, ')
          ..write('maxAltitude: $maxAltitude, ')
          ..write('avgGrade: $avgGrade, ')
          ..write('thresholdPower: $thresholdPower')
          ..write(')'))
        .toString();
  }
}

class $RecordsTable extends Records with TableInfo<$RecordsTable, Record> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _historyIdMeta =
      const VerificationMeta('historyId');
  @override
  late final GeneratedColumn<int> historyId = GeneratedColumn<int>(
      'history_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<RecordMessage>, Uint8List>
      messages = GeneratedColumn<Uint8List>('messages', aliasedName, false,
              type: DriftSqlType.blob, requiredDuringInsert: true)
          .withConverter<List<RecordMessage>>($RecordsTable.$convertermessages);
  @override
  List<GeneratedColumn> get $columns => [id, historyId, messages];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'records';
  @override
  VerificationContext validateIntegrity(Insertable<Record> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('history_id')) {
      context.handle(_historyIdMeta,
          historyId.isAcceptableOrUnknown(data['history_id']!, _historyIdMeta));
    } else if (isInserting) {
      context.missing(_historyIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Record map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Record(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      historyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}history_id'])!,
      messages: $RecordsTable.$convertermessages.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}messages'])!),
    );
  }

  @override
  $RecordsTable createAlias(String alias) {
    return $RecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<RecordMessage>, Uint8List> $convertermessages =
      RecordMessageListBinaryConverter();
}

class Record extends DataClass implements Insertable<Record> {
  final int id;
  final int historyId;
  final List<RecordMessage> messages;
  const Record(
      {required this.id, required this.historyId, required this.messages});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['history_id'] = Variable<int>(historyId);
    {
      map['messages'] =
          Variable<Uint8List>($RecordsTable.$convertermessages.toSql(messages));
    }
    return map;
  }

  RecordsCompanion toCompanion(bool nullToAbsent) {
    return RecordsCompanion(
      id: Value(id),
      historyId: Value(historyId),
      messages: Value(messages),
    );
  }

  factory Record.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Record(
      id: serializer.fromJson<int>(json['id']),
      historyId: serializer.fromJson<int>(json['historyId']),
      messages: serializer.fromJson<List<RecordMessage>>(json['messages']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'historyId': serializer.toJson<int>(historyId),
      'messages': serializer.toJson<List<RecordMessage>>(messages),
    };
  }

  Record copyWith({int? id, int? historyId, List<RecordMessage>? messages}) =>
      Record(
        id: id ?? this.id,
        historyId: historyId ?? this.historyId,
        messages: messages ?? this.messages,
      );
  Record copyWithCompanion(RecordsCompanion data) {
    return Record(
      id: data.id.present ? data.id.value : this.id,
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      messages: data.messages.present ? data.messages.value : this.messages,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Record(')
          ..write('id: $id, ')
          ..write('historyId: $historyId, ')
          ..write('messages: $messages')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, historyId, messages);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Record &&
          other.id == this.id &&
          other.historyId == this.historyId &&
          other.messages == this.messages);
}

class RecordsCompanion extends UpdateCompanion<Record> {
  final Value<int> id;
  final Value<int> historyId;
  final Value<List<RecordMessage>> messages;
  const RecordsCompanion({
    this.id = const Value.absent(),
    this.historyId = const Value.absent(),
    this.messages = const Value.absent(),
  });
  RecordsCompanion.insert({
    this.id = const Value.absent(),
    required int historyId,
    required List<RecordMessage> messages,
  })  : historyId = Value(historyId),
        messages = Value(messages);
  static Insertable<Record> custom({
    Expression<int>? id,
    Expression<int>? historyId,
    Expression<Uint8List>? messages,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (historyId != null) 'history_id': historyId,
      if (messages != null) 'messages': messages,
    });
  }

  RecordsCompanion copyWith(
      {Value<int>? id,
      Value<int>? historyId,
      Value<List<RecordMessage>>? messages}) {
    return RecordsCompanion(
      id: id ?? this.id,
      historyId: historyId ?? this.historyId,
      messages: messages ?? this.messages,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (historyId.present) {
      map['history_id'] = Variable<int>(historyId.value);
    }
    if (messages.present) {
      map['messages'] = Variable<Uint8List>(
          $RecordsTable.$convertermessages.toSql(messages.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordsCompanion(')
          ..write('id: $id, ')
          ..write('historyId: $historyId, ')
          ..write('messages: $messages')
          ..write(')'))
        .toString();
  }
}

class $BestScoresTable extends BestScores
    with TableInfo<$BestScoresTable, BestScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BestScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _historyIdMeta =
      const VerificationMeta('historyId');
  @override
  late final GeneratedColumn<int> historyId = GeneratedColumn<int>(
      'history_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _maxSpeedMeta =
      const VerificationMeta('maxSpeed');
  @override
  late final GeneratedColumn<double> maxSpeed = GeneratedColumn<double>(
      'max_speed', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _maxAltitudeMeta =
      const VerificationMeta('maxAltitude');
  @override
  late final GeneratedColumn<double> maxAltitude = GeneratedColumn<double>(
      'max_altitude', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _maxClimbMeta =
      const VerificationMeta('maxClimb');
  @override
  late final GeneratedColumn<double> maxClimb = GeneratedColumn<double>(
      'max_climb', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _maxPowerMeta =
      const VerificationMeta('maxPower');
  @override
  late final GeneratedColumn<double> maxPower = GeneratedColumn<double>(
      'max_power', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _maxDistanceMeta =
      const VerificationMeta('maxDistance');
  @override
  late final GeneratedColumn<double> maxDistance = GeneratedColumn<double>(
      'max_distance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _maxTimeMeta =
      const VerificationMeta('maxTime');
  @override
  late final GeneratedColumn<int> maxTime = GeneratedColumn<int>(
      'max_time', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _bestSpeedByDistanceJsonMeta =
      const VerificationMeta('bestSpeedByDistanceJson');
  @override
  late final GeneratedColumn<String> bestSpeedByDistanceJson =
      GeneratedColumn<String>('best_speed_by_distance_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('{}'));
  static const VerificationMeta _bestPowerByTimeJsonMeta =
      const VerificationMeta('bestPowerByTimeJson');
  @override
  late final GeneratedColumn<String> bestPowerByTimeJson =
      GeneratedColumn<String>('best_power_by_time_json', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('{}'));
  static const VerificationMeta _bestHRByTimeJsonMeta =
      const VerificationMeta('bestHRByTimeJson');
  @override
  late final GeneratedColumn<String> bestHRByTimeJson = GeneratedColumn<String>(
      'best_h_r_by_time_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        historyId,
        maxSpeed,
        maxAltitude,
        maxClimb,
        maxPower,
        maxDistance,
        maxTime,
        bestSpeedByDistanceJson,
        bestPowerByTimeJson,
        bestHRByTimeJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'best_scores';
  @override
  VerificationContext validateIntegrity(Insertable<BestScore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('history_id')) {
      context.handle(_historyIdMeta,
          historyId.isAcceptableOrUnknown(data['history_id']!, _historyIdMeta));
    } else if (isInserting) {
      context.missing(_historyIdMeta);
    }
    if (data.containsKey('max_speed')) {
      context.handle(_maxSpeedMeta,
          maxSpeed.isAcceptableOrUnknown(data['max_speed']!, _maxSpeedMeta));
    }
    if (data.containsKey('max_altitude')) {
      context.handle(
          _maxAltitudeMeta,
          maxAltitude.isAcceptableOrUnknown(
              data['max_altitude']!, _maxAltitudeMeta));
    }
    if (data.containsKey('max_climb')) {
      context.handle(_maxClimbMeta,
          maxClimb.isAcceptableOrUnknown(data['max_climb']!, _maxClimbMeta));
    }
    if (data.containsKey('max_power')) {
      context.handle(_maxPowerMeta,
          maxPower.isAcceptableOrUnknown(data['max_power']!, _maxPowerMeta));
    }
    if (data.containsKey('max_distance')) {
      context.handle(
          _maxDistanceMeta,
          maxDistance.isAcceptableOrUnknown(
              data['max_distance']!, _maxDistanceMeta));
    }
    if (data.containsKey('max_time')) {
      context.handle(_maxTimeMeta,
          maxTime.isAcceptableOrUnknown(data['max_time']!, _maxTimeMeta));
    }
    if (data.containsKey('best_speed_by_distance_json')) {
      context.handle(
          _bestSpeedByDistanceJsonMeta,
          bestSpeedByDistanceJson.isAcceptableOrUnknown(
              data['best_speed_by_distance_json']!,
              _bestSpeedByDistanceJsonMeta));
    }
    if (data.containsKey('best_power_by_time_json')) {
      context.handle(
          _bestPowerByTimeJsonMeta,
          bestPowerByTimeJson.isAcceptableOrUnknown(
              data['best_power_by_time_json']!, _bestPowerByTimeJsonMeta));
    }
    if (data.containsKey('best_h_r_by_time_json')) {
      context.handle(
          _bestHRByTimeJsonMeta,
          bestHRByTimeJson.isAcceptableOrUnknown(
              data['best_h_r_by_time_json']!, _bestHRByTimeJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BestScore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BestScore(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      historyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}history_id'])!,
      maxSpeed: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_speed'])!,
      maxAltitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_altitude'])!,
      maxClimb: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_climb'])!,
      maxPower: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_power'])!,
      maxDistance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_distance'])!,
      maxTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_time'])!,
      bestSpeedByDistanceJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}best_speed_by_distance_json'])!,
      bestPowerByTimeJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}best_power_by_time_json'])!,
      bestHRByTimeJson: attachedDatabase.typeMapping.read(DriftSqlType.string,
          data['${effectivePrefix}best_h_r_by_time_json'])!,
    );
  }

  @override
  $BestScoresTable createAlias(String alias) {
    return $BestScoresTable(attachedDatabase, alias);
  }
}

class BestScore extends DataClass implements Insertable<BestScore> {
  final int id;
  final int historyId;
  final double maxSpeed;
  final double maxAltitude;
  final double maxClimb;
  final double maxPower;
  final double maxDistance;
  final int maxTime;
  final String bestSpeedByDistanceJson;
  final String bestPowerByTimeJson;
  final String bestHRByTimeJson;
  const BestScore(
      {required this.id,
      required this.historyId,
      required this.maxSpeed,
      required this.maxAltitude,
      required this.maxClimb,
      required this.maxPower,
      required this.maxDistance,
      required this.maxTime,
      required this.bestSpeedByDistanceJson,
      required this.bestPowerByTimeJson,
      required this.bestHRByTimeJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['history_id'] = Variable<int>(historyId);
    map['max_speed'] = Variable<double>(maxSpeed);
    map['max_altitude'] = Variable<double>(maxAltitude);
    map['max_climb'] = Variable<double>(maxClimb);
    map['max_power'] = Variable<double>(maxPower);
    map['max_distance'] = Variable<double>(maxDistance);
    map['max_time'] = Variable<int>(maxTime);
    map['best_speed_by_distance_json'] =
        Variable<String>(bestSpeedByDistanceJson);
    map['best_power_by_time_json'] = Variable<String>(bestPowerByTimeJson);
    map['best_h_r_by_time_json'] = Variable<String>(bestHRByTimeJson);
    return map;
  }

  BestScoresCompanion toCompanion(bool nullToAbsent) {
    return BestScoresCompanion(
      id: Value(id),
      historyId: Value(historyId),
      maxSpeed: Value(maxSpeed),
      maxAltitude: Value(maxAltitude),
      maxClimb: Value(maxClimb),
      maxPower: Value(maxPower),
      maxDistance: Value(maxDistance),
      maxTime: Value(maxTime),
      bestSpeedByDistanceJson: Value(bestSpeedByDistanceJson),
      bestPowerByTimeJson: Value(bestPowerByTimeJson),
      bestHRByTimeJson: Value(bestHRByTimeJson),
    );
  }

  factory BestScore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BestScore(
      id: serializer.fromJson<int>(json['id']),
      historyId: serializer.fromJson<int>(json['historyId']),
      maxSpeed: serializer.fromJson<double>(json['maxSpeed']),
      maxAltitude: serializer.fromJson<double>(json['maxAltitude']),
      maxClimb: serializer.fromJson<double>(json['maxClimb']),
      maxPower: serializer.fromJson<double>(json['maxPower']),
      maxDistance: serializer.fromJson<double>(json['maxDistance']),
      maxTime: serializer.fromJson<int>(json['maxTime']),
      bestSpeedByDistanceJson:
          serializer.fromJson<String>(json['bestSpeedByDistanceJson']),
      bestPowerByTimeJson:
          serializer.fromJson<String>(json['bestPowerByTimeJson']),
      bestHRByTimeJson: serializer.fromJson<String>(json['bestHRByTimeJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'historyId': serializer.toJson<int>(historyId),
      'maxSpeed': serializer.toJson<double>(maxSpeed),
      'maxAltitude': serializer.toJson<double>(maxAltitude),
      'maxClimb': serializer.toJson<double>(maxClimb),
      'maxPower': serializer.toJson<double>(maxPower),
      'maxDistance': serializer.toJson<double>(maxDistance),
      'maxTime': serializer.toJson<int>(maxTime),
      'bestSpeedByDistanceJson':
          serializer.toJson<String>(bestSpeedByDistanceJson),
      'bestPowerByTimeJson': serializer.toJson<String>(bestPowerByTimeJson),
      'bestHRByTimeJson': serializer.toJson<String>(bestHRByTimeJson),
    };
  }

  BestScore copyWith(
          {int? id,
          int? historyId,
          double? maxSpeed,
          double? maxAltitude,
          double? maxClimb,
          double? maxPower,
          double? maxDistance,
          int? maxTime,
          String? bestSpeedByDistanceJson,
          String? bestPowerByTimeJson,
          String? bestHRByTimeJson}) =>
      BestScore(
        id: id ?? this.id,
        historyId: historyId ?? this.historyId,
        maxSpeed: maxSpeed ?? this.maxSpeed,
        maxAltitude: maxAltitude ?? this.maxAltitude,
        maxClimb: maxClimb ?? this.maxClimb,
        maxPower: maxPower ?? this.maxPower,
        maxDistance: maxDistance ?? this.maxDistance,
        maxTime: maxTime ?? this.maxTime,
        bestSpeedByDistanceJson:
            bestSpeedByDistanceJson ?? this.bestSpeedByDistanceJson,
        bestPowerByTimeJson: bestPowerByTimeJson ?? this.bestPowerByTimeJson,
        bestHRByTimeJson: bestHRByTimeJson ?? this.bestHRByTimeJson,
      );
  BestScore copyWithCompanion(BestScoresCompanion data) {
    return BestScore(
      id: data.id.present ? data.id.value : this.id,
      historyId: data.historyId.present ? data.historyId.value : this.historyId,
      maxSpeed: data.maxSpeed.present ? data.maxSpeed.value : this.maxSpeed,
      maxAltitude:
          data.maxAltitude.present ? data.maxAltitude.value : this.maxAltitude,
      maxClimb: data.maxClimb.present ? data.maxClimb.value : this.maxClimb,
      maxPower: data.maxPower.present ? data.maxPower.value : this.maxPower,
      maxDistance:
          data.maxDistance.present ? data.maxDistance.value : this.maxDistance,
      maxTime: data.maxTime.present ? data.maxTime.value : this.maxTime,
      bestSpeedByDistanceJson: data.bestSpeedByDistanceJson.present
          ? data.bestSpeedByDistanceJson.value
          : this.bestSpeedByDistanceJson,
      bestPowerByTimeJson: data.bestPowerByTimeJson.present
          ? data.bestPowerByTimeJson.value
          : this.bestPowerByTimeJson,
      bestHRByTimeJson: data.bestHRByTimeJson.present
          ? data.bestHRByTimeJson.value
          : this.bestHRByTimeJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BestScore(')
          ..write('id: $id, ')
          ..write('historyId: $historyId, ')
          ..write('maxSpeed: $maxSpeed, ')
          ..write('maxAltitude: $maxAltitude, ')
          ..write('maxClimb: $maxClimb, ')
          ..write('maxPower: $maxPower, ')
          ..write('maxDistance: $maxDistance, ')
          ..write('maxTime: $maxTime, ')
          ..write('bestSpeedByDistanceJson: $bestSpeedByDistanceJson, ')
          ..write('bestPowerByTimeJson: $bestPowerByTimeJson, ')
          ..write('bestHRByTimeJson: $bestHRByTimeJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      historyId,
      maxSpeed,
      maxAltitude,
      maxClimb,
      maxPower,
      maxDistance,
      maxTime,
      bestSpeedByDistanceJson,
      bestPowerByTimeJson,
      bestHRByTimeJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BestScore &&
          other.id == this.id &&
          other.historyId == this.historyId &&
          other.maxSpeed == this.maxSpeed &&
          other.maxAltitude == this.maxAltitude &&
          other.maxClimb == this.maxClimb &&
          other.maxPower == this.maxPower &&
          other.maxDistance == this.maxDistance &&
          other.maxTime == this.maxTime &&
          other.bestSpeedByDistanceJson == this.bestSpeedByDistanceJson &&
          other.bestPowerByTimeJson == this.bestPowerByTimeJson &&
          other.bestHRByTimeJson == this.bestHRByTimeJson);
}

class BestScoresCompanion extends UpdateCompanion<BestScore> {
  final Value<int> id;
  final Value<int> historyId;
  final Value<double> maxSpeed;
  final Value<double> maxAltitude;
  final Value<double> maxClimb;
  final Value<double> maxPower;
  final Value<double> maxDistance;
  final Value<int> maxTime;
  final Value<String> bestSpeedByDistanceJson;
  final Value<String> bestPowerByTimeJson;
  final Value<String> bestHRByTimeJson;
  const BestScoresCompanion({
    this.id = const Value.absent(),
    this.historyId = const Value.absent(),
    this.maxSpeed = const Value.absent(),
    this.maxAltitude = const Value.absent(),
    this.maxClimb = const Value.absent(),
    this.maxPower = const Value.absent(),
    this.maxDistance = const Value.absent(),
    this.maxTime = const Value.absent(),
    this.bestSpeedByDistanceJson = const Value.absent(),
    this.bestPowerByTimeJson = const Value.absent(),
    this.bestHRByTimeJson = const Value.absent(),
  });
  BestScoresCompanion.insert({
    this.id = const Value.absent(),
    required int historyId,
    this.maxSpeed = const Value.absent(),
    this.maxAltitude = const Value.absent(),
    this.maxClimb = const Value.absent(),
    this.maxPower = const Value.absent(),
    this.maxDistance = const Value.absent(),
    this.maxTime = const Value.absent(),
    this.bestSpeedByDistanceJson = const Value.absent(),
    this.bestPowerByTimeJson = const Value.absent(),
    this.bestHRByTimeJson = const Value.absent(),
  }) : historyId = Value(historyId);
  static Insertable<BestScore> custom({
    Expression<int>? id,
    Expression<int>? historyId,
    Expression<double>? maxSpeed,
    Expression<double>? maxAltitude,
    Expression<double>? maxClimb,
    Expression<double>? maxPower,
    Expression<double>? maxDistance,
    Expression<int>? maxTime,
    Expression<String>? bestSpeedByDistanceJson,
    Expression<String>? bestPowerByTimeJson,
    Expression<String>? bestHRByTimeJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (historyId != null) 'history_id': historyId,
      if (maxSpeed != null) 'max_speed': maxSpeed,
      if (maxAltitude != null) 'max_altitude': maxAltitude,
      if (maxClimb != null) 'max_climb': maxClimb,
      if (maxPower != null) 'max_power': maxPower,
      if (maxDistance != null) 'max_distance': maxDistance,
      if (maxTime != null) 'max_time': maxTime,
      if (bestSpeedByDistanceJson != null)
        'best_speed_by_distance_json': bestSpeedByDistanceJson,
      if (bestPowerByTimeJson != null)
        'best_power_by_time_json': bestPowerByTimeJson,
      if (bestHRByTimeJson != null) 'best_h_r_by_time_json': bestHRByTimeJson,
    });
  }

  BestScoresCompanion copyWith(
      {Value<int>? id,
      Value<int>? historyId,
      Value<double>? maxSpeed,
      Value<double>? maxAltitude,
      Value<double>? maxClimb,
      Value<double>? maxPower,
      Value<double>? maxDistance,
      Value<int>? maxTime,
      Value<String>? bestSpeedByDistanceJson,
      Value<String>? bestPowerByTimeJson,
      Value<String>? bestHRByTimeJson}) {
    return BestScoresCompanion(
      id: id ?? this.id,
      historyId: historyId ?? this.historyId,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      maxAltitude: maxAltitude ?? this.maxAltitude,
      maxClimb: maxClimb ?? this.maxClimb,
      maxPower: maxPower ?? this.maxPower,
      maxDistance: maxDistance ?? this.maxDistance,
      maxTime: maxTime ?? this.maxTime,
      bestSpeedByDistanceJson:
          bestSpeedByDistanceJson ?? this.bestSpeedByDistanceJson,
      bestPowerByTimeJson: bestPowerByTimeJson ?? this.bestPowerByTimeJson,
      bestHRByTimeJson: bestHRByTimeJson ?? this.bestHRByTimeJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (historyId.present) {
      map['history_id'] = Variable<int>(historyId.value);
    }
    if (maxSpeed.present) {
      map['max_speed'] = Variable<double>(maxSpeed.value);
    }
    if (maxAltitude.present) {
      map['max_altitude'] = Variable<double>(maxAltitude.value);
    }
    if (maxClimb.present) {
      map['max_climb'] = Variable<double>(maxClimb.value);
    }
    if (maxPower.present) {
      map['max_power'] = Variable<double>(maxPower.value);
    }
    if (maxDistance.present) {
      map['max_distance'] = Variable<double>(maxDistance.value);
    }
    if (maxTime.present) {
      map['max_time'] = Variable<int>(maxTime.value);
    }
    if (bestSpeedByDistanceJson.present) {
      map['best_speed_by_distance_json'] =
          Variable<String>(bestSpeedByDistanceJson.value);
    }
    if (bestPowerByTimeJson.present) {
      map['best_power_by_time_json'] =
          Variable<String>(bestPowerByTimeJson.value);
    }
    if (bestHRByTimeJson.present) {
      map['best_h_r_by_time_json'] = Variable<String>(bestHRByTimeJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BestScoresCompanion(')
          ..write('id: $id, ')
          ..write('historyId: $historyId, ')
          ..write('maxSpeed: $maxSpeed, ')
          ..write('maxAltitude: $maxAltitude, ')
          ..write('maxClimb: $maxClimb, ')
          ..write('maxPower: $maxPower, ')
          ..write('maxDistance: $maxDistance, ')
          ..write('maxTime: $maxTime, ')
          ..write('bestSpeedByDistanceJson: $bestSpeedByDistanceJson, ')
          ..write('bestPowerByTimeJson: $bestPowerByTimeJson, ')
          ..write('bestHRByTimeJson: $bestHRByTimeJson')
          ..write(')'))
        .toString();
  }
}

class $KVsTable extends KVs with TableInfo<$KVsTable, KV> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KVsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'k_vs';
  @override
  VerificationContext validateIntegrity(Insertable<KV> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KV map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KV(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $KVsTable createAlias(String alias) {
    return $KVsTable(attachedDatabase, alias);
  }
}

class KV extends DataClass implements Insertable<KV> {
  final int id;
  final String key;
  final String value;
  const KV({required this.id, required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KVsCompanion toCompanion(bool nullToAbsent) {
    return KVsCompanion(
      id: Value(id),
      key: Value(key),
      value: Value(value),
    );
  }

  factory KV.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KV(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KV copyWith({int? id, String? key, String? value}) => KV(
        id: id ?? this.id,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  KV copyWithCompanion(KVsCompanion data) {
    return KV(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KV(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KV &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class KVsCompanion extends UpdateCompanion<KV> {
  final Value<int> id;
  final Value<String> key;
  final Value<String> value;
  const KVsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  KVsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    required String value,
  })  : key = Value(key),
        value = Value(value);
  static Insertable<KV> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  KVsCompanion copyWith(
      {Value<int>? id, Value<String>? key, Value<String>? value}) {
    return KVsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KVsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

abstract class _$Database extends GeneratedDatabase {
  _$Database(QueryExecutor e) : super(e);
  $DatabaseManager get managers => $DatabaseManager(this);
  late final $HistorysTable historys = $HistorysTable(this);
  late final $RoutesTable routes = $RoutesTable(this);
  late final $SegmentsTable segments = $SegmentsTable(this);
  late final $SummarysTable summarys = $SummarysTable(this);
  late final $RecordsTable records = $RecordsTable(this);
  late final $BestScoresTable bestScores = $BestScoresTable(this);
  late final $KVsTable kVs = $KVsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [historys, routes, segments, summarys, records, bestScores, kVs];
}

typedef $$HistorysTableCreateCompanionBuilder = HistorysCompanion Function({
  Value<int> id,
  required String filePath,
  Value<DateTime?> createdAt,
  required List<LatLng> route,
  Value<int?> summaryId,
  Value<int?> bestScoreId,
});
typedef $$HistorysTableUpdateCompanionBuilder = HistorysCompanion Function({
  Value<int> id,
  Value<String> filePath,
  Value<DateTime?> createdAt,
  Value<List<LatLng>> route,
  Value<int?> summaryId,
  Value<int?> bestScoreId,
});

class $$HistorysTableFilterComposer
    extends Composer<_$Database, $HistorysTable> {
  $$HistorysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<LatLng>, List<LatLng>, String>
      get route => $composableBuilder(
          column: $table.route,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get summaryId => $composableBuilder(
      column: $table.summaryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bestScoreId => $composableBuilder(
      column: $table.bestScoreId, builder: (column) => ColumnFilters(column));
}

class $$HistorysTableOrderingComposer
    extends Composer<_$Database, $HistorysTable> {
  $$HistorysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get route => $composableBuilder(
      column: $table.route, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get summaryId => $composableBuilder(
      column: $table.summaryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bestScoreId => $composableBuilder(
      column: $table.bestScoreId, builder: (column) => ColumnOrderings(column));
}

class $$HistorysTableAnnotationComposer
    extends Composer<_$Database, $HistorysTable> {
  $$HistorysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<LatLng>, String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<int> get summaryId =>
      $composableBuilder(column: $table.summaryId, builder: (column) => column);

  GeneratedColumn<int> get bestScoreId => $composableBuilder(
      column: $table.bestScoreId, builder: (column) => column);
}

class $$HistorysTableTableManager extends RootTableManager<
    _$Database,
    $HistorysTable,
    History,
    $$HistorysTableFilterComposer,
    $$HistorysTableOrderingComposer,
    $$HistorysTableAnnotationComposer,
    $$HistorysTableCreateCompanionBuilder,
    $$HistorysTableUpdateCompanionBuilder,
    (History, BaseReferences<_$Database, $HistorysTable, History>),
    History,
    PrefetchHooks Function()> {
  $$HistorysTableTableManager(_$Database db, $HistorysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistorysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistorysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistorysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<DateTime?> createdAt = const Value.absent(),
            Value<List<LatLng>> route = const Value.absent(),
            Value<int?> summaryId = const Value.absent(),
            Value<int?> bestScoreId = const Value.absent(),
          }) =>
              HistorysCompanion(
            id: id,
            filePath: filePath,
            createdAt: createdAt,
            route: route,
            summaryId: summaryId,
            bestScoreId: bestScoreId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String filePath,
            Value<DateTime?> createdAt = const Value.absent(),
            required List<LatLng> route,
            Value<int?> summaryId = const Value.absent(),
            Value<int?> bestScoreId = const Value.absent(),
          }) =>
              HistorysCompanion.insert(
            id: id,
            filePath: filePath,
            createdAt: createdAt,
            route: route,
            summaryId: summaryId,
            bestScoreId: bestScoreId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$HistorysTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $HistorysTable,
    History,
    $$HistorysTableFilterComposer,
    $$HistorysTableOrderingComposer,
    $$HistorysTableAnnotationComposer,
    $$HistorysTableCreateCompanionBuilder,
    $$HistorysTableUpdateCompanionBuilder,
    (History, BaseReferences<_$Database, $HistorysTable, History>),
    History,
    PrefetchHooks Function()>;
typedef $$RoutesTableCreateCompanionBuilder = RoutesCompanion Function({
  Value<int> id,
  required String filePath,
  required double distance,
  required List<LatLng> route,
  required String data,
});
typedef $$RoutesTableUpdateCompanionBuilder = RoutesCompanion Function({
  Value<int> id,
  Value<String> filePath,
  Value<double> distance,
  Value<List<LatLng>> route,
  Value<String> data,
});

class $$RoutesTableFilterComposer extends Composer<_$Database, $RoutesTable> {
  $$RoutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<LatLng>, List<LatLng>, String>
      get route => $composableBuilder(
          column: $table.route,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));
}

class $$RoutesTableOrderingComposer extends Composer<_$Database, $RoutesTable> {
  $$RoutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distance => $composableBuilder(
      column: $table.distance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get route => $composableBuilder(
      column: $table.route, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));
}

class $$RoutesTableAnnotationComposer
    extends Composer<_$Database, $RoutesTable> {
  $$RoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<LatLng>, String> get route =>
      $composableBuilder(column: $table.route, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);
}

class $$RoutesTableTableManager extends RootTableManager<
    _$Database,
    $RoutesTable,
    Route,
    $$RoutesTableFilterComposer,
    $$RoutesTableOrderingComposer,
    $$RoutesTableAnnotationComposer,
    $$RoutesTableCreateCompanionBuilder,
    $$RoutesTableUpdateCompanionBuilder,
    (Route, BaseReferences<_$Database, $RoutesTable, Route>),
    Route,
    PrefetchHooks Function()> {
  $$RoutesTableTableManager(_$Database db, $RoutesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<double> distance = const Value.absent(),
            Value<List<LatLng>> route = const Value.absent(),
            Value<String> data = const Value.absent(),
          }) =>
              RoutesCompanion(
            id: id,
            filePath: filePath,
            distance: distance,
            route: route,
            data: data,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String filePath,
            required double distance,
            required List<LatLng> route,
            required String data,
          }) =>
              RoutesCompanion.insert(
            id: id,
            filePath: filePath,
            distance: distance,
            route: route,
            data: data,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RoutesTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $RoutesTable,
    Route,
    $$RoutesTableFilterComposer,
    $$RoutesTableOrderingComposer,
    $$RoutesTableAnnotationComposer,
    $$RoutesTableCreateCompanionBuilder,
    $$RoutesTableUpdateCompanionBuilder,
    (Route, BaseReferences<_$Database, $RoutesTable, Route>),
    Route,
    PrefetchHooks Function()>;
typedef $$SegmentsTableCreateCompanionBuilder = SegmentsCompanion Function({
  Value<int> id,
  required int routeId,
  required int historyId,
  required int bestScoreId,
  required int startIndex,
  required int endIndex,
  required double matchPercentage,
});
typedef $$SegmentsTableUpdateCompanionBuilder = SegmentsCompanion Function({
  Value<int> id,
  Value<int> routeId,
  Value<int> historyId,
  Value<int> bestScoreId,
  Value<int> startIndex,
  Value<int> endIndex,
  Value<double> matchPercentage,
});

class $$SegmentsTableFilterComposer
    extends Composer<_$Database, $SegmentsTable> {
  $$SegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get routeId => $composableBuilder(
      column: $table.routeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bestScoreId => $composableBuilder(
      column: $table.bestScoreId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startIndex => $composableBuilder(
      column: $table.startIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endIndex => $composableBuilder(
      column: $table.endIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get matchPercentage => $composableBuilder(
      column: $table.matchPercentage,
      builder: (column) => ColumnFilters(column));
}

class $$SegmentsTableOrderingComposer
    extends Composer<_$Database, $SegmentsTable> {
  $$SegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get routeId => $composableBuilder(
      column: $table.routeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bestScoreId => $composableBuilder(
      column: $table.bestScoreId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startIndex => $composableBuilder(
      column: $table.startIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endIndex => $composableBuilder(
      column: $table.endIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get matchPercentage => $composableBuilder(
      column: $table.matchPercentage,
      builder: (column) => ColumnOrderings(column));
}

class $$SegmentsTableAnnotationComposer
    extends Composer<_$Database, $SegmentsTable> {
  $$SegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get routeId =>
      $composableBuilder(column: $table.routeId, builder: (column) => column);

  GeneratedColumn<int> get historyId =>
      $composableBuilder(column: $table.historyId, builder: (column) => column);

  GeneratedColumn<int> get bestScoreId => $composableBuilder(
      column: $table.bestScoreId, builder: (column) => column);

  GeneratedColumn<int> get startIndex => $composableBuilder(
      column: $table.startIndex, builder: (column) => column);

  GeneratedColumn<int> get endIndex =>
      $composableBuilder(column: $table.endIndex, builder: (column) => column);

  GeneratedColumn<double> get matchPercentage => $composableBuilder(
      column: $table.matchPercentage, builder: (column) => column);
}

class $$SegmentsTableTableManager extends RootTableManager<
    _$Database,
    $SegmentsTable,
    Segment,
    $$SegmentsTableFilterComposer,
    $$SegmentsTableOrderingComposer,
    $$SegmentsTableAnnotationComposer,
    $$SegmentsTableCreateCompanionBuilder,
    $$SegmentsTableUpdateCompanionBuilder,
    (Segment, BaseReferences<_$Database, $SegmentsTable, Segment>),
    Segment,
    PrefetchHooks Function()> {
  $$SegmentsTableTableManager(_$Database db, $SegmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> routeId = const Value.absent(),
            Value<int> historyId = const Value.absent(),
            Value<int> bestScoreId = const Value.absent(),
            Value<int> startIndex = const Value.absent(),
            Value<int> endIndex = const Value.absent(),
            Value<double> matchPercentage = const Value.absent(),
          }) =>
              SegmentsCompanion(
            id: id,
            routeId: routeId,
            historyId: historyId,
            bestScoreId: bestScoreId,
            startIndex: startIndex,
            endIndex: endIndex,
            matchPercentage: matchPercentage,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int routeId,
            required int historyId,
            required int bestScoreId,
            required int startIndex,
            required int endIndex,
            required double matchPercentage,
          }) =>
              SegmentsCompanion.insert(
            id: id,
            routeId: routeId,
            historyId: historyId,
            bestScoreId: bestScoreId,
            startIndex: startIndex,
            endIndex: endIndex,
            matchPercentage: matchPercentage,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SegmentsTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $SegmentsTable,
    Segment,
    $$SegmentsTableFilterComposer,
    $$SegmentsTableOrderingComposer,
    $$SegmentsTableAnnotationComposer,
    $$SegmentsTableCreateCompanionBuilder,
    $$SegmentsTableUpdateCompanionBuilder,
    (Segment, BaseReferences<_$Database, $SegmentsTable, Segment>),
    Segment,
    PrefetchHooks Function()>;
typedef $$SummarysTableCreateCompanionBuilder = SummarysCompanion Function({
  Value<int> id,
  required int historyId,
  Value<int?> timestamp,
  Value<DateTime?> startTime,
  Value<String?> sport,
  Value<double?> maxTemperature,
  Value<double?> avgTemperature,
  Value<double?> totalAscent,
  Value<double?> totalDescent,
  Value<double?> totalDistance,
  Value<double?> totalElapsedTime,
  Value<double?> totalTimerTime,
  Value<double?> totalMovingTime,
  Value<double?> totalCalories,
  Value<double?> totalWork,
  Value<double?> maxPower,
  Value<double?> enhancedMaxSpeed,
  Value<double?> maxSpeed,
  Value<double?> maxCadence,
  Value<double?> maxHeartRate,
  Value<double?> avgPower,
  Value<double?> enhancedAvgSpeed,
  Value<double?> avgSpeed,
  Value<double?> avgCadence,
  Value<double?> avgHeartRate,
  Value<double?> enhancedAvgAltitude,
  Value<double?> avgAltitude,
  Value<double?> enhancedMaxAltitude,
  Value<double?> maxAltitude,
  Value<double?> avgGrade,
  Value<double?> thresholdPower,
});
typedef $$SummarysTableUpdateCompanionBuilder = SummarysCompanion Function({
  Value<int> id,
  Value<int> historyId,
  Value<int?> timestamp,
  Value<DateTime?> startTime,
  Value<String?> sport,
  Value<double?> maxTemperature,
  Value<double?> avgTemperature,
  Value<double?> totalAscent,
  Value<double?> totalDescent,
  Value<double?> totalDistance,
  Value<double?> totalElapsedTime,
  Value<double?> totalTimerTime,
  Value<double?> totalMovingTime,
  Value<double?> totalCalories,
  Value<double?> totalWork,
  Value<double?> maxPower,
  Value<double?> enhancedMaxSpeed,
  Value<double?> maxSpeed,
  Value<double?> maxCadence,
  Value<double?> maxHeartRate,
  Value<double?> avgPower,
  Value<double?> enhancedAvgSpeed,
  Value<double?> avgSpeed,
  Value<double?> avgCadence,
  Value<double?> avgHeartRate,
  Value<double?> enhancedAvgAltitude,
  Value<double?> avgAltitude,
  Value<double?> enhancedMaxAltitude,
  Value<double?> maxAltitude,
  Value<double?> avgGrade,
  Value<double?> thresholdPower,
});

class $$SummarysTableFilterComposer
    extends Composer<_$Database, $SummarysTable> {
  $$SummarysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sport => $composableBuilder(
      column: $table.sport, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxTemperature => $composableBuilder(
      column: $table.maxTemperature,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgTemperature => $composableBuilder(
      column: $table.avgTemperature,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAscent => $composableBuilder(
      column: $table.totalAscent, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalDescent => $composableBuilder(
      column: $table.totalDescent, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalDistance => $composableBuilder(
      column: $table.totalDistance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalElapsedTime => $composableBuilder(
      column: $table.totalElapsedTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalTimerTime => $composableBuilder(
      column: $table.totalTimerTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalMovingTime => $composableBuilder(
      column: $table.totalMovingTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalCalories => $composableBuilder(
      column: $table.totalCalories, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalWork => $composableBuilder(
      column: $table.totalWork, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxPower => $composableBuilder(
      column: $table.maxPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get enhancedMaxSpeed => $composableBuilder(
      column: $table.enhancedMaxSpeed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxSpeed => $composableBuilder(
      column: $table.maxSpeed, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxCadence => $composableBuilder(
      column: $table.maxCadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgPower => $composableBuilder(
      column: $table.avgPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get enhancedAvgSpeed => $composableBuilder(
      column: $table.enhancedAvgSpeed,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgSpeed => $composableBuilder(
      column: $table.avgSpeed, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get enhancedAvgAltitude => $composableBuilder(
      column: $table.enhancedAvgAltitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgAltitude => $composableBuilder(
      column: $table.avgAltitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get enhancedMaxAltitude => $composableBuilder(
      column: $table.enhancedMaxAltitude,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxAltitude => $composableBuilder(
      column: $table.maxAltitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgGrade => $composableBuilder(
      column: $table.avgGrade, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get thresholdPower => $composableBuilder(
      column: $table.thresholdPower,
      builder: (column) => ColumnFilters(column));
}

class $$SummarysTableOrderingComposer
    extends Composer<_$Database, $SummarysTable> {
  $$SummarysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sport => $composableBuilder(
      column: $table.sport, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxTemperature => $composableBuilder(
      column: $table.maxTemperature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgTemperature => $composableBuilder(
      column: $table.avgTemperature,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAscent => $composableBuilder(
      column: $table.totalAscent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalDescent => $composableBuilder(
      column: $table.totalDescent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalDistance => $composableBuilder(
      column: $table.totalDistance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalElapsedTime => $composableBuilder(
      column: $table.totalElapsedTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalTimerTime => $composableBuilder(
      column: $table.totalTimerTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalMovingTime => $composableBuilder(
      column: $table.totalMovingTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalCalories => $composableBuilder(
      column: $table.totalCalories,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalWork => $composableBuilder(
      column: $table.totalWork, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxPower => $composableBuilder(
      column: $table.maxPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get enhancedMaxSpeed => $composableBuilder(
      column: $table.enhancedMaxSpeed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxSpeed => $composableBuilder(
      column: $table.maxSpeed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxCadence => $composableBuilder(
      column: $table.maxCadence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgPower => $composableBuilder(
      column: $table.avgPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get enhancedAvgSpeed => $composableBuilder(
      column: $table.enhancedAvgSpeed,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgSpeed => $composableBuilder(
      column: $table.avgSpeed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get enhancedAvgAltitude => $composableBuilder(
      column: $table.enhancedAvgAltitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgAltitude => $composableBuilder(
      column: $table.avgAltitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get enhancedMaxAltitude => $composableBuilder(
      column: $table.enhancedMaxAltitude,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxAltitude => $composableBuilder(
      column: $table.maxAltitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgGrade => $composableBuilder(
      column: $table.avgGrade, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get thresholdPower => $composableBuilder(
      column: $table.thresholdPower,
      builder: (column) => ColumnOrderings(column));
}

class $$SummarysTableAnnotationComposer
    extends Composer<_$Database, $SummarysTable> {
  $$SummarysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get historyId =>
      $composableBuilder(column: $table.historyId, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get sport =>
      $composableBuilder(column: $table.sport, builder: (column) => column);

  GeneratedColumn<double> get maxTemperature => $composableBuilder(
      column: $table.maxTemperature, builder: (column) => column);

  GeneratedColumn<double> get avgTemperature => $composableBuilder(
      column: $table.avgTemperature, builder: (column) => column);

  GeneratedColumn<double> get totalAscent => $composableBuilder(
      column: $table.totalAscent, builder: (column) => column);

  GeneratedColumn<double> get totalDescent => $composableBuilder(
      column: $table.totalDescent, builder: (column) => column);

  GeneratedColumn<double> get totalDistance => $composableBuilder(
      column: $table.totalDistance, builder: (column) => column);

  GeneratedColumn<double> get totalElapsedTime => $composableBuilder(
      column: $table.totalElapsedTime, builder: (column) => column);

  GeneratedColumn<double> get totalTimerTime => $composableBuilder(
      column: $table.totalTimerTime, builder: (column) => column);

  GeneratedColumn<double> get totalMovingTime => $composableBuilder(
      column: $table.totalMovingTime, builder: (column) => column);

  GeneratedColumn<double> get totalCalories => $composableBuilder(
      column: $table.totalCalories, builder: (column) => column);

  GeneratedColumn<double> get totalWork =>
      $composableBuilder(column: $table.totalWork, builder: (column) => column);

  GeneratedColumn<double> get maxPower =>
      $composableBuilder(column: $table.maxPower, builder: (column) => column);

  GeneratedColumn<double> get enhancedMaxSpeed => $composableBuilder(
      column: $table.enhancedMaxSpeed, builder: (column) => column);

  GeneratedColumn<double> get maxSpeed =>
      $composableBuilder(column: $table.maxSpeed, builder: (column) => column);

  GeneratedColumn<double> get maxCadence => $composableBuilder(
      column: $table.maxCadence, builder: (column) => column);

  GeneratedColumn<double> get maxHeartRate => $composableBuilder(
      column: $table.maxHeartRate, builder: (column) => column);

  GeneratedColumn<double> get avgPower =>
      $composableBuilder(column: $table.avgPower, builder: (column) => column);

  GeneratedColumn<double> get enhancedAvgSpeed => $composableBuilder(
      column: $table.enhancedAvgSpeed, builder: (column) => column);

  GeneratedColumn<double> get avgSpeed =>
      $composableBuilder(column: $table.avgSpeed, builder: (column) => column);

  GeneratedColumn<double> get avgCadence => $composableBuilder(
      column: $table.avgCadence, builder: (column) => column);

  GeneratedColumn<double> get avgHeartRate => $composableBuilder(
      column: $table.avgHeartRate, builder: (column) => column);

  GeneratedColumn<double> get enhancedAvgAltitude => $composableBuilder(
      column: $table.enhancedAvgAltitude, builder: (column) => column);

  GeneratedColumn<double> get avgAltitude => $composableBuilder(
      column: $table.avgAltitude, builder: (column) => column);

  GeneratedColumn<double> get enhancedMaxAltitude => $composableBuilder(
      column: $table.enhancedMaxAltitude, builder: (column) => column);

  GeneratedColumn<double> get maxAltitude => $composableBuilder(
      column: $table.maxAltitude, builder: (column) => column);

  GeneratedColumn<double> get avgGrade =>
      $composableBuilder(column: $table.avgGrade, builder: (column) => column);

  GeneratedColumn<double> get thresholdPower => $composableBuilder(
      column: $table.thresholdPower, builder: (column) => column);
}

class $$SummarysTableTableManager extends RootTableManager<
    _$Database,
    $SummarysTable,
    Summary,
    $$SummarysTableFilterComposer,
    $$SummarysTableOrderingComposer,
    $$SummarysTableAnnotationComposer,
    $$SummarysTableCreateCompanionBuilder,
    $$SummarysTableUpdateCompanionBuilder,
    (Summary, BaseReferences<_$Database, $SummarysTable, Summary>),
    Summary,
    PrefetchHooks Function()> {
  $$SummarysTableTableManager(_$Database db, $SummarysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SummarysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SummarysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SummarysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> historyId = const Value.absent(),
            Value<int?> timestamp = const Value.absent(),
            Value<DateTime?> startTime = const Value.absent(),
            Value<String?> sport = const Value.absent(),
            Value<double?> maxTemperature = const Value.absent(),
            Value<double?> avgTemperature = const Value.absent(),
            Value<double?> totalAscent = const Value.absent(),
            Value<double?> totalDescent = const Value.absent(),
            Value<double?> totalDistance = const Value.absent(),
            Value<double?> totalElapsedTime = const Value.absent(),
            Value<double?> totalTimerTime = const Value.absent(),
            Value<double?> totalMovingTime = const Value.absent(),
            Value<double?> totalCalories = const Value.absent(),
            Value<double?> totalWork = const Value.absent(),
            Value<double?> maxPower = const Value.absent(),
            Value<double?> enhancedMaxSpeed = const Value.absent(),
            Value<double?> maxSpeed = const Value.absent(),
            Value<double?> maxCadence = const Value.absent(),
            Value<double?> maxHeartRate = const Value.absent(),
            Value<double?> avgPower = const Value.absent(),
            Value<double?> enhancedAvgSpeed = const Value.absent(),
            Value<double?> avgSpeed = const Value.absent(),
            Value<double?> avgCadence = const Value.absent(),
            Value<double?> avgHeartRate = const Value.absent(),
            Value<double?> enhancedAvgAltitude = const Value.absent(),
            Value<double?> avgAltitude = const Value.absent(),
            Value<double?> enhancedMaxAltitude = const Value.absent(),
            Value<double?> maxAltitude = const Value.absent(),
            Value<double?> avgGrade = const Value.absent(),
            Value<double?> thresholdPower = const Value.absent(),
          }) =>
              SummarysCompanion(
            id: id,
            historyId: historyId,
            timestamp: timestamp,
            startTime: startTime,
            sport: sport,
            maxTemperature: maxTemperature,
            avgTemperature: avgTemperature,
            totalAscent: totalAscent,
            totalDescent: totalDescent,
            totalDistance: totalDistance,
            totalElapsedTime: totalElapsedTime,
            totalTimerTime: totalTimerTime,
            totalMovingTime: totalMovingTime,
            totalCalories: totalCalories,
            totalWork: totalWork,
            maxPower: maxPower,
            enhancedMaxSpeed: enhancedMaxSpeed,
            maxSpeed: maxSpeed,
            maxCadence: maxCadence,
            maxHeartRate: maxHeartRate,
            avgPower: avgPower,
            enhancedAvgSpeed: enhancedAvgSpeed,
            avgSpeed: avgSpeed,
            avgCadence: avgCadence,
            avgHeartRate: avgHeartRate,
            enhancedAvgAltitude: enhancedAvgAltitude,
            avgAltitude: avgAltitude,
            enhancedMaxAltitude: enhancedMaxAltitude,
            maxAltitude: maxAltitude,
            avgGrade: avgGrade,
            thresholdPower: thresholdPower,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int historyId,
            Value<int?> timestamp = const Value.absent(),
            Value<DateTime?> startTime = const Value.absent(),
            Value<String?> sport = const Value.absent(),
            Value<double?> maxTemperature = const Value.absent(),
            Value<double?> avgTemperature = const Value.absent(),
            Value<double?> totalAscent = const Value.absent(),
            Value<double?> totalDescent = const Value.absent(),
            Value<double?> totalDistance = const Value.absent(),
            Value<double?> totalElapsedTime = const Value.absent(),
            Value<double?> totalTimerTime = const Value.absent(),
            Value<double?> totalMovingTime = const Value.absent(),
            Value<double?> totalCalories = const Value.absent(),
            Value<double?> totalWork = const Value.absent(),
            Value<double?> maxPower = const Value.absent(),
            Value<double?> enhancedMaxSpeed = const Value.absent(),
            Value<double?> maxSpeed = const Value.absent(),
            Value<double?> maxCadence = const Value.absent(),
            Value<double?> maxHeartRate = const Value.absent(),
            Value<double?> avgPower = const Value.absent(),
            Value<double?> enhancedAvgSpeed = const Value.absent(),
            Value<double?> avgSpeed = const Value.absent(),
            Value<double?> avgCadence = const Value.absent(),
            Value<double?> avgHeartRate = const Value.absent(),
            Value<double?> enhancedAvgAltitude = const Value.absent(),
            Value<double?> avgAltitude = const Value.absent(),
            Value<double?> enhancedMaxAltitude = const Value.absent(),
            Value<double?> maxAltitude = const Value.absent(),
            Value<double?> avgGrade = const Value.absent(),
            Value<double?> thresholdPower = const Value.absent(),
          }) =>
              SummarysCompanion.insert(
            id: id,
            historyId: historyId,
            timestamp: timestamp,
            startTime: startTime,
            sport: sport,
            maxTemperature: maxTemperature,
            avgTemperature: avgTemperature,
            totalAscent: totalAscent,
            totalDescent: totalDescent,
            totalDistance: totalDistance,
            totalElapsedTime: totalElapsedTime,
            totalTimerTime: totalTimerTime,
            totalMovingTime: totalMovingTime,
            totalCalories: totalCalories,
            totalWork: totalWork,
            maxPower: maxPower,
            enhancedMaxSpeed: enhancedMaxSpeed,
            maxSpeed: maxSpeed,
            maxCadence: maxCadence,
            maxHeartRate: maxHeartRate,
            avgPower: avgPower,
            enhancedAvgSpeed: enhancedAvgSpeed,
            avgSpeed: avgSpeed,
            avgCadence: avgCadence,
            avgHeartRate: avgHeartRate,
            enhancedAvgAltitude: enhancedAvgAltitude,
            avgAltitude: avgAltitude,
            enhancedMaxAltitude: enhancedMaxAltitude,
            maxAltitude: maxAltitude,
            avgGrade: avgGrade,
            thresholdPower: thresholdPower,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SummarysTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $SummarysTable,
    Summary,
    $$SummarysTableFilterComposer,
    $$SummarysTableOrderingComposer,
    $$SummarysTableAnnotationComposer,
    $$SummarysTableCreateCompanionBuilder,
    $$SummarysTableUpdateCompanionBuilder,
    (Summary, BaseReferences<_$Database, $SummarysTable, Summary>),
    Summary,
    PrefetchHooks Function()>;
typedef $$RecordsTableCreateCompanionBuilder = RecordsCompanion Function({
  Value<int> id,
  required int historyId,
  required List<RecordMessage> messages,
});
typedef $$RecordsTableUpdateCompanionBuilder = RecordsCompanion Function({
  Value<int> id,
  Value<int> historyId,
  Value<List<RecordMessage>> messages,
});

class $$RecordsTableFilterComposer extends Composer<_$Database, $RecordsTable> {
  $$RecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<RecordMessage>, List<RecordMessage>,
          Uint8List>
      get messages => $composableBuilder(
          column: $table.messages,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$RecordsTableOrderingComposer
    extends Composer<_$Database, $RecordsTable> {
  $$RecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<Uint8List> get messages => $composableBuilder(
      column: $table.messages, builder: (column) => ColumnOrderings(column));
}

class $$RecordsTableAnnotationComposer
    extends Composer<_$Database, $RecordsTable> {
  $$RecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get historyId =>
      $composableBuilder(column: $table.historyId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<RecordMessage>, Uint8List>
      get messages => $composableBuilder(
          column: $table.messages, builder: (column) => column);
}

class $$RecordsTableTableManager extends RootTableManager<
    _$Database,
    $RecordsTable,
    Record,
    $$RecordsTableFilterComposer,
    $$RecordsTableOrderingComposer,
    $$RecordsTableAnnotationComposer,
    $$RecordsTableCreateCompanionBuilder,
    $$RecordsTableUpdateCompanionBuilder,
    (Record, BaseReferences<_$Database, $RecordsTable, Record>),
    Record,
    PrefetchHooks Function()> {
  $$RecordsTableTableManager(_$Database db, $RecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> historyId = const Value.absent(),
            Value<List<RecordMessage>> messages = const Value.absent(),
          }) =>
              RecordsCompanion(
            id: id,
            historyId: historyId,
            messages: messages,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int historyId,
            required List<RecordMessage> messages,
          }) =>
              RecordsCompanion.insert(
            id: id,
            historyId: historyId,
            messages: messages,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecordsTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $RecordsTable,
    Record,
    $$RecordsTableFilterComposer,
    $$RecordsTableOrderingComposer,
    $$RecordsTableAnnotationComposer,
    $$RecordsTableCreateCompanionBuilder,
    $$RecordsTableUpdateCompanionBuilder,
    (Record, BaseReferences<_$Database, $RecordsTable, Record>),
    Record,
    PrefetchHooks Function()>;
typedef $$BestScoresTableCreateCompanionBuilder = BestScoresCompanion Function({
  Value<int> id,
  required int historyId,
  Value<double> maxSpeed,
  Value<double> maxAltitude,
  Value<double> maxClimb,
  Value<double> maxPower,
  Value<double> maxDistance,
  Value<int> maxTime,
  Value<String> bestSpeedByDistanceJson,
  Value<String> bestPowerByTimeJson,
  Value<String> bestHRByTimeJson,
});
typedef $$BestScoresTableUpdateCompanionBuilder = BestScoresCompanion Function({
  Value<int> id,
  Value<int> historyId,
  Value<double> maxSpeed,
  Value<double> maxAltitude,
  Value<double> maxClimb,
  Value<double> maxPower,
  Value<double> maxDistance,
  Value<int> maxTime,
  Value<String> bestSpeedByDistanceJson,
  Value<String> bestPowerByTimeJson,
  Value<String> bestHRByTimeJson,
});

class $$BestScoresTableFilterComposer
    extends Composer<_$Database, $BestScoresTable> {
  $$BestScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxSpeed => $composableBuilder(
      column: $table.maxSpeed, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxAltitude => $composableBuilder(
      column: $table.maxAltitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxClimb => $composableBuilder(
      column: $table.maxClimb, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxPower => $composableBuilder(
      column: $table.maxPower, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get maxDistance => $composableBuilder(
      column: $table.maxDistance, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxTime => $composableBuilder(
      column: $table.maxTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bestSpeedByDistanceJson => $composableBuilder(
      column: $table.bestSpeedByDistanceJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bestPowerByTimeJson => $composableBuilder(
      column: $table.bestPowerByTimeJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bestHRByTimeJson => $composableBuilder(
      column: $table.bestHRByTimeJson,
      builder: (column) => ColumnFilters(column));
}

class $$BestScoresTableOrderingComposer
    extends Composer<_$Database, $BestScoresTable> {
  $$BestScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get historyId => $composableBuilder(
      column: $table.historyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxSpeed => $composableBuilder(
      column: $table.maxSpeed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxAltitude => $composableBuilder(
      column: $table.maxAltitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxClimb => $composableBuilder(
      column: $table.maxClimb, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxPower => $composableBuilder(
      column: $table.maxPower, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get maxDistance => $composableBuilder(
      column: $table.maxDistance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxTime => $composableBuilder(
      column: $table.maxTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bestSpeedByDistanceJson => $composableBuilder(
      column: $table.bestSpeedByDistanceJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bestPowerByTimeJson => $composableBuilder(
      column: $table.bestPowerByTimeJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bestHRByTimeJson => $composableBuilder(
      column: $table.bestHRByTimeJson,
      builder: (column) => ColumnOrderings(column));
}

class $$BestScoresTableAnnotationComposer
    extends Composer<_$Database, $BestScoresTable> {
  $$BestScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get historyId =>
      $composableBuilder(column: $table.historyId, builder: (column) => column);

  GeneratedColumn<double> get maxSpeed =>
      $composableBuilder(column: $table.maxSpeed, builder: (column) => column);

  GeneratedColumn<double> get maxAltitude => $composableBuilder(
      column: $table.maxAltitude, builder: (column) => column);

  GeneratedColumn<double> get maxClimb =>
      $composableBuilder(column: $table.maxClimb, builder: (column) => column);

  GeneratedColumn<double> get maxPower =>
      $composableBuilder(column: $table.maxPower, builder: (column) => column);

  GeneratedColumn<double> get maxDistance => $composableBuilder(
      column: $table.maxDistance, builder: (column) => column);

  GeneratedColumn<int> get maxTime =>
      $composableBuilder(column: $table.maxTime, builder: (column) => column);

  GeneratedColumn<String> get bestSpeedByDistanceJson => $composableBuilder(
      column: $table.bestSpeedByDistanceJson, builder: (column) => column);

  GeneratedColumn<String> get bestPowerByTimeJson => $composableBuilder(
      column: $table.bestPowerByTimeJson, builder: (column) => column);

  GeneratedColumn<String> get bestHRByTimeJson => $composableBuilder(
      column: $table.bestHRByTimeJson, builder: (column) => column);
}

class $$BestScoresTableTableManager extends RootTableManager<
    _$Database,
    $BestScoresTable,
    BestScore,
    $$BestScoresTableFilterComposer,
    $$BestScoresTableOrderingComposer,
    $$BestScoresTableAnnotationComposer,
    $$BestScoresTableCreateCompanionBuilder,
    $$BestScoresTableUpdateCompanionBuilder,
    (BestScore, BaseReferences<_$Database, $BestScoresTable, BestScore>),
    BestScore,
    PrefetchHooks Function()> {
  $$BestScoresTableTableManager(_$Database db, $BestScoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BestScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BestScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BestScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> historyId = const Value.absent(),
            Value<double> maxSpeed = const Value.absent(),
            Value<double> maxAltitude = const Value.absent(),
            Value<double> maxClimb = const Value.absent(),
            Value<double> maxPower = const Value.absent(),
            Value<double> maxDistance = const Value.absent(),
            Value<int> maxTime = const Value.absent(),
            Value<String> bestSpeedByDistanceJson = const Value.absent(),
            Value<String> bestPowerByTimeJson = const Value.absent(),
            Value<String> bestHRByTimeJson = const Value.absent(),
          }) =>
              BestScoresCompanion(
            id: id,
            historyId: historyId,
            maxSpeed: maxSpeed,
            maxAltitude: maxAltitude,
            maxClimb: maxClimb,
            maxPower: maxPower,
            maxDistance: maxDistance,
            maxTime: maxTime,
            bestSpeedByDistanceJson: bestSpeedByDistanceJson,
            bestPowerByTimeJson: bestPowerByTimeJson,
            bestHRByTimeJson: bestHRByTimeJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int historyId,
            Value<double> maxSpeed = const Value.absent(),
            Value<double> maxAltitude = const Value.absent(),
            Value<double> maxClimb = const Value.absent(),
            Value<double> maxPower = const Value.absent(),
            Value<double> maxDistance = const Value.absent(),
            Value<int> maxTime = const Value.absent(),
            Value<String> bestSpeedByDistanceJson = const Value.absent(),
            Value<String> bestPowerByTimeJson = const Value.absent(),
            Value<String> bestHRByTimeJson = const Value.absent(),
          }) =>
              BestScoresCompanion.insert(
            id: id,
            historyId: historyId,
            maxSpeed: maxSpeed,
            maxAltitude: maxAltitude,
            maxClimb: maxClimb,
            maxPower: maxPower,
            maxDistance: maxDistance,
            maxTime: maxTime,
            bestSpeedByDistanceJson: bestSpeedByDistanceJson,
            bestPowerByTimeJson: bestPowerByTimeJson,
            bestHRByTimeJson: bestHRByTimeJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BestScoresTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $BestScoresTable,
    BestScore,
    $$BestScoresTableFilterComposer,
    $$BestScoresTableOrderingComposer,
    $$BestScoresTableAnnotationComposer,
    $$BestScoresTableCreateCompanionBuilder,
    $$BestScoresTableUpdateCompanionBuilder,
    (BestScore, BaseReferences<_$Database, $BestScoresTable, BestScore>),
    BestScore,
    PrefetchHooks Function()>;
typedef $$KVsTableCreateCompanionBuilder = KVsCompanion Function({
  Value<int> id,
  required String key,
  required String value,
});
typedef $$KVsTableUpdateCompanionBuilder = KVsCompanion Function({
  Value<int> id,
  Value<String> key,
  Value<String> value,
});

class $$KVsTableFilterComposer extends Composer<_$Database, $KVsTable> {
  $$KVsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$KVsTableOrderingComposer extends Composer<_$Database, $KVsTable> {
  $$KVsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$KVsTableAnnotationComposer extends Composer<_$Database, $KVsTable> {
  $$KVsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KVsTableTableManager extends RootTableManager<
    _$Database,
    $KVsTable,
    KV,
    $$KVsTableFilterComposer,
    $$KVsTableOrderingComposer,
    $$KVsTableAnnotationComposer,
    $$KVsTableCreateCompanionBuilder,
    $$KVsTableUpdateCompanionBuilder,
    (KV, BaseReferences<_$Database, $KVsTable, KV>),
    KV,
    PrefetchHooks Function()> {
  $$KVsTableTableManager(_$Database db, $KVsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KVsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KVsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KVsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
          }) =>
              KVsCompanion(
            id: id,
            key: key,
            value: value,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String key,
            required String value,
          }) =>
              KVsCompanion.insert(
            id: id,
            key: key,
            value: value,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KVsTableProcessedTableManager = ProcessedTableManager<
    _$Database,
    $KVsTable,
    KV,
    $$KVsTableFilterComposer,
    $$KVsTableOrderingComposer,
    $$KVsTableAnnotationComposer,
    $$KVsTableCreateCompanionBuilder,
    $$KVsTableUpdateCompanionBuilder,
    (KV, BaseReferences<_$Database, $KVsTable, KV>),
    KV,
    PrefetchHooks Function()>;

class $DatabaseManager {
  final _$Database _db;
  $DatabaseManager(this._db);
  $$HistorysTableTableManager get historys =>
      $$HistorysTableTableManager(_db, _db.historys);
  $$RoutesTableTableManager get routes =>
      $$RoutesTableTableManager(_db, _db.routes);
  $$SegmentsTableTableManager get segments =>
      $$SegmentsTableTableManager(_db, _db.segments);
  $$SummarysTableTableManager get summarys =>
      $$SummarysTableTableManager(_db, _db.summarys);
  $$RecordsTableTableManager get records =>
      $$RecordsTableTableManager(_db, _db.records);
  $$BestScoresTableTableManager get bestScores =>
      $$BestScoresTableTableManager(_db, _db.bestScores);
  $$KVsTableTableManager get kVs => $$KVsTableTableManager(_db, _db.kVs);
}
