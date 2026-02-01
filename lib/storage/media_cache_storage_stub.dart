import 'media_cache_storage.dart';

class _MediaCacheStorageStub implements MediaCacheStorage {
  @override
  Future<void> setPath(String mediaId, String path) async {}

  @override
  Future<String?> getPath(String mediaId) async => null;
}

MediaCacheStorage createStorage() => _MediaCacheStorageStub();
