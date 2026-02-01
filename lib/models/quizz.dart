import 'reward_media.dart';

enum QuizzType {
  multipleChoice,
  text;

  static QuizzType fromJson(String value) {
    switch (value) {
      case 'multiple_choice':
        return QuizzType.multipleChoice;
      case 'text':
        return QuizzType.text;
      default:
        throw ArgumentError('Unknown quizz type: $value');
    }
  }
}

class QuizzReward {
  const QuizzReward({
    required this.folder,
  });

  final String folder;

  factory QuizzReward.fromJson(Map<String, dynamic> json) {
    return QuizzReward(
      folder: json['folder'] as String,
    );
  }
}

class Quizz {
  const Quizz({
    required this.id,
    required this.title,
    required this.question,
    required this.type,
    required this.reward,
    required this.message,
    this.choices,
    this.correctIndex,
    this.acceptedAnswers,
    this.questionImages,
    this.rewardMedia = const [],
    this.allowAnyAnswer = false,
    this.isTutorial = false,
  });

  final String id;
  final String title;
  final String question;
  final QuizzType type;
  final QuizzReward reward;
  final String message;
  final List<String>? choices;
  final int? correctIndex;
  final List<String>? acceptedAnswers;
  final List<String>? questionImages;
  final List<RewardMedia> rewardMedia;
  final bool allowAnyAnswer;
  final bool isTutorial;

  Quizz copyWith({
    List<RewardMedia>? rewardMedia,
    bool? isTutorial,
  }) {
    return Quizz(
      id: id,
      title: title,
      question: question,
      type: type,
      reward: reward,
      message: message,
      choices: choices,
      correctIndex: correctIndex,
      acceptedAnswers: acceptedAnswers,
      questionImages: questionImages,
      rewardMedia: rewardMedia ?? this.rewardMedia,
      allowAnyAnswer: allowAnyAnswer,
      isTutorial: isTutorial ?? this.isTutorial,
    );
  }

  factory Quizz.fromJson(Map<String, dynamic> json) {
    final type = QuizzType.fromJson(json['type'] as String);
    return Quizz(
      id: json['id'] as String,
      title: json['title'] as String,
      question: json['question'] as String,
      type: type,
      reward: QuizzReward.fromJson(json['reward'] as Map<String, dynamic>),
      message: json['message'] as String? ?? '',
      choices: (json['choices'] as List<dynamic>?)
          ?.map((value) => value as String)
          .toList(),
      correctIndex: json['correctIndex'] as int?,
      acceptedAnswers: (json['acceptedAnswers'] as List<dynamic>?)
          ?.map((value) => value as String)
          .toList(),
      questionImages: (json['questionImages'] as List<dynamic>?)
          ?.map((value) => value as String)
          .toList(),
      rewardMedia: (json['rewardMedia'] as List<dynamic>?)
              ?.map((value) => RewardMedia.fromJsonWithQuizzId(
                    value as Map<String, dynamic>,
                    json['id'] as String?,
                  ))
              .toList() ??
          const [],
      allowAnyAnswer: json['allowAnyAnswer'] as bool? ?? false,
      isTutorial: json['isTutorial'] as bool? ?? false,
    );
  }

  bool isCorrectAnswer(String input) {
    if (allowAnyAnswer) {
      return true;
    }
    switch (type) {
      case QuizzType.multipleChoice:
        return false;
      case QuizzType.text:
        if (acceptedAnswers == null || acceptedAnswers!.isEmpty) {
          return false;
        }
        final normalizedInput = _normalize(input);
        return acceptedAnswers!
            .map(_normalize)
            .contains(normalizedInput);
    }
  }

  bool isCorrectChoice(int index) {
    if (allowAnyAnswer) {
      return true;
    }
    if (type != QuizzType.multipleChoice) {
      return false;
    }
    return correctIndex != null && index == correctIndex;
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
