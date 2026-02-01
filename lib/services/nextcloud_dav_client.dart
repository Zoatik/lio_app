import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../models/dav_file.dart';
import 'file_downloader.dart';

class NextcloudDavClient {
  NextcloudDavClient({
    required this.baseUrl,
    required this.username,
    required this.appPassword,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  static Future<void> _queue = Future.value();
  static const Duration _minDelay = Duration(milliseconds: 300);

  final String baseUrl;
  final String username;
  final String appPassword;
  final Dio _dio;

  String get _authHeader {
    final raw = '$username:$appPassword';
    final encoded = base64Encode(utf8.encode(raw));
    return 'Basic $encoded';
  }

  Uri _rootUri() {
    if (baseUrl.contains('workers.dev')) {
      return Uri.parse('$baseUrl/');
    }
    return Uri.parse('$baseUrl/remote.php/dav/files/$username/');
  }

  Uri buildUri(String relativePath) {
    final normalized = relativePath.replaceAll('\\', '/');
    final root = _rootUri();
    return root.resolve(_encodePath(normalized));
  }

  Future<List<DavFile>> listFiles(String relativePath) async {
    return _enqueue(() async {
      final uri = buildUri(relativePath);
      try {
        final response = await _dio.request<String>(
          uri.toString(),
          data: _propfindBody,
          options: Options(
            method: 'PROPFIND',
            headers: {
              'Authorization': _authHeader,
              'Depth': '1',
              'Content-Type': 'application/xml',
            },
            responseType: ResponseType.plain,
          ),
        );

        final raw = response.data ?? '';
        if (raw.isEmpty) {
          return [];
        }

        final document = XmlDocument.parse(raw);
        final responses = _findElementsByLocalName(document, 'response');
        final items = <DavFile>[];

        for (final node in responses) {
          final href = _firstElementText(node, 'href');
          if (href == null) {
            continue;
          }
          final decodedHref = Uri.decodeFull(href);
          final isCollection = _findElementsByLocalName(node, 'collection').isNotEmpty;
          if (isCollection) {
            continue;
          }

          final displayName =
              _firstElementText(node, 'displayname') ?? p.basename(decodedHref);
          final contentLength = int.tryParse(
                _firstElementText(node, 'getcontentlength') ?? '',
              ) ??
              0;
          final contentType =
              _firstElementText(node, 'getcontenttype') ??
                  'application/octet-stream';
          final lastModifiedRaw = _firstElementText(node, 'getlastmodified');
          final lastModified = lastModifiedRaw != null
              ? DateTime.tryParse(lastModifiedRaw)
              : null;

          final fileUrl = _resolveFileUrl(href);

          // Ignore the folder itself (first response) by comparing paths.
          if (_isSameResource(uri, fileUrl)) {
            continue;
          }

          items.add(
            DavFile(
              name: displayName,
              size: contentLength,
              mimeType: contentType,
              lastModified: lastModified,
              url: fileUrl,
            ),
          );
        }

        return items;
      } on DioException catch (e) {
        if (e.response?.statusCode == 429) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
          return await listFiles(relativePath);
        }
        _throwReadable(e);
      }
    });
  }

  Future<String> downloadFile(Uri fileUrl) async {
    if (kIsWeb) {
      throw UnsupportedError('Download to local file is not supported on web.');
    }
    try {
      final downloader = getFileDownloader();
      return await downloader.download(
        dio: _dio,
        url: fileUrl,
        headers: {'Authorization': _authHeader},
      );
    } on DioException catch (e) {
      _throwReadable(e);
    }
  }

  Map<String, String> authHeaders() {
    return {'Authorization': _authHeader};
  }

  bool _isSameResource(Uri folderUri, Uri fileUri) {
    final folderPath = folderUri.path.endsWith('/')
        ? folderUri.path
        : '${folderUri.path}/';
    return fileUri.path == folderPath || fileUri.path == folderUri.path;
  }

  Never _throwReadable(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      throw Exception('Acces refuse (authentification invalide).');
    }
    if (status == 404) {
      throw Exception('Dossier introuvable (404).');
    }
    throw Exception('Erreur WebDAV: ${status ?? 'inconnue'}');
  }

  Uri _resolveFileUrl(String href) {
    if (!baseUrl.contains('workers.dev')) {
      return Uri.parse('$baseUrl$href');
    }
    final prefix = '/remote.php/dav/files/$username/';
    if (href.startsWith(prefix)) {
      final suffix = href.substring(prefix.length);
      return Uri.parse('$baseUrl/dav/$suffix');
    }
    return Uri.parse('$baseUrl$href');
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      await Future<void>.delayed(_minDelay);
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  String _encodePath(String input) {
    return input
        .split('/')
        .map((segment) => Uri.encodeComponent(segment))
        .join('/');
  }

  List<XmlElement> _findElementsByLocalName(XmlNode node, String name) {
    return node
        .findAllElements('*')
        .where((element) => element.name.local == name)
        .toList();
  }

  String? _firstElementText(XmlNode node, String name) {
    final matches = _findElementsByLocalName(node, name);
    if (matches.isEmpty) {
      return null;
    }
    return matches.first.innerText;
  }
}

const _propfindBody = '''
<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname />
    <d:getcontentlength />
    <d:getcontenttype />
    <d:getlastmodified />
    <d:resourcetype />
  </d:prop>
</d:propfind>
''';

extension _XmlFirstOrNull on Iterable<XmlElement> {
  XmlElement? get firstOrNull => isEmpty ? null : first;
}
