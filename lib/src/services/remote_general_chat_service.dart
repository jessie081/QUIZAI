import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import 'ai_request_payload_factory.dart';
import 'backend_api_client.dart';
import 'general_chat_service.dart';

class RemoteGeneralChatService implements GeneralChatService {
  const RemoteGeneralChatService(this._apiClient);

  final BackendApiClient _apiClient;

  @override
  Future<AiAssistantResponse> sendMessage({
    required String prompt,
    required AiActionType actionType,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) async {
    final json = await _apiClient.postJson(
      '/chat/general',
      body: AiRequestPayloadFactory.buildGeneralPayload(
        prompt: prompt,
        actionType: actionType,
        history: history,
      ),
    );

    return _parseAssistantResponse(json);
  }

  AiAssistantResponse _parseAssistantResponse(Map<String, dynamic> json) {
    return AiAssistantResponse(
      message: json['message'] as String? ?? 'No response returned.',
      citedSnippets: List<String>.from(
        json['citations'] as List? ?? const <String>[],
      ),
      suggestedPrompts: (json['suggested_prompts'] as List? ?? const [])
          .map(
            (prompt) => _parsePrompt(
              Map<String, dynamic>.from(prompt as Map),
            ),
          )
          .toList(),
    );
  }

  AiPromptSuggestion _parsePrompt(Map<String, dynamic> json) {
    final rawActionType = json['action_type'] as String? ?? AiActionType.ask.name;
    return AiPromptSuggestion(
      label: json['label'] as String? ?? 'Ask follow-up',
      prompt: json['prompt'] as String? ?? '',
      actionType: AiActionType.values.firstWhere(
        (value) => value.name == rawActionType,
        orElse: () => AiActionType.ask,
      ),
    );
  }
}
