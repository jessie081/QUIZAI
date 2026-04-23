import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';

abstract class PdfContextChatService {
  Future<AiAssistantResponse> sendMessage({
    required String prompt,
    required PdfDocumentModel document,
    required AiActionType actionType,
    List<ChatMessageModel> history,
  });
}
