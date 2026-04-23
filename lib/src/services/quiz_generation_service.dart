import '../models/quiz_model.dart';
import '../models/quiz_settings_model.dart';

class QuizGenerationRequest {
  const QuizGenerationRequest({
    required this.pdfText,
    required this.sourcePdfId,
    required this.sourcePdfName,
    required this.questionCounts,
    required this.difficulty,
    this.userInstruction,
  });

  final String pdfText;
  final String sourcePdfId;
  final String sourcePdfName;
  final Map<QuizQuestionType, int> questionCounts;
  final String difficulty;
  final String? userInstruction;
}

abstract class QuizGenerationService {
  Future<QuizModel> generateQuizFromText(QuizGenerationRequest request);
}
