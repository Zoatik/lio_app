class DavFile {
  const DavFile({
    required this.name,
    required this.size,
    required this.mimeType,
    required this.lastModified,
    required this.url,
  });

  final String name;
  final int size;
  final String mimeType;
  final DateTime? lastModified;
  final Uri url;
}
