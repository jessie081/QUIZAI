import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import '../models/quiz_model.dart';
import 'ai_service.dart';
import 'quiz_generation_service.dart';

class UnavailableAiService implements AiService {
  const UnavailableAiService();

  @override
  Future<AiAssistantResponse> sendGeneralMessage({
    required String prompt,
    required AiActionType actionType,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) {
    throw StateError(
      'AI is not connected yet. Start the backend and try again.',
    );
  }

  @override
  Future<AiAssistantResponse> sendPdfMessage({
    required String prompt,
    required PdfDocumentModel document,
    required AiActionType actionType,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) {
    throw StateError(
      'AI is not connected yet. Start the backend and try again.',
    );
  }

  @override
  Future<QuizModel> generateQuiz({
    required QuizGenerationRequest request,
  }) {
    throw StateError(
      'AI is not connected yet. Start the backend before generating quizzes.',
    );
  }

  @override
  Future<AiAssistantResponse> explainQuizAnswer({
    required PdfDocumentModel document,
    required QuizAnswerExplanationRequest request,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) {
    throw StateError(
      'AI is not connected yet. Start the backend and try again.',
    );
  }
}
