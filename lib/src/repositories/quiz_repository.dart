import '../models/quiz_model.dart';
import '../services/local_storage_service.dart';
import '../services/ai_service.dart';
import '../services/quiz_generation_service.dart';

class QuizRepository {
  const QuizRepository({
    required AiService aiService,
    required LocalStorageService localStorageService,
  })  : _aiService = aiService,
        _localStorageService = localStorageService;

  final AiService _aiService;
  final LocalStorageService _localStorageService;

  Future<QuizModel> generateQuiz(QuizGenerationRequest request) async {
    final quiz = await _aiService.generateQuiz(request: request);
    await _localStorageService.saveQuiz(quiz);
    return quiz;
  }

  Future<void> saveQuiz(QuizModel quiz) {
    return _localStorageService.saveQuiz(quiz);
  }

  Future<List<QuizModel>> loadSavedQuizzes() {
    return _localStorageService.loadQuizzes();
  }

  Future<void> deleteQuiz(String quizId) {
    return _localStorageService.deleteQuiz(quizId);
  }
}
