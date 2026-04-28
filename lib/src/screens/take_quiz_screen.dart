import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_router.dart';
import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../providers.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

int _answeredQuestionCount(QuizTakingState state, QuizModel quiz) {
  return quiz.questions.where((q) {
    final raw = state.answers[q.id]?.trim() ?? '';
    return raw.isNotEmpty;
  }).length;
}

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
    final answered = _answeredQuestionCount(state, quiz);
    final total = quiz.totalQuestions;

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
                if (answered < total) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You still have ${total - answered} unanswered '
                        '${total - answered == 1 ? "question" : "questions"}.',
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
                  Text(
                    quiz.title,
                    style: theme.textTheme.titleLarge,
                    softWrap: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Finish every item, then submit once. The score screen will guide you to the next best action.',
                    style: theme.textTheme.bodyMedium,
                    softWrap: true,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$answered of $total answered',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (answered < total) ...[
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
                      onChanged: (value) =>
                          notifier.setAnswer(entry.value.id, value),
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
          Text(
            question.prompt,
            style: theme.textTheme.bodyLarge,
            softWrap: true,
          ),
          const SizedBox(height: 14),
          if (question.expectsOptions && answerOptions.isNotEmpty)
            ...answerOptions.map(
              (choice) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                value: choice,
                groupValue: value,
                title: Text(
                  choice,
                  softWrap: true,
                ),
                onChanged: (selected) {
                  if (selected != null) {
                    onChanged(selected);
                  }
                },
              ),
            )
          else if (question.expectsOptions)
            Container(
              width: double.infinity,
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
                softWrap: true,
              ),
            )
          else
            _SyncedAnswerTextField(
              questionId: question.id,
              value: value,
              questionType: question.type,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

/// Keeps [TextEditingController] in sync with Riverpod state so answers are not
/// lost or stuck when the parent rebuilds.
class _SyncedAnswerTextField extends StatefulWidget {
  const _SyncedAnswerTextField({
    required this.questionId,
    required this.value,
    required this.questionType,
    required this.onChanged,
  });

  final String questionId;
  final String? value;
  final QuestionType questionType;
  final ValueChanged<String> onChanged;

  @override
  State<_SyncedAnswerTextField> createState() => _SyncedAnswerTextFieldState();
}

class _SyncedAnswerTextFieldState extends State<_SyncedAnswerTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant _SyncedAnswerTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.value ?? '';
    final prev = oldWidget.value ?? '';
    if (next != prev && next != _controller.text) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey<String>(widget.questionId),
      controller: _controller,
      minLines: 1,
      maxLines: widget.questionType == QuestionType.shortAnswer ? 4 : 1,
      keyboardType: widget.questionType == QuestionType.shortAnswer
          ? TextInputType.multiline
          : TextInputType.text,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: widget.questionType == QuestionType.shortAnswer
            ? 'Your answer'
            : 'Answer',
        hintText: widget.questionType == QuestionType.shortAnswer
            ? 'Type your answer'
            : 'Enter your answer',
        alignLabelWithHint: widget.questionType == QuestionType.shortAnswer,
      ),
      onChanged: widget.onChanged,
    );
  }
}
