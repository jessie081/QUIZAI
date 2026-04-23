enum QuizQuestionType {
  multipleChoice,
  trueFalse,
  identification,
  shortAnswer,
}

class QuizSettingsModel {
  const QuizSettingsModel({
    this.difficulty = 'medium',
    this.multipleChoiceCount = 5,
    this.trueFalseCount = 0,
    this.identificationCount = 0,
    this.shortAnswerCount = 0,
  });

  final String difficulty;
  final int multipleChoiceCount;
  final int trueFalseCount;
  final int identificationCount;
  final int shortAnswerCount;

  int get totalQuestions =>
      multipleChoiceCount +
      trueFalseCount +
      identificationCount +
      shortAnswerCount;

  Map<QuizQuestionType, int> get questionCounts {
    return <QuizQuestionType, int>{
      QuizQuestionType.multipleChoice: multipleChoiceCount,
      QuizQuestionType.trueFalse: trueFalseCount,
      QuizQuestionType.identification: identificationCount,
      QuizQuestionType.shortAnswer: shortAnswerCount,
    };
  }

  List<QuizQuestionType> get includedTypes {
    return questionCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
  }

  int countFor(QuizQuestionType type) {
    return questionCounts[type] ?? 0;
  }

  QuizSettingsModel copyWith({
    String? difficulty,
    int? multipleChoiceCount,
    int? trueFalseCount,
    int? identificationCount,
    int? shortAnswerCount,
  }) {
    return QuizSettingsModel(
      difficulty: difficulty ?? this.difficulty,
      multipleChoiceCount: multipleChoiceCount ?? this.multipleChoiceCount,
      trueFalseCount: trueFalseCount ?? this.trueFalseCount,
      identificationCount: identificationCount ?? this.identificationCount,
      shortAnswerCount: shortAnswerCount ?? this.shortAnswerCount,
    );
  }
}
