import 'dart:typed_data';

import 'web_blob_url_stub.dart'
    if (dart.library.html) 'web_blob_url_web.dart';

Future<Uri?> createBlobUrlFromBytes(
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) =>
    createBlobUrlFromBytesImpl(bytes, mimeType: mimeType);

void revokeBlobUrl(Uri uri) => revokeBlobUrlImpl(uri);
