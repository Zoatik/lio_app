import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CredentialsStorage {
  static const _userKey = 'nc_username_v1';
  static const _passKey = 'nc_password_v1';
  static (String, String)? _cached;

  const CredentialsStorage();

  Future<void> save({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, username);
    await prefs.setString(_passKey, password);
    _cached = (username, password);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_passKey);
    _cached = null;
  }

  Future<(String, String)?> load() async {
    if (_cached != null) {
      return _cached;
    }
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString(_userKey);
    final pass = prefs.getString(_passKey);
    if (user == null || pass == null) {
      return null;
    }
    _cached = (user, pass);
    return _cached;
  }

  Map<String, String> authHeadersSync() {
    if (_cached == null) {
      return {};
    }
    final (user, pass) = _cached!;
    final raw = '$user:$pass';
    final encoded = base64Encode(utf8.encode(raw));
    return {'Authorization': 'Basic $encoded'};
  }

  Future<Map<String, String>> authHeaders() async {
    final creds = await load();
    if (creds == null) {
      return {};
    }
    final (user, pass) = creds;
    final raw = '$user:$pass';
    final encoded = base64Encode(utf8.encode(raw));
    return {'Authorization': 'Basic $encoded'};
  }
}
