import 'package:shared_preferences/shared_preferences.dart';

class CredentialsStorage {
  static const _userKey = 'nc_username_v1';
  static const _passKey = 'nc_password_v1';

  const CredentialsStorage();

  Future<void> save({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, username);
    await prefs.setString(_passKey, password);
  }

  Future<(String, String)?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString(_userKey);
    final pass = prefs.getString(_passKey);
    if (user == null || pass == null) {
      return null;
    }
    return (user, pass);
  }
}
