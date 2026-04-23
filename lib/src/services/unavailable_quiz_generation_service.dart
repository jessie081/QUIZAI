import '../models/quiz_model.dart';
import 'quiz_generation_service.dart';

class UnavailableQuizGenerationService implements QuizGenerationService {
  const UnavailableQuizGenerationService();

  @override
  Future<QuizModel> generateQuizFromText(QuizGenerationRequest request) {
    throw StateError(
      'AI is not connected yet. Start the backend before generating quizzes.',
    );
  }
}
