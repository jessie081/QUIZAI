import '../models/ai_assistant_models.dart';

class AiPromptTemplates {
  const AiPromptTemplates._();

  static const List<AiPromptSuggestion> generalActions = <AiPromptSuggestion>[
    AiPromptSuggestion(
      label: 'Ask AI anything',
      prompt: 'Let\'s switch to general chat. I want to ask something unrelated to the PDF.',
      actionType: AiActionType.ask,
    ),
    AiPromptSuggestion(
      label: 'Explain a topic',
      prompt: 'Explain this topic simply and clearly.',
      actionType: AiActionType.ask,
    ),
    AiPromptSuggestion(
      label: 'Brainstorm ideas',
      prompt: 'Help me brainstorm a few strong ideas.',
      actionType: AiActionType.ask,
    ),
  ];

  static const List<AiPromptSuggestion> studyActions = <AiPromptSuggestion>[
    AiPromptSuggestion(
      label: 'Summarize this PDF',
      prompt: 'Summarize this PDF into a concise study overview.',
      actionType: AiActionType.summarizePdf,
    ),
    AiPromptSuggestion(
      label: 'Generate 10 questions',
      prompt: 'Generate 10 mixed quiz questions from this PDF.',
      actionType: AiActionType.generateQuiz,
    ),
    AiPromptSuggestion(
      label: 'Explain key concepts',
      prompt: 'Explain the key concepts from this document in simple terms.',
      actionType: AiActionType.explainKeyConcepts,
    ),
    AiPromptSuggestion(
      label: 'Make a study guide',
      prompt: 'Create a focused study guide from the important ideas in this PDF.',
      actionType: AiActionType.makeStudyGuide,
    ),
  ];

  static const List<AiPromptSuggestion> resultActions = <AiPromptSuggestion>[
    AiPromptSuggestion(
      label: 'Explain my mistakes',
      prompt: 'Explain the common mistakes a student might make on this quiz.',
      actionType: AiActionType.explainMistakes,
    ),
    AiPromptSuggestion(
      label: 'Summarize this section',
      prompt: 'Summarize the section that best supports the quiz answers.',
      actionType: AiActionType.summarizeSection,
    ),
  ];
}
