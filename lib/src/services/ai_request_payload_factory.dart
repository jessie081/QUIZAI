import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import '../models/quiz_settings_model.dart';
import 'ai_service.dart';
import 'quiz_generation_service.dart';

class AiRequestPayloadFactory {
  const AiRequestPayloadFactory._();

  static const int _maxHistoryMessages = 12;

  static Map<String, dynamic> buildGeneralPayload({
    required String prompt,
    required AiActionType actionType,
    required List<ChatMessageModel> history,
  }) {
    return <String, dynamic>{
      'mode': 'general',
      'message': prompt,
      'action_type': actionType.name,
      'history': _serializeHistory(history),
    };
  }

  static Map<String, dynamic> buildPdfPayload({
    required String prompt,
    required PdfDocumentModel document,
    required AiActionType actionType,
    required List<ChatMessageModel> history,
  }) {
    return <String, dynamic>{
      'mode': 'pdf',
      'message': prompt,
      'action_type': actionType.name,
      'fileName': document.fileName,
      'pdfText': document.extractedText,
      'history': _serializeHistory(history),
    };
  }

  static Map<String, dynamic> buildQuizPayload(
    QuizGenerationRequest request,
  ) {
    return <String, dynamic>{
      'mode': 'quiz',
      'source_pdf_id': request.sourcePdfId,
      'source_pdf_name': request.sourcePdfName,
      'pdf_text': request.pdfText,
      'difficulty': request.difficulty,
      'question_counts': <String, int>{
        'multiple_choice':
            request.questionCounts[QuizQuestionType.multipleChoice] ?? 0,
        'true_false': request.questionCounts[QuizQuestionType.trueFalse] ?? 0,
        'identification':
            request.questionCounts[QuizQuestionType.identification] ?? 0,
        'short_answer':
            request.questionCounts[QuizQuestionType.shortAnswer] ?? 0,
      },
      if (request.userInstruction != null &&
          request.userInstruction!.trim().isNotEmpty)
        'user_instruction': request.userInstruction,
    };
  }

  static Map<String, dynamic> buildQuizExplanationPayload({
    required PdfDocumentModel document,
    required QuizAnswerExplanationRequest request,
    required List<ChatMessageModel> history,
  }) {
    return <String, dynamic>{
      'mode': 'quiz_explanation',
      if (request.message != null && request.message!.trim().isNotEmpty)
        'message': request.message,
      'action_type': AiActionType.explainMistakes.name,
      'document': <String, dynamic>{
        'id': document.id,
        'file_name': document.fileName,
        'text': document.extractedText,
        'word_count': document.wordCount,
        'excerpt': document.previewText,
      },
      'quiz_context': <String, dynamic>{
        'quiz_title': request.quizTitle,
        'question_prompt': request.questionPrompt,
        'correct_answer': request.correctAnswer,
        if (request.userAnswer != null && request.userAnswer!.trim().isNotEmpty)
          'user_answer': request.userAnswer,
      },
      'history': _serializeHistory(history),
    };
  }

  static List<Map<String, dynamic>> _serializeHistory(
    List<ChatMessageModel> history,
  ) {
    final trimmed = history.length <= _maxHistoryMessages
        ? history
        : history.sublist(history.length - _maxHistoryMessages);

    return trimmed
        .map(
          (message) => <String, dynamic>{
            'role': message.isFromUser ? 'user' : 'assistant',
            'text': message.text,
          },
        )
        .toList();
  }
}
