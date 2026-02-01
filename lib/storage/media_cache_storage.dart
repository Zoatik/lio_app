import 'media_cache_storage_stub.dart'
    if (dart.library.io) 'media_cache_storage_io.dart';

abstract class MediaCacheStorage {
  Future<void> setPath(String mediaId, String path);
  Future<String?> getPath(String mediaId);
}

MediaCacheStorage createMediaCacheStorage() => createStorage();
