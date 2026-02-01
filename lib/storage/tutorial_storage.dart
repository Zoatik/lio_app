import 'package:shared_preferences/shared_preferences.dart';

class TutorialStorage {
  static const _key = 'tutorial_shown_v1';
  static const _finalKey = 'final_message_shown_v1';

  const TutorialStorage();

  Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<bool> shouldShowFinalMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_finalKey) ?? false);
  }

  Future<void> markFinalMessageSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_finalKey, true);
  }
}
