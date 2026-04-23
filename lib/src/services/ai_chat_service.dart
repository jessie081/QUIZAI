import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';

abstract class AiChatService {
  Future<AiAssistantResponse> sendMessage({
    required String prompt,
    required AiChatMode mode,
    required AiActionType actionType,
    PdfDocumentModel? document,
    List<ChatMessageModel> history,
  });
}
