import 'package:shared_preferences/shared_preferences.dart';

class AgeGateStorage {
  static const _key = 'age_verified_v1';

  const AgeGateStorage();

  Future<bool> isVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> setVerified(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
