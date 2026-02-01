import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'file_media_helper.dart';

class _FileMediaHelperStub implements FileMediaHelper {
  @override
  Widget imageFromFile(String path, BoxFit fit) {
    return const SizedBox.shrink();
  }

  @override
  VideoPlayerController videoControllerFromFile(String path) {
    throw UnsupportedError('File media not supported on web.');
  }
}

FileMediaHelper createFileMediaHelper() => _FileMediaHelperStub();
