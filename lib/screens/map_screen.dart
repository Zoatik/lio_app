import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/quizzs_repository.dart';
import '../models/progress.dart';
import '../models/quizz.dart';
import '../storage/progress_storage.dart';
import '../storage/tutorial_storage.dart';
import 'booster_screen.dart';
import 'inventory_screen.dart';
import 'quiz_screen.dart';
import '../services/media_cache_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _repository = const QuizzsRepository();
  final _storage = const ProgressStorage();

  List<Quizz> _quizzs = [];
  AppProgress _progress = AppProgress.empty();
  bool _loading = true;
  bool _showTutorial = false;
  int _tutorialStep = 0;
  bool _showCongrats = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final quizzs = await _repository.load();
    final progress = await _storage.load();
    final showTutorial = await const TutorialStorage().shouldShow();
    final showFinal = await const TutorialStorage().shouldShowFinalMessage();
    if (!mounted) {
      return;
    }
    setState(() {
      _quizzs = quizzs.where((q) => !q.isTutorial).toList();
      _progress = progress;
      _loading = false;
      _showTutorial = showTutorial;
      _tutorialStep = 0;
      _showCongrats = showFinal &&
          _quizzs.isNotEmpty &&
          _quizzs.every((q) => progress.completedQuizzIds.contains(q.id));
    });
  }

  Future<void> _completeQuizz(Quizz quizz) async {
    final completed = Set<String>.from(_progress.completedQuizzIds)
      ..add(quizz.id);
    final unlocked = Set<String>.from(_progress.unlockedMediaIds)
      ..addAll(quizz.rewardMedia.map((media) => media.id));
    final updated = _progress.copyWith(
      completedQuizzIds: completed,
      unlockedMediaIds: unlocked,
    );
    await _storage.save(updated);
    await MediaCacheService().prefetch(quizz.rewardMedia);
    if (!mounted) {
      return;
    }
    setState(() {
      _progress = updated;
    });
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BoosterScreen(
          media: quizz.rewardMedia,
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
    await _load();
  }

  Future<void> _closeCongrats() async {
    await const TutorialStorage().markFinalMessageSeen();
    if (!mounted) {
      return;
    }
    setState(() {
      _showCongrats = false;
    });
  }

  bool _isUnlocked(int index) {
    if (index == 0) {
      return true;
    }
    final previousId = _quizzs[index - 1].id;
    return _progress.completedQuizzIds.contains(previousId);
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
        title: const Text('Parcours'),
        actions: [
          _InventoryButton(
            highlight: _showTutorial && _tutorialStep == 0,
            onPressed: () {
              if (_showTutorial && _tutorialStep == 0) {
                setState(() {
                  _tutorialStep = 1;
                });
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const InventoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapBackgroundPainter(),
            ),
          ),
          _DuolingoPath(
            quizzs: _quizzs,
            progress: _progress,
            onTap: (quizz) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    quizz: quizz,
                    onCompleted: () {
                      Navigator.of(context).pop();
                      _completeQuizz(quizz);
                    },
                  ),
                ),
              );
            },
            isUnlocked: _isUnlocked,
          ),
          if (_showTutorial)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  if (_tutorialStep < 1) {
                    setState(() {
                      _tutorialStep += 1;
                    });
                    return;
                  }
                  await const TutorialStorage().markSeen();
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _showTutorial = false;
                    _tutorialStep = 0;
                  });
                },
                child: Stack(
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 1,
                      child: Container(
                        color: const Color.fromRGBO(0, 0, 0, 0.2),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 16,
                      left: 16,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 380),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final dy = (1 - value) * 60;
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, dy),
                              child: child,
                            ),
                          );
                        },
                        child: _TutorialCard(
                          text: _tutorialStep == 0
                              ? 'Bravo, tu as gagné tes premières cartes. '
                                  'Tu peux les consulter dans l\'inventaire.'
                              : 'Résous les quizz pour récupérer davantage de cartes.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_showCongrats)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Container(
                  color: const Color.fromRGBO(0, 0, 0, 0.35),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 60),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bravo !',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Cher meilleur ami (aka Lionel), j\'espère que ce petit jeu t\'a plu. '
                            'Moi, je me suis bien marré en le faisant. '
                            'J\'ai surtout adoré traverser toutes ces photos à la recherche de perles rares. '
                            'Et des perles, j\'en ai trouvées ! '
                            'C\'est pas sans émotion que j\'ai pu retracer une partie de notre parcours. '
                            'On est quand même pas très malins... '
                            'Mais à défaut de l\'être, on se marre bien. '
                            'On continuera d\'ailleurs ! '
                            '24 ans c\'est une année de souvenirs en plus. '
                            'Il est 5h03 du matin quand j\'écris et je pense que c\'est justement à cause de cet océan de souvenirs. '
                            'Donc, c\'est pas bien grave. '
                            'Ce sont aussi ces souvenirs qui m\'ont rappelé toute l\'admiration que j\'ai pour toi. '
                            'Tu es quelqu\'un d\'unique et à qui je tiens. '
                            'Ne change pas (juste apprends nos prénoms stp). '
                            'Bon anniversaire Lionel.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                _closeCongrats();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD54F),
                                foregroundColor: const Color(0xFF0B1B3B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Fermer'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _DuolingoPath extends StatelessWidget {
  const _DuolingoPath({
    required this.quizzs,
    required this.progress,
    required this.onTap,
    required this.isUnlocked,
  });

  final List<Quizz> quizzs;
  final AppProgress progress;
  final ValueChanged<Quizz> onTap;
  final bool Function(int) isUnlocked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final nodeSize = 70.0;
        final gap = 110.0;
        final topPadding = 32.0;
        final height =
            topPadding * 2 + (quizzs.length - 1).clamp(0, 999) * gap + nodeSize;

        final points = List.generate(quizzs.length, (index) {
          final t = index * 0.85;
          final x = width / 2 + (width * 0.22) * math.sin(t);
          final y = topPadding + index * gap;
          return Offset(x, y);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SizedBox(
            height: height,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(width, height),
                  painter: _PathPainter(points: points),
                ),
                ...List.generate(quizzs.length, (index) {
                  final quizz = quizzs[index];
                  final isCompleted =
                      progress.completedQuizzIds.contains(quizz.id);
                  final unlocked = isUnlocked(index);
                  final point = points[index];
                  return Positioned(
                    left: point.dx - nodeSize / 2,
                    top: point.dy - nodeSize / 2,
                  child: _LevelPlatform(
                      label: '${index + 1}',
                      title: quizz.title,
                      isCompleted: isCompleted,
                      isUnlocked: unlocked,
                      onTap: unlocked
                          ? () {
                              if (isCompleted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BoosterScreen(
                                      media: quizz.rewardMedia,
                                      startOpened: true,
                                      onDone: () => Navigator.of(context).pop(),
                                    ),
                                  ),
                                );
                              } else {
                                onTap(quizz);
                              }
                            }
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PathPainter extends CustomPainter {
  const _PathPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final control = Offset((prev.dx + current.dx) / 2, prev.dy + 60);
      path.quadraticBezierTo(control.dx, control.dy, current.dx, current.dy);
    }

    final paint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFE6F4FF),
        Color(0xFFFFF4C2),
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    final cloudPaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 190);
    final hillPaint = Paint()..color = const Color(0xFFBEE3F8).withValues(alpha: 200);

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.12), 60, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.12), 75, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.18), 70, cloudPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.18), 50, cloudPaint);

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.95), 160, hillPaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.9), 200, hillPaint);
  }

  @override
  bool shouldRepaint(covariant _MapBackgroundPainter oldDelegate) => false;
}

class _LevelPlatform extends StatelessWidget {
  const _LevelPlatform({
    required this.label,
    required this.title,
    required this.isCompleted,
    required this.isUnlocked,
    required this.onTap,
  });

  final String label;
  final String title;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _LevelNode(
      label: label,
      title: title,
      isCompleted: isCompleted,
      isUnlocked: isUnlocked,
      onTap: onTap,
      compact: true,
    );
  }
}

class _InventoryButton extends StatelessWidget {
  const _InventoryButton({
    required this.onPressed,
    required this.highlight,
  });

  final VoidCallback onPressed;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final icon = IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.collections_bookmark),
      tooltip: 'Inventaire',
    );

    if (!highlight) {
      return icon;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 204),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: icon,
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 38),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.label,
    required this.title,
    required this.isCompleted,
    required this.isUnlocked,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String title;
  final bool isCompleted;
  final bool isUnlocked;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isCompleted
        ? const Color(0xFF22C55E)
        : isUnlocked
            ? colorScheme.primary
            : Colors.grey.shade800;
    final foreground = Colors.white;

    if (compact) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: Colors.grey.shade800,
          disabledForegroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(18),
          elevation: isUnlocked ? 6 : 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(18),
            elevation: isUnlocked ? 6 : 0,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isUnlocked ? Colors.black87 : Colors.black38,
              ),
        ),
      ],
    );
  }
}
