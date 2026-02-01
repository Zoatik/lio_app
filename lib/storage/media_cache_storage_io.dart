import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'media_cache_storage.dart';

class _MediaCacheStorageIo implements MediaCacheStorage {
  static const _key = 'media_cache_v1';

  Future<Map<String, String>> _loadMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> _saveMap(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }

  @override
  Future<void> setPath(String mediaId, String path) async {
    final map = await _loadMap();
    map[mediaId] = path;
    await _saveMap(map);
  }

  @override
  Future<String?> getPath(String mediaId) async {
    final map = await _loadMap();
    final path = map[mediaId];
    if (path == null) {
      return null;
    }
    final file = File(path);
    if (!await file.exists()) {
      return null;
    }
    return path;
  }
}

MediaCacheStorage createStorage() => _MediaCacheStorageIo();
