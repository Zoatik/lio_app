import 'dart:typed_data';

import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart';

Future<void> downloadBytes(
  Uint8List bytes, {
  required String filename,
  String mimeType = 'application/octet-stream',
}) =>
    downloadBytesImpl(bytes, filename: filename, mimeType: mimeType);
