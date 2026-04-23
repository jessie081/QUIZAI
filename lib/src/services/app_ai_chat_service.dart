import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import 'ai_chat_service.dart';
import 'general_chat_service.dart';
import 'pdf_context_chat_service.dart';

class AppAiChatService implements AiChatService {
  AppAiChatService({
    required GeneralChatService generalChatService,
    required PdfContextChatService pdfContextChatService,
  })  : _generalChatService = generalChatService,
        _pdfContextChatService = pdfContextChatService;

  final GeneralChatService _generalChatService;
  final PdfContextChatService _pdfContextChatService;

  @override
  Future<AiAssistantResponse> sendMessage({
    required String prompt,
    required AiChatMode mode,
    required AiActionType actionType,
    PdfDocumentModel? document,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) {
    if (mode == AiChatMode.general) {
      return _generalChatService.sendMessage(
        prompt: prompt,
        actionType: actionType,
        history: history,
      );
    }

    if (document == null) {
      throw StateError('PDF mode requires a document context.');
    }

    return _pdfContextChatService.sendMessage(
      prompt: prompt,
      document: document,
      actionType: actionType,
      history: history,
    );
  }
}
