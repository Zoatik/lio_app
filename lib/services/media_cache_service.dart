import 'package:flutter/foundation.dart';

import '../models/reward_media.dart';
import '../storage/credentials_storage.dart';
import '../storage/media_cache_storage.dart';
import 'nextcloud_config.dart';
import 'nextcloud_dav_client.dart';

class MediaCacheService {
  MediaCacheService({
    MediaCacheStorage? storage,
  }) : _storage = storage ?? createMediaCacheStorage();

  final MediaCacheStorage _storage;

  Future<void> prefetch(List<RewardMedia> media) async {
    if (kIsWeb) {
      return;
    }
    final creds = await const CredentialsStorage().load();
    if (creds == null) {
      return;
    }
    final (user, pass) = creds;
    final client = NextcloudDavClient(
      baseUrl: nextcloudBaseUrl,
      username: user,
      appPassword: pass,
    );

    for (final item in media) {
      if (!item.path.startsWith('http')) {
        continue;
      }
      final existing = await _storage.getPath(item.id);
      if (existing != null) {
        continue;
      }
      final localPath = await client.downloadFile(Uri.parse(item.path));
      await _storage.setPath(item.id, localPath);
    }
  }

  Future<String?> getCachedPath(String mediaId) async {
    return _storage.getPath(mediaId);
  }
}
