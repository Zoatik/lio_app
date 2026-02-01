import 'package:flutter/material.dart';

import '../data/quizzs_repository.dart';
import '../models/progress.dart';
import '../models/reward_media.dart';
import '../storage/progress_storage.dart';
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
    final quizzs = await _repository.load();
    final progress = await _storage.load();
    final media = <RewardMedia>[];
    for (final quizz in quizzs) {
      media.addAll(quizz.rewardMedia);
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
                      Image.asset(
                        item.coverPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.black12,
                          child: Icon(
                            item.type == RewardMediaType.video
                                ? Icons.videocam
                                : Icons.photo,
                            size: 48,
                          ),
                        ),
                      )
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
}
