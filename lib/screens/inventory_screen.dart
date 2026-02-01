import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/quizzs_repository.dart';
import '../models/progress.dart';
import '../models/reward_media.dart';
import '../services/web_download.dart';
import '../storage/progress_storage.dart';
import '../storage/credentials_storage.dart';
import 'media_viewer_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repository = const QuizzsRepository();
  final _storage = const ProgressStorage();

  bool _loading = true;
  List<RewardMedia> _media = [];
  AppProgress _progress = AppProgress.empty();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final progress = await _storage.load();
    final quizzs = await _repository.load(includeRemoteMedia: false);
    final media = <RewardMedia>[];
    final targetIds = <String>{...progress.completedQuizzIds};
    final tutorial = quizzs.where((q) => q.isTutorial).firstOrNull;
    if (tutorial != null && progress.unlockedMediaIds.isNotEmpty) {
      targetIds.add(tutorial.id);
    }
    for (final quizz in quizzs) {
      if (!targetIds.contains(quizz.id)) {
        continue;
      }
      final full = await _repository.loadById(quizz.id);
      media.addAll((full ?? quizz).rewardMedia);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _media = media;
      _progress = progress;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _media.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          final item = _media[index];
          final unlocked = _progress.unlockedMediaIds.contains(item.id);
          final hasImageCover = _isImagePath(item.coverPath);
          final authHeaders = const CredentialsStorage().authHeadersSync();
          return GestureDetector(
            onTap: unlocked
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MediaViewerScreen(media: item),
                      ),
                    );
                  }
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (unlocked)
                    if (item.type == RewardMediaType.video && !hasImageCover)
                      Container(
                        color: Colors.black12,
                        child: const Icon(Icons.videocam, size: 48),
                      )
                    else
                      _buildCover(item.coverPath, authHeaders, item.type)
                  else
                    Container(
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.lock,
                        size: 36,
                        color: Colors.black54,
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.black54,
                      child: Text(
                        item.type == RewardMediaType.photo ? 'PHOTO' : 'VIDÉO',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  if (unlocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _DownloadButton(
                        onPressed: () => _downloadMedia(item),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  Widget _buildCover(
    String path,
    Map<String, String> headers,
    RewardMediaType type,
  ) {
    final placeholder = Container(
      color: Colors.black12,
      child: Icon(
        type == RewardMediaType.video ? Icons.videocam : Icons.photo,
        size: 48,
      ),
    );

    if (path.startsWith('http')) {
      return Image.network(
        path,
        headers: headers,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Future<void> _downloadMedia(RewardMedia media) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telechargement web uniquement.')),
      );
      return;
    }
    final path = media.path;
    if (!path.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media non disponible en ligne.')),
      );
      return;
    }
    try {
      final headers = const CredentialsStorage().authHeadersSync();
      final dio = Dio();
      final response = await dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers,
        ),
      );
      final bytes = response.data;
      if (bytes == null) {
        throw Exception('Aucun contenu.');
      }
      final filename = _filenameForMedia(media);
      await downloadBytes(
        Uint8List.fromList(bytes),
        filename: filename,
        mimeType: media.type == RewardMediaType.video
            ? 'video/mp4'
            : 'image/jpeg',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Echec du telechargement.')),
      );
    }
  }

  String _filenameForMedia(RewardMedia media) {
    if (media.path.startsWith('http')) {
      final uri = Uri.parse(media.path);
      final name = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : media.id;
      return name.isEmpty ? media.id : name;
    }
    final parts = media.path.split('/');
    return parts.isNotEmpty ? parts.last : media.id;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(999),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.download, color: Colors.white, size: 18),
        tooltip: 'Telecharger',
      ),
    );
  }
}
