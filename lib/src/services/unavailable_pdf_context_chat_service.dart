import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import 'pdf_context_chat_service.dart';

class UnavailablePdfContextChatService implements PdfContextChatService {
  const UnavailablePdfContextChatService();

  @override
  Future<AiAssistantResponse> sendMessage({
    required String prompt,
    required PdfDocumentModel document,
    required AiActionType actionType,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) {
    throw StateError(
      'AI is not connected yet. Start the backend and try again.',
    );
  }
}
