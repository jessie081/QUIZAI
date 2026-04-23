import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import '../models/quiz_model.dart';
import 'quiz_generation_service.dart';

class QuizAnswerExplanationRequest {
  const QuizAnswerExplanationRequest({
    required this.quizTitle,
    required this.questionPrompt,
    required this.correctAnswer,
    this.userAnswer,
    this.message,
  });

  final String quizTitle;
  final String questionPrompt;
  final String correctAnswer;
  final String? userAnswer;
  final String? message;
}

abstract class AiService {
  Future<AiAssistantResponse> sendGeneralMessage({
    required String prompt,
    required AiActionType actionType,
    List<ChatMessageModel> history,
  });

  Future<AiAssistantResponse> sendPdfMessage({
    required String prompt,
    required PdfDocumentModel document,
    required AiActionType actionType,
    List<ChatMessageModel> history,
  });

  Future<QuizModel> generateQuiz({
    required QuizGenerationRequest request,
  });

  Future<AiAssistantResponse> explainQuizAnswer({
    required PdfDocumentModel document,
    required QuizAnswerExplanationRequest request,
    List<ChatMessageModel> history,
  });
}
