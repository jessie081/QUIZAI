import 'package:flutter/material.dart';

import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_result_model.dart';
import '../widgets/app_shell_app_bar.dart';

class QuizReviewScreen extends StatelessWidget {
  const QuizReviewScreen({
    super.key,
    required this.quiz,
    this.result,
  });

  final QuizModel quiz;
  final QuizResultModel? result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppShellAppBar(title: 'Quiz Review'),
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
                  Text(quiz.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Review the correct answers and compare them with your own responses.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...quiz.questions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReviewCard(
                      index: entry.key + 1,
                      question: entry.value,
                      submittedAnswer: result?.answers[entry.value.id],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.question,
    required this.submittedAnswer,
  });

  final int index;
  final QuestionModel question;
  final String? submittedAnswer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedSubmitted = submittedAnswer?.trim().toLowerCase();
    final normalizedAnswer = question.answer.trim().toLowerCase();
    final isCorrect =
        normalizedSubmitted == null ? null : normalizedSubmitted == normalizedAnswer;

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
          Text(question.prompt, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          if (submittedAnswer != null) ...[
            Text(
              'Your answer',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              submittedAnswer!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isCorrect == true
                    ? const Color(0xFF157F3D)
                    : const Color(0xFFB42318),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            'Correct answer',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(question.answer, style: theme.textTheme.bodyMedium),
          if (question.explanation != null) ...[
            const SizedBox(height: 10),
            Text(
              'Explanation',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(question.explanation!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
