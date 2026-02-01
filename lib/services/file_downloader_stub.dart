import 'package:dio/dio.dart';

import 'file_downloader.dart';

class _StubDownloader implements FileDownloader {
  @override
  Future<String> download({
    required Dio dio,
    required Uri url,
    required Map<String, String> headers,
  }) {
    throw UnsupportedError('Download not supported on this platform.');
  }
}

FileDownloader createFileDownloader() => _StubDownloader();
