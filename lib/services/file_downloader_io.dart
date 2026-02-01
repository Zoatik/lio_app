import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'file_downloader.dart';

class _IoDownloader implements FileDownloader {
  @override
  Future<String> download({
    required Dio dio,
    required Uri url,
    required Map<String, String> headers,
  }) async {
    final dir = await getTemporaryDirectory();
    final filename = p.basename(url.path);
    final filePath = p.join(dir.path, filename);

    await dio.download(
      url.toString(),
      filePath,
      options: Options(headers: headers),
    );

    return filePath;
  }
}

FileDownloader createFileDownloader() => _IoDownloader();
