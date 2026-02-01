import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/progress.dart';

class ProgressStorage {
  static const _key = 'app_progress_v1';

  const ProgressStorage();

  Future<AppProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return AppProgress.empty();
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppProgress.fromJson(decoded);
  }

  Future<void> save(AppProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(progress.toJson());
    await prefs.setString(_key, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
