import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static final Prefs _instance = Prefs._internal();
  static SharedPreferences? prefs;

  factory Prefs() {
    return _instance;
  }

  Prefs._internal();

  static Future<void> initialize() async {
    prefs ??= await SharedPreferences.getInstance();
  }

  static T getPreference<T>(String key, T defaultValue) {
    if (prefs == null) return defaultValue;
    final value = prefs!.get(key);
    if (value is T) return value;
    return defaultValue;
  }

  static Future<void> setPreference<T>(String key, T value) async {
    if (prefs == null) return;
    if (value is int) {
      await prefs!.setInt(key, value);
    } else if (value is double) {
      await prefs!.setDouble(key, value);
    } else if (value is bool) {
      await prefs!.setBool(key, value);
    } else if (value is String) {
      await prefs!.setString(key, value);
    } else if (value is List<String>) {
      await prefs!.setStringList(key, value);
    }
  }
}
