import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/dav_file.dart';
import '../services/nextcloud_dav_client.dart';
import '../storage/credentials_storage.dart';

class WebDavExamples extends StatefulWidget {
  const WebDavExamples({super.key});

  @override
  State<WebDavExamples> createState() => _WebDavExamplesState();
}

class _WebDavExamplesState extends State<WebDavExamples> {
  static const baseUrl = 'https://lioapp.axelhal.workers.dev';
  NextcloudDavClient? _client;
  Future<NextcloudDavClient> _ensureClient() async {
    if (_client != null) {
      return _client!;
    }
    final creds = await const CredentialsStorage().load();
    if (creds == null) {
      throw Exception('Identifiants manquants. Connecte-toi d\'abord.');
    }
    final (user, pass) = creds;
    _client = NextcloudDavClient(
      baseUrl: baseUrl,
      username: user,
      appPassword: pass,
    );
    return _client!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Images de quiz (grille)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: FutureBuilder<List<DavFile>>(
              future: _ensureClient()
                  .then((client) => client.listFiles('dav/Media/quizz_images/quizz1/')),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final files = snapshot.data!;
                final client = _client!;
                return GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        file.url.toString(),
                        fit: BoxFit.cover,
                        headers: client.authHeaders(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Médias (liste)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<DavFile>>(
            future:
                _ensureClient().then((client) => client.listFiles('dav/Media/medias/quizz1/')),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final files = snapshot.data!;
              return Column(
                children: files
                    .map(
                      (file) => ListTile(
                        title: Text(file.name),
                        subtitle: Text(file.mimeType),
                        trailing: const Icon(Icons.play_circle),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WebDavVideoPlayer(
                                file: file,
                                client: _client!,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class WebDavVideoPlayer extends StatefulWidget {
  const WebDavVideoPlayer({
    super.key,
    required this.file,
    required this.client,
  });

  final DavFile file;
  final NextcloudDavClient client;

  @override
  State<WebDavVideoPlayer> createState() => _WebDavVideoPlayerState();
}

class _WebDavVideoPlayerState extends State<WebDavVideoPlayer> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // Try streaming with headers, fallback to download.
    try {
      _controller = VideoPlayerController.networkUrl(
        widget.file.url,
        httpHeaders: widget.client.authHeaders(),
      );
      await _controller!.initialize();
      if (!mounted) {
        return;
      }
      setState(() {});
      _controller!.play();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Streaming non supporté. Utilise le téléchargement local.'),
        ),
      );
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
      appBar: AppBar(title: Text(widget.file.name)),
      body: Center(
        child: _controller == null || !_controller!.value.isInitialized
            ? const CircularProgressIndicator()
            : AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
      ),
    );
  }
}
