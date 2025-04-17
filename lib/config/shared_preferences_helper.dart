import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static late SharedPreferences _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static Future<bool> isFirstRun() async {
    return _prefs.getBool('first_run') ?? true;
  }
  
  static Future<void> setFirstRunComplete() async {
    await _prefs.setBool('first_run', false);
  }
  
  // Other preference methods
}