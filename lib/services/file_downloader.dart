import 'package:dio/dio.dart';

import 'file_downloader_stub.dart'
    if (dart.library.io) 'file_downloader_io.dart';

abstract class FileDownloader {
  Future<String> download({
    required Dio dio,
    required Uri url,
    required Map<String, String> headers,
  });
}

FileDownloader getFileDownloader() => createFileDownloader();
