import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_router.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../providers.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class TakeQuizScreen extends ConsumerWidget {
  const TakeQuizScreen({
    super.key,
    required this.quiz,
  });

  final QuizModel quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizTakingProvider(quiz));
    final notifier = ref.read(quizTakingProvider(quiz).notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppShellAppBar(title: 'Take Quiz'),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFD0D5DD)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final unansweredCount = quiz.totalQuestions - state.answers.length;
                if (unansweredCount > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You still have $unansweredCount unanswered ${unansweredCount == 1 ? "question" : "questions"}.',
                      ),
                    ),
                  );
                  return;
                }

                final result = notifier.submit();
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.quizResult,
                  arguments: QuizResultRouteArgs(
                    quiz: quiz,
                    result: result,
                  ),
                );
              },
              child: const Text('Submit quiz'),
            ),
          ),
        ),
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
                  Text(quiz.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Finish every item, then submit once. The score screen will guide you to the next best action.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${state.answers.length} of ${quiz.totalQuestions} answered',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (state.answers.length < quiz.totalQuestions) ...[
              const SizedBox(height: 16),
              const AppStatusBanner(
                icon: Icons.info_outline_rounded,
                title: 'Complete all questions',
                message:
                    'The quiz can only be submitted after every question has an answer.',
                backgroundColor: Color(0xFFEEF4FF),
                borderColor: Color(0xFFB2CCFF),
                foregroundColor: Color(0xFF004EEB),
              ),
            ],
            const SizedBox(height: 16),
            ...quiz.questions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuestionInputCard(
                      index: entry.key + 1,
                      question: entry.value,
                      value: state.answers[entry.value.id],
                      onChanged: (value) => notifier.setAnswer(entry.value.id, value),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _QuestionInputCard extends StatelessWidget {
  const _QuestionInputCard({
    required this.index,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final int index;
  final QuestionModel question;
  final String? value;
  final ValueChanged<String> onChanged;

  List<String> get _answerOptions {
    switch (question.type) {
      case QuestionType.trueFalse:
        return const <String>['True', 'False'];
      case QuestionType.multipleChoice:
        return question.choices;
      case QuestionType.identification:
      case QuestionType.shortAnswer:
        return const <String>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answerOptions = _answerOptions;

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
          const SizedBox(height: 14),
          if (question.expectsOptions && answerOptions.isNotEmpty)
            ...answerOptions.map(
              (choice) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: choice,
                groupValue: value,
                title: Text(choice),
                onChanged: (selected) {
                  if (selected != null) {
                    onChanged(selected);
                  }
                },
              ),
            )
          else if (question.expectsOptions)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                'This question is missing answer options.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB42318),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextFormField(
              initialValue: value,
              minLines: 1,
              maxLines: question.type == QuestionType.shortAnswer ? 4 : 1,
              decoration: InputDecoration(
                labelText:
                    question.type == QuestionType.shortAnswer ? 'Your answer' : 'Answer',
                hintText: question.type == QuestionType.shortAnswer
                    ? 'Type your answer'
                    : 'Enter your answer',
              ),
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}
