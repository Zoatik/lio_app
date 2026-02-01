import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/reward_media.dart';
import '../services/file_media_helper.dart';
import '../services/media_cache_service.dart';
import '../services/web_blob_url.dart';
import '../storage/credentials_storage.dart';

class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({super.key, required this.media});

  final RewardMedia media;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _controller;
  Uri? _blobUrl;

  @override
  void initState() {
    super.initState();
    if (widget.media.type == RewardMediaType.video) {
      _initVideo();
    }
  }

  @override
  void dispose() {
    if (_blobUrl != null) {
      revokeBlobUrl(_blobUrl!);
      _blobUrl = null;
    }
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    final path = widget.media.path;
    if (path.startsWith('http')) {
      try {
        final headers = const CredentialsStorage().authHeadersSync();
        if (kIsWeb) {
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
            throw Exception('Video download failed.');
          }
          _blobUrl = await createBlobUrlFromBytes(
            Uint8List.fromList(bytes),
            mimeType: 'video/mp4',
          );
          if (_blobUrl == null) {
            throw Exception('Blob URL creation failed.');
          }
          _controller = VideoPlayerController.networkUrl(_blobUrl!);
        } else {
          _controller = VideoPlayerController.networkUrl(
            Uri.parse(path),
            httpHeaders: headers,
          );
        }
        await _controller!.initialize();
        if (!mounted) {
          return;
        }
        setState(() {});
        _controller!.play();
        return;
      } catch (_) {
        // fallback below
      }
    }

    if (!kIsWeb) {
      final cached =
          await MediaCacheService().getCachedPath(widget.media.id);
      if (cached != null) {
        _controller = getFileMediaHelper().videoControllerFromFile(cached);
        await _controller!.initialize();
        if (!mounted) {
          return;
        }
        setState(() {});
        _controller!.play();
        return;
      }
    }

    if (!path.startsWith('http')) {
      _controller = VideoPlayerController.asset(path)
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.media.type == RewardMediaType.photo
            ? 'Photo'
            : 'Vidéo'),
      ),
      body: Center(
        child: widget.media.type == RewardMediaType.photo
            ? _buildPhoto()
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

  Widget _buildPhoto() {
    final path = widget.media.path;
    if (path.startsWith('http')) {
      if (!kIsWeb) {
        return FutureBuilder<String?>(
          future: MediaCacheService().getCachedPath(widget.media.id),
          builder: (context, snapshot) {
            final cached = snapshot.data;
            if (cached != null) {
              return getFileMediaHelper()
                  .imageFromFile(cached, BoxFit.contain);
            }
            final headers = const CredentialsStorage().authHeadersSync();
            return Image.network(
              path,
              headers: headers,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            );
          },
        );
      }
      final headers = const CredentialsStorage().authHeadersSync();
      return Image.network(
        path,
        headers: headers,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
    );
  }
}
