import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_prompt_templates.dart';
import '../app_router.dart';
import '../models/ai_assistant_models.dart';
import '../models/pdf_document_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../providers.dart';
import '../widgets/ai_assistant_card.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.result,
  });

  final QuizModel quiz;
  final QuizResultModel result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOnline = ref.watch(isOnlineProvider);
    final score = result.scorePercent.round();
    final document = PdfDocumentModel.fromExtraction(
      id: quiz.sourcePdfId,
      fileName: quiz.sourcePdfName,
      filePath: quiz.sourcePdfName,
      extractedText: quiz.sourcePdfText,
    );

    return Scaffold(
      appBar: const AppShellAppBar(title: 'Quiz Result'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Column(
                children: [
                  Text('$score%', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                    '${result.correctAnswers} out of ${result.totalQuestions} correct',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    score >= 80
                        ? 'Strong result. Review the tough spots and move on.'
                        : 'You are close. Review the mistakes before taking it again.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.quizReview,
                          arguments: QuizReviewRouteArgs(
                            quiz: quiz,
                            result: result,
                          ),
                        );
                      },
                      child: const Text('Review mistakes'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.takeQuiz,
                          arguments: quiz,
                        );
                      },
                      child: const Text('Retake quiz'),
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
                          document: document,
                          initialPrompt:
                              'Explain the likely mistakes based on my recent quiz result.',
                          initialActionType: AiActionType.explainMistakes,
                        ),
                      );
                    }
                        : null,
                    child: const Text('Explain with AI'),
                  ),
                ],
              ),
            ),
            if (!isOnline) ...[
              const SizedBox(height: 16),
              const AppStatusBanner(
                icon: Icons.wifi_off_rounded,
                title: 'AI explanations are offline',
                message:
                    'You can still review your answers and retake the quiz now. Reconnect when you want AI study help.',
                backgroundColor: Color(0xFFF2F4F7),
                borderColor: Color(0xFFD0D5DD),
                foregroundColor: Color(0xFF344054),
              ),
            ],
            const SizedBox(height: 16),
            AiAssistantCard(
              title: 'Use AI to review this result',
              subtitle:
                  'Ask what went wrong, summarize the weak areas, or turn the misses into a study plan.',
              prompts: AiPromptTemplates.resultActions,
              enabled: isOnline,
              onPromptTap: (prompt) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.pdfAiChat,
                  arguments: PdfAiChatRouteArgs(
                    document: document,
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
}
