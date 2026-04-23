import 'question_model.dart';

class QuizModel {
  QuizModel({
    required this.id,
    required this.title,
    required this.sourcePdfId,
    required this.sourcePdfName,
    required this.sourcePdfText,
    required this.questions,
    required this.createdAt,
    this.summary,
    this.difficulty = 'Mixed',
  });

  final String id;
  final String title;
  final String sourcePdfId;
  final String sourcePdfName;
  final String sourcePdfText;
  final List<QuestionModel> questions;
  final DateTime createdAt;
  final String? summary;
  final String difficulty;

  int get totalQuestions => questions.length;

  QuizModel copyWith({
    String? id,
    String? title,
    String? sourcePdfId,
    String? sourcePdfName,
    String? sourcePdfText,
    List<QuestionModel>? questions,
    DateTime? createdAt,
    String? summary,
    String? difficulty,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      sourcePdfId: sourcePdfId ?? this.sourcePdfId,
      sourcePdfName: sourcePdfName ?? this.sourcePdfName,
      sourcePdfText: sourcePdfText ?? this.sourcePdfText,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      summary: summary ?? this.summary,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sourcePdfId': sourcePdfId,
      'sourcePdfName': sourcePdfName,
      'sourcePdfText': sourcePdfText,
      'questions': questions.map((question) => question.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'summary': summary,
      'difficulty': difficulty,
    };
  }

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as String,
      title: json['title'] as String,
      sourcePdfId: json['sourcePdfId'] as String,
      sourcePdfName: json['sourcePdfName'] as String? ?? 'Unknown PDF',
      sourcePdfText: json['sourcePdfText'] as String? ?? '',
      questions: (json['questions'] as List<dynamic>)
          .map(
            (question) => QuestionModel.fromJson(
              Map<String, dynamic>.from(question as Map),
            ),
          )
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      summary: json['summary'] as String?,
      difficulty: json['difficulty'] as String? ?? 'Mixed',
    );
  }
}
