import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'file_media_helper.dart';

class _FileMediaHelperIo implements FileMediaHelper {
  @override
  Widget imageFromFile(String path, BoxFit fit) {
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  VideoPlayerController videoControllerFromFile(String path) {
    return VideoPlayerController.file(File(path));
  }
}

FileMediaHelper createFileMediaHelper() => _FileMediaHelperIo();
