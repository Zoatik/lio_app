class RewardCard {
  const RewardCard({
    required this.id,
    required this.mediaId,
    required this.unlocked,
  });

  final String id;
  final String mediaId;
  final bool unlocked;

  RewardCard copyWith({bool? unlocked}) {
    return RewardCard(
      id: id,
      mediaId: mediaId,
      unlocked: unlocked ?? this.unlocked,
    );
  }

  factory RewardCard.fromJson(Map<String, dynamic> json) {
    return RewardCard(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mediaId': mediaId,
      'unlocked': unlocked,
    };
  }
}
