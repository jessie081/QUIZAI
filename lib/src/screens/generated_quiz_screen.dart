import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_prompt_templates.dart';
import '../app_router.dart';
import '../models/pdf_document_model.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../providers.dart';
import '../widgets/ai_assistant_card.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class GeneratedQuizScreen extends ConsumerStatefulWidget {
  const GeneratedQuizScreen({
    super.key,
    required this.document,
    required this.quiz,
  });

  final PdfDocumentModel document;
  final QuizModel quiz;

  @override
  ConsumerState<GeneratedQuizScreen> createState() => _GeneratedQuizScreenState();
}

class _GeneratedQuizScreenState extends ConsumerState<GeneratedQuizScreen> {
  bool _isSaving = false;

  Future<void> _saveQuiz() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(localStorageServiceProvider).saveQuiz(widget.quiz);
      final refreshNotifier = ref.read(savedQuizRefreshTriggerProvider.notifier);
      refreshNotifier.state = refreshNotifier.state + 1;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz saved locally.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final isOnline = ref.watch(isOnlineProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppShellAppBar(title: 'Quiz Ready'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  Text(
                    quiz.title,
                    style: theme.textTheme.titleLarge,
                    softWrap: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    quiz.summary ??
                        'Your quiz is ready. Start immediately or save it for later.',
                    style: theme.textTheme.bodyMedium,
                    softWrap: true,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('${quiz.totalQuestions} questions')),
                      Chip(label: Text(quiz.difficulty)),
                      Chip(
                        label: Text(
                          quiz.sourcePdfName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        resetQuizTakingProgress(ref, quiz);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.takeQuiz,
                          arguments: quiz,
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start quiz'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _saveQuiz,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save quiz'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: isOnline
                        ? () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.pdfAiChat,
                        arguments: PdfAiChatRouteArgs(
                          document: widget.document,
                        ),
                      );
                    }
                        : null,
                    child: const Text('Ask AI to explain topics'),
                  ),
                ],
              ),
            ),
            if (!isOnline) ...[
              const SizedBox(height: 16),
              const AppStatusBanner(
                icon: Icons.wifi_off_rounded,
                title: 'AI review is offline',
                message:
                    'You can still take, save, and reopen this quiz offline. Reconnect when you want AI explanations or study guides.',
                backgroundColor: Color(0xFFF2F4F7),
                borderColor: Color(0xFFD0D5DD),
                foregroundColor: Color(0xFF344054),
              ),
            ],
            const SizedBox(height: 16),
            AiAssistantCard(
              title: 'Use AI while reviewing',
              subtitle:
                  'Ask follow-up questions, explain concepts, or turn this quiz into a study guide.',
              prompts: const [
                ...AiPromptTemplates.resultActions,
                ...AiPromptTemplates.studyActions,
              ],
              enabled: isOnline,
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
            const SizedBox(height: 16),
            Text('Question preview', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...quiz.questions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuestionPreviewCard(
                      index: entry.key + 1,
                      question: entry.value,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  const _QuestionPreviewCard({
    required this.index,
    required this.question,
  });

  final int index;
  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question $index',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF155EEF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.prompt,
            style: theme.textTheme.titleMedium,
            softWrap: true,
          ),
          const SizedBox(height: 12),
          Chip(label: Text(question.typeLabel)),
        ],
      ),
    );
  }
}
