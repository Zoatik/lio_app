import 'package:video_player/video_player.dart';
import 'package:flutter/widgets.dart';

import 'file_media_helper_stub.dart'
    if (dart.library.io) 'file_media_helper_io.dart';

abstract class FileMediaHelper {
  Widget imageFromFile(String path, BoxFit fit);
  VideoPlayerController videoControllerFromFile(String path);
}

FileMediaHelper getFileMediaHelper() => createFileMediaHelper();
