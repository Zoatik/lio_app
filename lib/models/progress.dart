class AppProgress {
  const AppProgress({
    required this.completedQuizzIds,
    required this.unlockedMediaIds,
  });

  final Set<String> completedQuizzIds;
  final Set<String> unlockedMediaIds;

  factory AppProgress.empty() {
    return const AppProgress(
      completedQuizzIds: {},
      unlockedMediaIds: {},
    );
  }

  AppProgress copyWith({
    Set<String>? completedQuizzIds,
    Set<String>? unlockedMediaIds,
  }) {
    return AppProgress(
      completedQuizzIds: completedQuizzIds ?? this.completedQuizzIds,
      unlockedMediaIds: unlockedMediaIds ?? this.unlockedMediaIds,
    );
  }

  factory AppProgress.fromJson(Map<String, dynamic> json) {
    return AppProgress(
      completedQuizzIds: Set<String>.from(
        (json['completedQuizzIds'] as List<dynamic>? ?? [])
            .map((value) => value as String),
      ),
      unlockedMediaIds: Set<String>.from(
        (json['unlockedMediaIds'] as List<dynamic>? ?? [])
            .map((value) => value as String),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedQuizzIds': completedQuizzIds.toList(),
      'unlockedMediaIds': unlockedMediaIds.toList(),
    };
  }
}
