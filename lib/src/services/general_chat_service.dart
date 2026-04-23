import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';

abstract class GeneralChatService {
  Future<AiAssistantResponse> sendMessage({
    required String prompt,
    required AiActionType actionType,
    List<ChatMessageModel> history,
  });
}
