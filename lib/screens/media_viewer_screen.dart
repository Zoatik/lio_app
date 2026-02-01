import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/reward_media.dart';

class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({super.key, required this.media});

  final RewardMedia media;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.media.type == RewardMediaType.video) {
      _controller = VideoPlayerController.asset(widget.media.path)
        ..initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
          _controller?.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.media.type == RewardMediaType.photo
            ? 'Photo'
            : 'Vidéo'),
      ),
      body: Center(
        child: widget.media.type == RewardMediaType.photo
            ? Image.asset(
                widget.media.path,
                fit: BoxFit.contain,
              )
            : _buildVideo(),
      ),
      floatingActionButton: widget.media.type == RewardMediaType.video
          ? FloatingActionButton(
              onPressed: () {
                if (_controller == null) {
                  return;
                }
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
              child: Icon(
                _controller?.value.isPlaying == true
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            )
          : null,
    );
  }

  Widget _buildVideo() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const CircularProgressIndicator();
    }
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}
