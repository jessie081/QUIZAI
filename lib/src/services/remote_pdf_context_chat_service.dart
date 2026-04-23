import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import 'ai_request_payload_factory.dart';
import 'backend_api_client.dart';
import 'pdf_context_chat_service.dart';

class RemotePdfContextChatService implements PdfContextChatService {
  const RemotePdfContextChatService(this._apiClient);

  final BackendApiClient _apiClient;

  @override
  Future<AiAssistantResponse> sendMessage({
    required String prompt,
    required PdfDocumentModel document,
    required AiActionType actionType,
    List<ChatMessageModel> history = const <ChatMessageModel>[],
  }) async {
    final json = await _apiClient.postJson(
      '/chat/pdf',
      body: AiRequestPayloadFactory.buildPdfPayload(
        prompt: prompt,
        document: document,
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
