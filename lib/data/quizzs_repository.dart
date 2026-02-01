import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quizz.dart';
import '../models/reward_media.dart';
import '../models/dav_file.dart';
import '../services/nextcloud_config.dart';
import '../services/nextcloud_dav_client.dart';
import '../storage/credentials_storage.dart';

class QuizzsRepository {
  const QuizzsRepository();

  Future<List<Quizz>> load() async {
    final raw = await rootBundle.loadString('assets/data/quizzs.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded['quizzs'] as List<dynamic>? ?? [];
    final quizzs = list
        .map((item) => Quizz.fromJson(item as Map<String, dynamic>))
        .toList();

    final creds = await const CredentialsStorage().load();
    if (creds != null) {
      final (user, pass) = creds;
      final client = NextcloudDavClient(
        baseUrl: nextcloudBaseUrl,
        username: user,
        appPassword: pass,
      );
      final result = <Quizz>[];
      for (final quizz in quizzs) {
        try {
          result.add(await _attachRemoteMedia(quizz, client));
        } catch (_) {
          result.add(quizz);
        }
        await Future.delayed(const Duration(milliseconds: 120));
      }
      return result;
    }

    return _fallbackLocal(quizzs);
  }

  Future<List<String>> _loadAssetManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets();
    } catch (_) {
      return [];
    }
  }

  Future<List<Quizz>> _fallbackLocal(List<Quizz> quizzs) async {
    final manifest = await _loadAssetManifest();
    final normalized = manifest.map((path) => path.replaceAll('\\', '/')).toList();
    return quizzs.map((quizz) => _ensureRewardMedia(quizz, normalized)).toList();
  }

  Quizz _ensureRewardMedia(
    Quizz quizz,
    List<String> assets,
  ) {
    if (quizz.rewardMedia.isNotEmpty) {
      return quizz;
    }

    final folder = quizz.reward.folder;
    final filtered = assets
        .where((path) => path.startsWith(folder))
        .where((path) => !_isDirectory(path))
        .toList()
      ..sort();

    if (filtered.isEmpty) {
      return quizz;
    }

    final generated = <RewardMedia>[];
    for (final path in filtered) {
      if (_isCoverImage(path)) {
        continue;
      }
      final type = _inferType(path);
      if (type == null) {
        continue;
      }
      final id = '${quizz.id}_${_basenameWithoutExt(path)}';
      final cover = type == RewardMediaType.photo
          ? path
          : _findVideoCover(path, filtered) ?? path;
      generated.add(
        RewardMedia(
          id: id,
          quizzId: quizz.id,
          type: type,
          path: path,
          coverPath: cover,
        ),
      );
    }

    return quizz.copyWith(rewardMedia: generated);
  }

  Future<Quizz> _attachRemoteMedia(
    Quizz quizz,
    NextcloudDavClient client,
  ) async {
    final remoteQuestions =
        _mapQuestionImagesToRemote(quizz.questionImages ?? const []);
    if (quizz.rewardMedia.isNotEmpty) {
      return quizz.copyWith(questionImages: remoteQuestions);
    }
    final remoteFolder = _toRemoteRewardFolder(quizz.reward.folder);
    final files = await client.listFiles(remoteFolder);
    if (files.isEmpty) {
      return quizz.copyWith(questionImages: remoteQuestions);
    }

    final coverMap = _buildCoverMap(files);
    final generated = <RewardMedia>[];
    for (final file in files) {
      if (_isCoverName(file.name)) {
        continue;
      }
      final type = _inferType(file.name) ?? _inferTypeFromMime(file.mimeType);
      if (type == null) {
        continue;
      }
      final id = '${quizz.id}_${_basenameWithoutExt(file.name)}';
      final coverUrl = type == RewardMediaType.photo
          ? file.url.toString()
          : (coverMap[file.name] ?? file.url.toString());
      generated.add(
        RewardMedia(
          id: id,
          quizzId: quizz.id,
          type: type,
          path: file.url.toString(),
          coverPath: coverUrl,
        ),
      );
    }

    return quizz.copyWith(
      rewardMedia: generated,
      questionImages: remoteQuestions,
    );
  }

  static bool _isDirectory(String path) {
    return path.endsWith('/');
  }

  static RewardMediaType? _inferType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return RewardMediaType.photo;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v')) {
      return RewardMediaType.video;
    }
    return null;
  }

  static RewardMediaType? _inferTypeFromMime(String mime) {
    final lower = mime.toLowerCase();
    if (lower.startsWith('image/')) {
      return RewardMediaType.photo;
    }
    if (lower.startsWith('video/')) {
      return RewardMediaType.video;
    }
    return null;
  }

  static String _basenameWithoutExt(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot == -1 ? name : name.substring(0, dot);
  }

  static String? _findVideoCover(String path, List<String> assets) {
    final base = _basenameWithoutExt(path);
    final folder = path.substring(0, path.lastIndexOf('/') + 1);
    final candidates = [
      '$folder${base}_cover.jpg',
      '$folder${base}_cover.png',
      '$folder$base-cover.jpg',
      '$folder$base-cover.png',
    ];
    for (final candidate in candidates) {
      if (assets.contains(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  static bool _isCoverImage(String path) {
    final lower = path.toLowerCase();
    if (!(lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif'))) {
      return false;
    }
    return lower.contains('_cover.') || lower.contains('-cover.');
  }

  static bool _isCoverName(String name) {
    final lower = name.toLowerCase();
    return lower.contains('_cover.') || lower.contains('-cover.');
  }

  static String _toRemoteRewardFolder(String localFolder) {
    final normalized = localFolder.replaceAll('\\', '/');
    if (normalized.startsWith('medias/')) {
      return '${nextcloudMediaRoot}${normalized}';
    }
    if (normalized.startsWith('Media/')) {
      return 'dav/$normalized';
    }
    return '${nextcloudMediaRoot}$normalized';
  }

  static List<String> _mapQuestionImagesToRemote(List<String> images) {
    return images.map((path) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return path;
      }
      final normalized = path.replaceAll('\\', '/');
      if (normalized.startsWith('quizz_images/')) {
        return '$nextcloudBaseUrl/${nextcloudMediaRoot}$normalized';
      }
      if (normalized.startsWith('Media/')) {
        return '$nextcloudBaseUrl/dav/$normalized';
      }
      return '$nextcloudBaseUrl/${nextcloudMediaRoot}$normalized';
    }).toList();
  }

  static Map<String, String> _buildCoverMap(List<DavFile> files) {
    final map = <String, String>{};
    for (final file in files) {
      if (!_isCoverName(file.name)) {
        continue;
      }
      final base = file.name
          .replaceAll('_cover', '')
          .replaceAll('-cover', '');
      map['$base.mp4'] = file.url.toString();
      map['$base.mov'] = file.url.toString();
      map['$base.m4v'] = file.url.toString();
    }
    return map;
  }
}
