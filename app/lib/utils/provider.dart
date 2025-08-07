// 全局数据库实例提供者
import 'package:app/database.dart';
import 'package:app/utils/cache.dart';
import 'package:flutter/material.dart' show ThemeData, ColorScheme, TextTheme, Colors, FontWeight, TextStyle, Brightness;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 历史记录数据提供者（自动缓存）
final historyProvider = StreamProvider.autoDispose<List<History>>((ref) {
  final db = Database();
  return db.select(db.historys).watch();
});

final routesProvider = StreamProvider.autoDispose<List<Route>>((ref) {
  final db = Database();
  return db.select(db.routes).watch();
});

final cacheProvider = Provider<Cache>((ref) => Cache(ref));

// You cannot access BuildContext in a Provider's create function.
// Instead, provide a default ThemeData or use a ConsumerWidget to access Theme.of(context).
final lightThemeProvider = Provider<ThemeData>((ref) => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
    ));

// 暗黑主题
final darkThemeProvider = Provider<ThemeData>((ref) => ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red, brightness: Brightness.dark),
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  ),
    ));