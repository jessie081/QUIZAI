enum QuestionType {
  multipleChoice,
  trueFalse,
  identification,
  shortAnswer;

  String get typeLabel {
    switch (this) {
      case QuestionType.multipleChoice:
        return "Multiple Choice";
      case QuestionType.trueFalse:
        return "True / False";
      case QuestionType.identification:
        return "Identification";
      case QuestionType.shortAnswer:
        return "Short Answer";
    }
  }
}

class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.type,
    required this.prompt,
    required this.answer,
    this.choices = const <String>[],
    this.explanation,
  });

  final String id;
  final QuestionType type;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String? explanation;

  bool get expectsOptions =>
      type == QuestionType.multipleChoice || type == QuestionType.trueFalse;

  String get typeLabel {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.trueFalse:
        return 'True / False';
      case QuestionType.identification:
        return 'Identification';
      case QuestionType.shortAnswer:
        return 'Short Answer';
    }
  }

  QuestionModel copyWith({
    String? id,
    QuestionType? type,
    String? prompt,
    String? answer,
    List<String>? choices,
    String? explanation,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      answer: answer ?? this.answer,
      choices: choices ?? this.choices,
      explanation: explanation ?? this.explanation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'prompt': prompt,
      'answer': answer,
      'choices': choices,
      'explanation': explanation,
    };
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      type: QuestionType.values.byName(json['type'] as String),
      prompt: json['prompt'] as String,
      answer: json['answer'] as String,
      choices: List<String>.from(json['choices'] as List? ?? const <String>[]),
      explanation: json['explanation'] as String?,
    );
  }
}
