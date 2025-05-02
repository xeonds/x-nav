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
}
