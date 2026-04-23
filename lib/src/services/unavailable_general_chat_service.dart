import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import 'general_chat_service.dart';

class UnavailableGeneralChatService implements GeneralChatService {
  const UnavailableGeneralChatService();

  @override
  Future<AiAssistantResponse> sendMessage({
    required String prompt,
    required AiActionType actionType,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) {
    throw StateError(
      'AI is not connected yet. Start the backend and try again.',
    );
  }
}
