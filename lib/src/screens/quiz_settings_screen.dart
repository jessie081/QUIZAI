import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_prompt_templates.dart';
import '../app_router.dart';
import '../models/pdf_document_model.dart';
import '../models/quiz_settings_model.dart';
import '../providers.dart';
import '../widgets/ai_assistant_card.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';
import '../widgets/question_count_input_row.dart';

class QuizSettingsScreen extends ConsumerStatefulWidget {
  const QuizSettingsScreen({
    super.key,
    required this.document,
  });

  final PdfDocumentModel document;

  @override
  ConsumerState<QuizSettingsScreen> createState() => _QuizSettingsScreenState();
}

class _QuizSettingsScreenState extends ConsumerState<QuizSettingsScreen> {
  static const int _maxCountPerType = 50;

  late final Map<QuizQuestionType, TextEditingController> _controllers;
  late final Map<QuizQuestionType, FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(quizSettingsProvider);

    _controllers = <QuizQuestionType, TextEditingController>{
      for (final type in QuizQuestionType.values)
        type: TextEditingController(
          text: settings.countFor(type).toString(),
        ),
    };

    _focusNodes = <QuizQuestionType, FocusNode>{
      for (final type in QuizQuestionType.values) type: FocusNode(),
    };

    for (final entry in _focusNodes.entries) {
      entry.value.addListener(() {
        if (!mounted) {
          return;
        }

        if (!entry.value.hasFocus) {
          _normalizeField(entry.key);
        }

        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(quizSettingsProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final generationState = ref.watch(quizGenerationProvider(widget.document));
    final notifier = ref.read(quizGenerationProvider(widget.document).notifier);
    final theme = Theme.of(context);

    ref.listen(quizGenerationProvider(widget.document), (previous, next) {
      if (next.quiz != null && previous?.quiz?.id != next.quiz!.id) {
        ref.read(currentQuizProvider.notifier).state = next.quiz;
        Navigator.pushNamed(
          context,
          AppRoutes.generatedQuiz,
          arguments: GeneratedQuizRouteArgs(
            document: widget.document,
            quiz: next.quiz!,
          ),
        );
      }
    });

    return Scaffold(
      appBar: const AppShellAppBar(title: 'Quiz Setup'),
      bottomNavigationBar: _QuizSetupFooter(
        totalQuestions: settings.totalQuestions,
        isOnline: isOnline,
        isLoading: generationState.isLoading,
        onGeneratePressed: !isOnline ||
                settings.totalQuestions == 0 ||
                generationState.isLoading
            ? null
            : () => notifier.generate(settings),
        onCreateManualQuiz: () {
          Navigator.pushNamed(
            context,
            AppRoutes.manualQuizBuilder,
          );
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.document.fileName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the difficulty and exact question counts. The button stays fixed below so you can generate as soon as the setup looks right.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text('Difficulty', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'easy', label: Text('Easy')),
                      ButtonSegment(value: 'medium', label: Text('Medium')),
                      ButtonSegment(value: 'hard', label: Text('Hard')),
                    ],
                    selected: <String>{settings.difficulty},
                    onSelectionChanged: (selection) {
                      ref.read(quizSettingsProvider.notifier).state =
                          settings.copyWith(difficulty: selection.first);
                    },
                  ),
                  const SizedBox(height: 20),
                  QuestionCountInputRow(
                    label: 'Multiple Choice',
                    helperText: 'Exactly 4 choices with 1 correct answer',
                    controller: _controllers[QuizQuestionType.multipleChoice]!,
                    focusNode: _focusNodes[QuizQuestionType.multipleChoice]!,
                    onChanged: (value) => _handleInputChange(
                      QuizQuestionType.multipleChoice,
                      value,
                    ),
                    onIncrement: () => _adjustCount(
                      QuizQuestionType.multipleChoice,
                      1,
                    ),
                    onDecrement: () => _adjustCount(
                      QuizQuestionType.multipleChoice,
                      -1,
                    ),
                  ),
                  QuestionCountInputRow(
                    label: 'True / False',
                    helperText: 'Use this for clear statement checks',
                    controller: _controllers[QuizQuestionType.trueFalse]!,
                    focusNode: _focusNodes[QuizQuestionType.trueFalse]!,
                    onChanged: (value) => _handleInputChange(
                      QuizQuestionType.trueFalse,
                      value,
                    ),
                    onIncrement: () => _adjustCount(
                      QuizQuestionType.trueFalse,
                      1,
                    ),
                    onDecrement: () => _adjustCount(
                      QuizQuestionType.trueFalse,
                      -1,
                    ),
                  ),
                  QuestionCountInputRow(
                    label: 'Identification',
                    helperText: 'Best for terms, labels, and keywords',
                    controller: _controllers[QuizQuestionType.identification]!,
                    focusNode: _focusNodes[QuizQuestionType.identification]!,
                    onChanged: (value) => _handleInputChange(
                      QuizQuestionType.identification,
                      value,
                    ),
                    onIncrement: () => _adjustCount(
                      QuizQuestionType.identification,
                      1,
                    ),
                    onDecrement: () => _adjustCount(
                      QuizQuestionType.identification,
                      -1,
                    ),
                  ),
                  QuestionCountInputRow(
                    label: 'Short Answer',
                    helperText: 'Use this for brief written recall',
                    controller: _controllers[QuizQuestionType.shortAnswer]!,
                    focusNode: _focusNodes[QuizQuestionType.shortAnswer]!,
                    onChanged: (value) => _handleInputChange(
                      QuizQuestionType.shortAnswer,
                      value,
                    ),
                    onIncrement: () => _adjustCount(
                      QuizQuestionType.shortAnswer,
                      1,
                    ),
                    onDecrement: () => _adjustCount(
                      QuizQuestionType.shortAnswer,
                      -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Per type maximum: $_maxCountPerType',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!isOnline) ...[
              const SizedBox(height: 16),
              const AppStatusBanner(
                icon: Icons.wifi_off_rounded,
                title: 'AI quiz generation is offline',
                message:
                    'Create a manual quiz or reconnect to generate one with AI.',
                backgroundColor: Color(0xFFF2F4F7),
                borderColor: Color(0xFFD0D5DD),
                foregroundColor: Color(0xFF344054),
              ),
            ],
            if (settings.totalQuestions == 0) ...[
              const SizedBox(height: 16),
              const AppStatusBanner(
                icon: Icons.info_outline_rounded,
                title: 'No questions selected',
                message:
                    'Add at least one question before you generate a quiz.',
                backgroundColor: Color(0xFFEEF4FF),
                borderColor: Color(0xFFB2CCFF),
                foregroundColor: Color(0xFF004EEB),
              ),
            ],
            if (generationState.errorMessage != null) ...[
              const SizedBox(height: 16),
              AppStatusBanner(
                icon: Icons.error_outline_rounded,
                title: 'Quiz generation failed',
                message: generationState.errorMessage!,
                backgroundColor: const Color(0xFFFEF3F2),
                borderColor: const Color(0xFFFDA29B),
                foregroundColor: const Color(0xFFB42318),
              ),
            ],
            const SizedBox(height: 16),
            AiAssistantCard(
              title: 'Need help before generating?',
              subtitle:
                  'Ask AI to summarize or explain the document first, then come back and build the quiz.',
              prompts: AiPromptTemplates.studyActions,
              enabled: isOnline,
              primaryButtonLabel: 'Ask this document',
              onPrimaryPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.pdfAiChat,
                  arguments: PdfAiChatRouteArgs(
                    document: widget.document,
                  ),
                );
              },
              onPromptTap: (prompt) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.pdfAiChat,
                  arguments: PdfAiChatRouteArgs(
                    document: widget.document,
                    initialPrompt: prompt.prompt,
                    initialActionType: prompt.actionType,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleInputChange(QuizQuestionType type, String rawValue) {
    final sanitized = _sanitize(rawValue);
    _updateSettings(type, sanitized);

    if (rawValue.isEmpty) {
      return;
    }

    final normalized = sanitized.toString();
    if (rawValue != normalized) {
      _setControllerValue(type, normalized);
    }
  }

  void _adjustCount(QuizQuestionType type, int delta) {
    final current = _sanitize(_controllers[type]!.text);
    final updated = (current + delta).clamp(0, _maxCountPerType);
    _setControllerValue(type, '$updated');
    _updateSettings(type, updated);
  }

  void _normalizeField(QuizQuestionType type) {
    final normalized = _sanitize(_controllers[type]!.text);
    _setControllerValue(type, '$normalized');
    _updateSettings(type, normalized);
  }

  int _sanitize(String rawValue) {
    final parsed = int.tryParse(rawValue);
    if (parsed == null || parsed < 0) {
      return 0;
    }
    return parsed.clamp(0, _maxCountPerType);
  }

  void _setControllerValue(QuizQuestionType type, String text) {
    final controller = _controllers[type]!;
    if (controller.text == text) {
      return;
    }

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _updateSettings(QuizQuestionType type, int value) {
    final current = ref.read(quizSettingsProvider);
    final next = switch (type) {
      QuizQuestionType.multipleChoice =>
        current.copyWith(multipleChoiceCount: value),
      QuizQuestionType.trueFalse => current.copyWith(trueFalseCount: value),
      QuizQuestionType.identification =>
        current.copyWith(identificationCount: value),
      QuizQuestionType.shortAnswer => current.copyWith(shortAnswerCount: value),
    };

    if (next != current) {
      ref.read(quizSettingsProvider.notifier).state = next;
    }
  }
}

class _QuizSetupFooter extends StatelessWidget {
  const _QuizSetupFooter({
    required this.totalQuestions,
    required this.isOnline,
    required this.isLoading,
    required this.onGeneratePressed,
    required this.onCreateManualQuiz,
  });

  final int totalQuestions;
  final bool isOnline;
  final bool isLoading;
  final VoidCallback? onGeneratePressed;
  final VoidCallback onCreateManualQuiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFD0D5DD)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total questions: $totalQuestions',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGeneratePressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(
                  isLoading ? 'Generating quiz...' : 'Generate quiz',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCreateManualQuiz,
                child: Text(
                  isOnline ? 'Create manual quiz instead' : 'Create manual quiz',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
