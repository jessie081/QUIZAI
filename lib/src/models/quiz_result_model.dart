class QuizResultModel {
  QuizResultModel({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.answers,
    DateTime? takenAt,
  }) : takenAt = takenAt ?? DateTime.now();

  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int correctAnswers;
  final Map<String, String> answers;
  final DateTime takenAt;

  double get scorePercent {
    if (totalQuestions == 0) {
      return 0;
    }
    return (correctAnswers / totalQuestions) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'answers': answers,
      'takenAt': takenAt.toIso8601String(),
    };
  }

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      quizId: json['quizId'] as String,
      quizTitle: json['quizTitle'] as String? ?? 'Quiz',
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      answers: Map<String, String>.from(
        json['answers'] as Map? ?? const <String, String>{},
      ),
      takenAt: DateTime.parse(json['takenAt'] as String),
    );
  }
}
