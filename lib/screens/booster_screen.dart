import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/reward_media.dart';
import 'media_viewer_screen.dart';

class BoosterScreen extends StatefulWidget {
  const BoosterScreen({
    super.key,
    required this.media,
    required this.onDone,
    this.showTutorial = false,
    this.startOpened = false,
  });

  final List<RewardMedia> media;
  final VoidCallback onDone;
  final bool showTutorial;
  final bool startOpened;

  @override
  State<BoosterScreen> createState() => _BoosterScreenState();
}

class _BoosterScreenState extends State<BoosterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _packScale;
  late final Animation<double> _packRotate;
  late final Animation<double> _burst;
  bool _opened = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _packScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);
    _packRotate = Tween(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _burst = CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo);
    _showTutorial = widget.showTutorial;
    _opened = widget.startOpened;
    if (_opened) {
      _controller.value = 1.0;
    } else {
      _startIdleShake();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openBooster() {
    if (_opened) {
      return;
    }
    setState(() {
      _opened = true;
    });
    _controller.stop();
    _controller.forward(from: 0);
  }

  Future<void> _startIdleShake() async {
    while (mounted && !_opened) {
      await _controller.forward(from: 0);
      if (!mounted || _opened) {
        break;
      }
      await _controller.reverse(from: 1);
      if (!mounted || _opened) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted || _opened) {
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B3A8D),
                  Color(0xFF1F6FEB),
                  Color(0xFFFFC928),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Ouverture du booster',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_opened && _burst.value < 0.9)
                                CustomPaint(
                                  size: const Size(260, 260),
                                  painter: _BurstPainter(_burst.value),
                                ),
                              Opacity(
                                opacity: _opened ? 0.0 : 1.0,
                                child: Transform.rotate(
                                  angle: _packRotate.value,
                                  child: Transform.scale(
                                    scale: _packScale.value,
                                    child: _BoosterButton(onTap: _openBooster),
                                  ),
                                ),
                              ),
                              if (_opened)
                                _StaggeredCards(
                                  media: widget.media,
                                  progress: _controller.value,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _opened ? widget.onDone : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF0B1B3B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Continuer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showTutorial)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _showTutorial = false;
                  });
                },
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
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
                      child: const Text(
                        'Tu as gagné ton premier booster. Il contient des photos et vidéos souvenirs.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 230),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 77),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Ouvrir',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _BoosterCards extends StatelessWidget {
  const _BoosterCards({required this.media});

  final List<RewardMedia> media;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 230),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text('Aucune carte à débloquer.'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      itemCount: media.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final item = media[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                item.coverPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.black12,
                  child: const Icon(Icons.photo, size: 40),
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
        );
      },
    );
  }
}

class _StaggeredCards extends StatelessWidget {
  const _StaggeredCards({
    required this.media,
    required this.progress,
  });

  final List<RewardMedia> media;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const _BoosterCards(media: []);
    }

    final items = media.take(6).toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(items.length, (index) {
        final start = 0.3 + index * 0.08;
        final end = start + 0.35;
        final t = ((progress - start) / (end - start)).clamp(0.0, 1.0);
        final scale = Tween<double>(begin: 0.6, end: 1.0)
            .transform(Curves.easeOutBack.transform(t));
        final opacity = Tween<double>(begin: 0.0, end: 1.0)
            .transform(Curves.easeIn.transform(t));
        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 120,
              height: 170,
              child: _CardFace(item: items[index]),
            ),
          ),
        );
      }),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.item});

  final RewardMedia item;

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    final hasImageCover = _isImagePath(item.coverPath);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MediaViewerScreen(media: item),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 153)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final rays = 12;
    for (var i = 0; i < rays; i++) {
      final angle = (i / rays) * 6.283185;
      final length = 40 + 80 * t;
      final dx = center.dx + length * math.cos(angle);
      final dy = center.dy + length * math.sin(angle);
      canvas.drawLine(center, Offset(dx, dy), paint);
    }

    final glowPaint = Paint()
      ..color = const Color(0xFFFFF3C0)
          .withValues(alpha: ((0.5 * (1 - t)) * 255).round().toDouble())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, 60 + 90 * t, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
