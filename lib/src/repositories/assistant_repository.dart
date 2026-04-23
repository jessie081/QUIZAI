import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import '../services/ai_service.dart';

class AssistantRepository {
  const AssistantRepository(this._service);

  final AiService _service;

  Future<AiAssistantResponse> ask({
    required String prompt,
    required AiChatMode mode,
    PdfDocumentModel? document,
    required AiActionType actionType,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) {
    switch (mode) {
      case AiChatMode.general:
        return _service.sendGeneralMessage(
          prompt: prompt,
          actionType: actionType,
          history: history,
        );
      case AiChatMode.pdf:
        final doc = document;
        if (doc == null) {
          throw StateError('PDF mode requires a document context.');
        }
        return _service.sendPdfMessage(
          prompt: prompt,
          document: doc,
          actionType: actionType,
          history: history,
        );
    }
  }

  Future<AiAssistantResponse> explainQuizAnswer({
    required PdfDocumentModel document,
    required QuizAnswerExplanationRequest request,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) {
    return _service.explainQuizAnswer(
      document: document,
      request: request,
      history: history,
    );
  }
}
