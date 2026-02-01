import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/quizz.dart';
import '../models/reward_media.dart';

class QuizzsRepository {
  const QuizzsRepository();

  Future<List<Quizz>> load() async {
    final raw = await rootBundle.loadString('assets/data/quizzs.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded['quizzs'] as List<dynamic>? ?? [];
    final quizzs = list
        .map((item) => Quizz.fromJson(item as Map<String, dynamic>))
        .toList();

    final manifest = await _loadAssetManifest();
    final normalized = manifest
        .map((path) => path.replaceAll('\\', '/'))
        .toList();
    return quizzs
        .map((quizz) => _ensureRewardMedia(quizz, normalized))
        .toList();
  }

  Future<List<String>> _loadAssetManifest() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest.listAssets();
    } catch (_) {
      return [];
    }
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
}
