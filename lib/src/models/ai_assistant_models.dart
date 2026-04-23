enum AiChatMode {
  general,
  pdf,
}

enum AiActionType {
  ask,
  summarizePdf,
  explainKeyConcepts,
  makeStudyGuide,
  generateQuiz,
  explainMistakes,
  summarizeSection,
}

extension AiChatModeX on AiChatMode {
  String get label {
    switch (this) {
      case AiChatMode.general:
        return 'General';
      case AiChatMode.pdf:
        return 'This PDF';
    }
  }
}

class AiPromptSuggestion {
  const AiPromptSuggestion({
    required this.label,
    required this.prompt,
    required this.actionType,
  });

  final String label;
  final String prompt;
  final AiActionType actionType;
}

class AiAssistantResponse {
  const AiAssistantResponse({
    required this.message,
    this.citedSnippets = const <String>[],
    this.suggestedPrompts = const <AiPromptSuggestion>[],
  });

  final String message;
  final List<String> citedSnippets;
  final List<AiPromptSuggestion> suggestedPrompts;
}
