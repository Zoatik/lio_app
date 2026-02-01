import 'dart:html' as html;
import 'dart:typed_data';

Future<Uri?> createBlobUrlFromBytesImpl(
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  return Uri.parse(url);
}

void revokeBlobUrlImpl(Uri uri) {
  html.Url.revokeObjectUrl(uri.toString());
}
