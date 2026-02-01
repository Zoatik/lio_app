enum RewardMediaType {
  photo,
  video;

  static RewardMediaType fromJson(String value) {
    switch (value) {
      case 'photo':
        return RewardMediaType.photo;
      case 'video':
        return RewardMediaType.video;
      default:
        throw ArgumentError('Unknown reward media type: $value');
    }
  }

  String toJson() {
    switch (this) {
      case RewardMediaType.photo:
        return 'photo';
      case RewardMediaType.video:
        return 'video';
    }
  }
}

class RewardMedia {
  const RewardMedia({
    required this.id,
    required this.quizzId,
    required this.type,
    required this.path,
    required this.coverPath,
  });

  final String id;
  final String quizzId;
  final RewardMediaType type;
  final String path;
  final String coverPath;

  factory RewardMedia.fromJson(Map<String, dynamic> json) {
    return RewardMedia.fromJsonWithQuizzId(json, json['quizzId'] as String?);
  }

  factory RewardMedia.fromJsonWithQuizzId(
    Map<String, dynamic> json,
    String? quizzId,
  ) {
    final path = json['path'] as String?;
    final cover = json['coverPath'] as String? ?? path;
    final resolvedQuizzId = quizzId ?? json['quizzId'] as String? ?? '';
    if (path == null || cover == null) {
      throw ArgumentError('RewardMedia requires path/coverPath');
    }
    return RewardMedia(
      id: json['id'] as String,
      quizzId: resolvedQuizzId,
      type: RewardMediaType.fromJson(json['type'] as String),
      path: path,
      coverPath: cover,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizzId': quizzId,
      'type': type.toJson(),
      'path': path,
      'coverPath': coverPath,
    };
  }
}
