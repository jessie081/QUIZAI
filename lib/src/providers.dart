import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'ai/ai_prompt_templates.dart';
import 'config/app_backend_config.dart';
import 'models/ai_assistant_models.dart';
import 'models/chat_message_model.dart';
import 'models/pdf_document_model.dart';
import 'models/quiz_model.dart';
import 'models/quiz_result_model.dart';
import 'models/quiz_settings_model.dart';
import 'repositories/assistant_repository.dart';
import 'repositories/pdf_repository.dart';
import 'repositories/quiz_repository.dart';
import 'services/ai_service.dart';
import 'services/backend_api_client.dart';
import 'services/backend_health_service.dart';
import 'services/connectivity_service.dart';
import 'services/local_storage_service.dart';
import 'services/pdf_processing_service.dart';
import 'services/quiz_generation_service.dart';
import 'services/remote_ai_service.dart';
import 'services/syncfusion_pdf_processing_service.dart';
import 'services/unavailable_ai_service.dart';

class AiConversationState {
  const AiConversationState({
    this.messages = const <ChatMessageModel>[],
    this.isLoading = false,
    this.errorMessage,
    this.lastFailedPrompt,
    this.lastFailedActionType,
  });

  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? errorMessage;
  final String? lastFailedPrompt;
  final AiActionType? lastFailedActionType;

  AiConversationState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? lastFailedPrompt,
    AiActionType? lastFailedActionType,
    bool clearFailedPrompt = false,
  }) {
    return AiConversationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastFailedPrompt:
          clearFailedPrompt ? null : lastFailedPrompt ?? this.lastFailedPrompt,
      lastFailedActionType: clearFailedPrompt
          ? null
          : lastFailedActionType ?? this.lastFailedActionType,
    );
  }
}

String _buildAiErrorMessage(Object error) {
  if (error is BackendApiException) {
    final message = error.message.toLowerCase();
    if (message.contains('could not connect')) {
      return 'AI is unavailable right now. Check your internet connection and try again.';
    }
    if (message.contains('too long')) {
      return 'AI is taking too long to respond. Please try again.';
    }
    if (message.contains('insufficient balance') ||
        message.contains('billing') ||
        message.contains('payment')) {
      return 'AI is temporarily unavailable because the backend account needs more balance.';
    }
    if (error.statusCode == 401 ||
        error.statusCode == 403 ||
        message.contains('invalid api key') ||
        message.contains('authentication')) {
      return 'AI is not ready yet. Check the Groq API key on the backend.';
    }
    if (error.statusCode == 429 ||
        message.contains('quota') ||
        message.contains('rate limit') ||
        message.contains('too many requests') ||
        message.contains('resource exhausted')) {
      return 'AI is temporarily busy right now. Please wait a moment and try again.';
    }
    if (message.contains('api key') || message.contains('groq')) {
      return 'AI is not ready yet. Check the Groq backend.';
    }
    if (error.statusCode == 400) {
      return 'That message could not be processed. Please try again.';
    }
    return 'AI request failed. Please try again.';
  }

  final message = error.toString().toLowerCase();
  if (message.contains('not connected yet') ||
      message.contains('backend is not configured')) {
    return 'AI is not connected yet. Start the backend and try again.';
  }

  return 'AI request failed. Please try again.';
}

String _buildQuizErrorMessage(Object error) {
  if (error is BackendApiException) {
    final message = error.message.toLowerCase();
    if (message.contains('could not connect')) {
      return 'Quiz generation is unavailable right now. Check your internet connection and try again.';
    }
    if (message.contains('too long')) {
      return 'Quiz generation is taking too long. Please try again.';
    }
    if (message.contains('insufficient balance') ||
        message.contains('billing') ||
        message.contains('payment')) {
      return 'Quiz generation is temporarily unavailable because the backend account needs more balance.';
    }
    if (error.statusCode == 401 ||
        error.statusCode == 403 ||
        message.contains('invalid api key') ||
        message.contains('authentication')) {
      return 'Quiz generation is not ready yet. Check the Groq API key on the backend.';
    }
    if (error.statusCode == 429 ||
        message.contains('quota') ||
        message.contains('rate limit') ||
        message.contains('too many requests') ||
        message.contains('resource exhausted')) {
      return 'Quiz generation is temporarily busy right now. Please wait a moment and try again.';
    }
    if (message.contains('invalid json') ||
        message.contains('wrong number') ||
        message.contains('wrong total question count') ||
        message.contains('wrong length') ||
        message.contains('must include exactly 4 options')) {
      return 'The AI returned an invalid quiz format. Please try again or reduce the question count.';
    }
    if (message.contains('api key') ||
        message.contains('invalid api key') ||
        message.contains('authentication failed')) {
      return 'Quiz generation is not ready yet. Check the Groq backend.';
    }
    if (error.statusCode != null && error.statusCode! >= 500) {
      return 'The quiz service is temporarily unavailable. Please try again shortly.';
    }
    if (error.statusCode == 400) {
      return 'Your quiz settings could not be processed. Please adjust them and try again.';
    }
    return 'Could not generate the quiz right now. Please try again.';
  }

  final message = error.toString().toLowerCase();
  if (message.contains('not connected yet') ||
      message.contains('backend is not configured')) {
    return 'Quiz generation is not connected yet. Start the backend and try again.';
  }

  return 'Could not generate the quiz right now. Please try again.';
}

class AiConversationNotifier extends StateNotifier<AiConversationState> {
  AiConversationNotifier.general({
    required this.repository,
    required this.localStorageService,
  })  : mode = AiChatMode.general,
        document = null,
        super(
          AiConversationState(
            messages: <ChatMessageModel>[
              ChatMessageModel(
                id: _welcomeMessageId(null),
                sender: MessageSender.assistant,
                text: _welcomeMessageText(null),
              ),
            ],
          ),
        ) {
    unawaited(_restoreConversation());
  }

  AiConversationNotifier.pdf({
    required this.document,
    required this.repository,
    required this.localStorageService,
  })  : mode = AiChatMode.pdf,
        super(
          AiConversationState(
            messages: <ChatMessageModel>[
              ChatMessageModel(
                id: _welcomeMessageId(document),
                sender: MessageSender.assistant,
                text: _welcomeMessageText(document),
              ),
            ],
          ),
        ) {
    unawaited(_restoreConversation());
  }

  final AiChatMode mode;
  final PdfDocumentModel? document;
  final AssistantRepository repository;
  final LocalStorageService localStorageService;

  static String _welcomeMessageId(PdfDocumentModel? document) {
    return 'assistant-welcome-${document?.id ?? 'general'}';
  }

  static String _welcomeMessageText(PdfDocumentModel? document) {
    final fileName = document?.fileName;
    if (fileName == null || fileName.trim().isEmpty) {
      return 'Hey, I\'m here. Ask me anything.';
    }

    return 'Hey, I\'m here with $fileName. Ask me to explain something, summarize it, or turn it into quiz practice.';
  }

  String get _conversationStorageKey =>
      mode == AiChatMode.general ? 'general' : 'pdf_${document?.id ?? 'unknown'}';

  Future<void> _restoreConversation() async {
    final cachedMessages = await localStorageService.loadConversation(
      _conversationStorageKey,
    );
    if (cachedMessages.isEmpty || state.messages.length > 1) {
      return;
    }

    state = state.copyWith(messages: cachedMessages);
  }

  Future<void> _persistConversation(List<ChatMessageModel> messages) {
    return localStorageService.saveConversation(_conversationStorageKey, messages);
  }

  Future<void> submitPrompt({
    required String prompt,
    required AiActionType actionType,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty || state.isLoading) {
      return;
    }

    final userMessage = ChatMessageModel(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      sender: MessageSender.user,
      text: trimmed,
      actionType: actionType,
    );

    final updatedMessages = <ChatMessageModel>[
      ...state.messages,
      userMessage,
    ];

    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      clearError: true,
    );
    unawaited(_persistConversation(updatedMessages));

    try {
      final response = await repository.ask(
        prompt: trimmed,
        mode: mode,
        document: document,
        actionType: actionType,
        history: updatedMessages,
      );

      final assistantMessage = ChatMessageModel(
        id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        text: response.message,
        actionType: actionType,
        citations: response.citedSnippets,
      );

      state = state.copyWith(
        messages: <ChatMessageModel>[
          ...updatedMessages,
          assistantMessage,
        ],
        isLoading: false,
        clearError: true,
        clearFailedPrompt: true,
      );
      unawaited(_persistConversation(state.messages));
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _buildAiErrorMessage(error),
        lastFailedPrompt: trimmed,
        lastFailedActionType: actionType,
      );
    }
  }

  Future<void> retryLastPrompt() async {
    final prompt = state.lastFailedPrompt;
    final actionType = state.lastFailedActionType;
    if (prompt == null || actionType == null || state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final response = await repository.ask(
        prompt: prompt,
        mode: mode,
        document: document,
        actionType: actionType,
        history: state.messages,
      );

      final assistantMessage = ChatMessageModel(
        id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
        sender: MessageSender.assistant,
        text: response.message,
        actionType: actionType,
        citations: response.citedSnippets,
      );

      state = state.copyWith(
        messages: <ChatMessageModel>[
          ...state.messages,
          assistantMessage,
        ],
        isLoading: false,
        clearError: true,
        clearFailedPrompt: true,
      );
      unawaited(_persistConversation(state.messages));
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _buildAiErrorMessage(error),
        lastFailedPrompt: prompt,
        lastFailedActionType: actionType,
      );
    }
  }
}

class CurrentPdfNotifier extends StateNotifier<PdfDocumentModel?> {
  CurrentPdfNotifier(this._localStorageService) : super(null) {
    unawaited(_restore());
  }

  final LocalStorageService _localStorageService;

  Future<void> _restore() async {
    state = await _localStorageService.loadCurrentDocument();
  }

  Future<void> setDocument(PdfDocumentModel document) async {
    state = document;
    await _localStorageService.saveCurrentDocument(document);
  }

  Future<void> clear() async {
    state = null;
    await _localStorageService.clearCurrentDocument();
  }
}

class QuizGenerationState {
  const QuizGenerationState({
    this.isLoading = false,
    this.quiz,
    this.errorMessage,
  });

  final bool isLoading;
  final QuizModel? quiz;
  final String? errorMessage;

  QuizGenerationState copyWith({
    bool? isLoading,
    QuizModel? quiz,
    String? errorMessage,
    bool clearError = false,
    bool clearQuiz = false,
  }) {
    return QuizGenerationState(
      isLoading: isLoading ?? this.isLoading,
      quiz: clearQuiz ? null : quiz ?? this.quiz,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class QuizGenerationNotifier extends StateNotifier<QuizGenerationState> {
  QuizGenerationNotifier({
    required this.document,
    required this.repository,
  }) : super(const QuizGenerationState());

  final PdfDocumentModel document;
  final QuizRepository repository;

  Future<void> generate(QuizSettingsModel settings) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearQuiz: true,
    );

    try {
      final quiz = await repository.generateQuiz(
        QuizGenerationRequest(
          pdfText: document.extractedText,
          sourcePdfId: document.id,
          sourcePdfName: document.fileName,
          questionCounts: settings.questionCounts,
          difficulty: settings.difficulty,
          userInstruction:
              'Generate a grounded quiz using these exact counts: '
              'multiple_choice=${settings.multipleChoiceCount}, '
              'true_false=${settings.trueFalseCount}, '
              'identification=${settings.identificationCount}, '
              'short_answer=${settings.shortAnswerCount}, '
              'difficulty=${settings.difficulty}.',
        ),
      );

      state = state.copyWith(
        isLoading: false,
        quiz: quiz,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _buildQuizErrorMessage(error),
      );
    }
  }
}

class QuizTakingState {
  const QuizTakingState({
    this.answers = const <String, String>{},
    this.isSubmitting = false,
  });

  final Map<String, String> answers;
  final bool isSubmitting;

  QuizTakingState copyWith({
    Map<String, String>? answers,
    bool? isSubmitting,
  }) {
    return QuizTakingState(
      answers: answers ?? this.answers,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class QuizTakingNotifier extends StateNotifier<QuizTakingState> {
  QuizTakingNotifier(this.quiz) : super(const QuizTakingState());

  final QuizModel quiz;

  void setAnswer(String questionId, String value) {
    final updated = Map<String, String>.from(state.answers);
    updated[questionId] = value;
    state = state.copyWith(answers: updated);
  }

  QuizResultModel submit() {
    final correctAnswers = quiz.questions.where((question) {
      final submitted = state.answers[question.id]?.trim().toLowerCase() ?? '';
      return submitted == question.answer.trim().toLowerCase();
    }).length;

    return QuizResultModel(
      quizId: quiz.id,
      quizTitle: quiz.title,
      totalQuestions: quiz.totalQuestions,
      correctAnswers: correctAnswers,
      answers: state.answers,
    );
  }

  void reset() {
    state = const QuizTakingState();
  }
}

final pdfProcessingServiceProvider = Provider<PdfProcessingService>(
  (_) => const SyncfusionPdfProcessingService(),
);

final appBackendConfigProvider = Provider<AppBackendConfig>(
  (_) => AppBackendConfig.fromEnvironment(),
);

final backendApiClientProvider = Provider<BackendApiClient?>((ref) {
  final config = ref.watch(appBackendConfigProvider);
  if (!config.isConfigured) {
    return null;
  }

  final httpClient = http.Client();
  ref.onDispose(httpClient.close);

  return BackendApiClient(
    baseUrl: config.normalizedBaseUrl,
    httpClient: httpClient,
  );
});

final backendHealthServiceProvider = Provider<BackendHealthService>((ref) {
  return BackendHealthService(
    config: ref.watch(appBackendConfigProvider),
    apiClient: ref.watch(backendApiClientProvider),
  );
});

final backendHealthProvider = FutureProvider<BackendHealthStatus>((ref) async {
  return ref.watch(backendHealthServiceProvider).loadStatus();
});

final aiServiceProvider = Provider<AiService>((ref) {
  final apiClient = ref.watch(backendApiClientProvider);
  if (apiClient != null) {
    return RemoteAiService(apiClient);
  }
  return const UnavailableAiService();
});

final localStorageServiceProvider = Provider<LocalStorageService>(
  (_) => LocalStorageService(),
);

final connectivityServiceProvider = Provider<ConnectivityService>(
  (_) => ConnectivityService(),
);

final pdfRepositoryProvider = Provider<PdfRepository>(
  (ref) => PdfRepository(ref.watch(pdfProcessingServiceProvider)),
);

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(
    aiService: ref.watch(aiServiceProvider),
    localStorageService: ref.watch(localStorageServiceProvider),
  ),
);

final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepository(ref.watch(aiServiceProvider)),
);

final connectivityStatusProvider = StreamProvider<AppConnectionStatus>((ref) {
  return ref.watch(connectivityServiceProvider).watchStatus();
});

final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider).value;
  return status != AppConnectionStatus.offline;
});

final currentPdfProvider =
    StateNotifierProvider<CurrentPdfNotifier, PdfDocumentModel?>(
  (ref) => CurrentPdfNotifier(ref.watch(localStorageServiceProvider)),
);
final currentQuizProvider = StateProvider<QuizModel?>((_) => null);
final quizSettingsProvider =
    StateProvider<QuizSettingsModel>((_) => const QuizSettingsModel());
final savedQuizRefreshTriggerProvider = StateProvider<int>((_) => 0);

final savedQuizzesProvider = FutureProvider<List<QuizModel>>((ref) async {
  ref.watch(savedQuizRefreshTriggerProvider);
  return ref.watch(quizRepositoryProvider).loadSavedQuizzes();
});

final aiQuickPromptsProvider = Provider<List<AiPromptSuggestion>>(
  (_) => AiPromptTemplates.studyActions,
);

final generalConversationProvider =
    StateNotifierProvider<AiConversationNotifier, AiConversationState>(
  (ref) {
    return AiConversationNotifier.general(
      repository: ref.watch(assistantRepositoryProvider),
      localStorageService: ref.watch(localStorageServiceProvider),
    );
  },
);

final pdfConversationProvider = StateNotifierProvider.family<
    AiConversationNotifier, AiConversationState, PdfDocumentModel>(
  (ref, document) {
    return AiConversationNotifier.pdf(
      document: document,
      repository: ref.watch(assistantRepositoryProvider),
      localStorageService: ref.watch(localStorageServiceProvider),
    );
  },
);

final quizGenerationProvider = StateNotifierProvider.family<
    QuizGenerationNotifier, QuizGenerationState, PdfDocumentModel>(
  (ref, document) {
    return QuizGenerationNotifier(
      document: document,
      repository: ref.watch(quizRepositoryProvider),
    );
  },
);

/// Not autoDispose: avoids losing in-progress answers when the route or subtree
/// briefly disposes listeners. Call [resetQuizTakingProgress] before a new attempt
/// on the same [QuizModel] instance (start / retake / reopen).
final quizTakingProvider = StateNotifierProvider.family<
    QuizTakingNotifier, QuizTakingState, QuizModel>(
  (_, quiz) => QuizTakingNotifier(quiz),
);

void resetQuizTakingProgress(WidgetRef ref, QuizModel quiz) {
  ref.read(quizTakingProvider(quiz).notifier).reset();
}
