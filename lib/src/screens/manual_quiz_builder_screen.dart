import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/question_model.dart';
import '../models/quiz_model.dart';
import '../providers.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class ManualQuizBuilderScreen extends ConsumerStatefulWidget {
  const ManualQuizBuilderScreen({
    super.key,
    this.initialQuiz,
  });

  final QuizModel? initialQuiz;

  @override
  ConsumerState<ManualQuizBuilderScreen> createState() =>
      _ManualQuizBuilderScreenState();
}

class _ManualQuizBuilderScreenState
    extends ConsumerState<ManualQuizBuilderScreen> {
  final Uuid _uuid = const Uuid();
  late final TextEditingController _titleController;
  late final List<_QuestionDraft> _drafts;
  bool _isSaving = false;

  bool get _isEditing => widget.initialQuiz != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialQuiz?.title ?? '',
    );
    _drafts = widget.initialQuiz == null
        ? <_QuestionDraft>[_QuestionDraft.empty()]
        : widget.initialQuiz!.questions.map(_QuestionDraft.fromQuestion).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _drafts.add(_QuestionDraft.empty());
    });
  }

  void _removeQuestion(int index) {
    if (_drafts.length == 1) {
      return;
    }

    setState(() {
      final draft = _drafts.removeAt(index);
      draft.dispose();
    });
  }

  Future<void> _saveQuiz() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showMessage('Add a quiz title before saving.');
      return;
    }

    final questions = <QuestionModel>[];
    for (var index = 0; index < _drafts.length; index++) {
      final question = _drafts[index].buildQuestion(
        id: widget.initialQuiz?.questions.elementAtOrNull(index)?.id ?? _uuid.v4(),
      );
      if (question == null) {
        _showMessage('Question ${index + 1} is incomplete. Finish it before saving.');
        return;
      }
      questions.add(question);
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final existing = widget.initialQuiz;
      final quiz = QuizModel(
        id: existing?.id ?? _uuid.v4(),
        title: title,
        sourcePdfId: existing?.sourcePdfId ?? 'manual-${_uuid.v4()}',
        sourcePdfName: existing?.sourcePdfName ?? 'Manual Quiz',
        sourcePdfText: existing?.sourcePdfText ?? '',
        questions: questions,
        createdAt: existing?.createdAt ?? DateTime.now(),
        summary: 'Created manually for offline practice.',
        difficulty: existing?.difficulty ?? 'Manual',
      );

      await ref.read(quizRepositoryProvider).saveQuiz(quiz);
      final refreshNotifier = ref.read(savedQuizRefreshTriggerProvider.notifier);
      refreshNotifier.state = refreshNotifier.state + 1;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Quiz updated.' : 'Manual quiz saved.'),
        ),
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppShellAppBar(
        title: _isEditing ? 'Edit Manual Quiz' : 'Manual Quiz Builder',
      ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveQuiz,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt_rounded),
                  label: Text(_isSaving ? 'Saving...' : 'Save manual quiz'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add question'),
                ),
              ),
            ],
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
                    _isEditing ? 'Update your quiz' : 'Build a quiz manually',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This mode works fully offline. Add your own questions, save locally, and take the quiz anytime.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quiz title',
                      hintText: 'Example: Biology Chapter Review',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppStatusBanner(
              icon: Icons.offline_bolt_rounded,
              title: 'Offline-ready feature',
              message:
                  'Manual quizzes, saved quizzes, and quiz retakes work without internet.',
              backgroundColor: Color(0xFFEEF4FF),
              borderColor: Color(0xFFB2CCFF),
              foregroundColor: Color(0xFF004EEB),
            ),
            const SizedBox(height: 16),
            ..._drafts.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QuestionEditorCard(
                      index: entry.key + 1,
                      draft: entry.value,
                      canDelete: _drafts.length > 1,
                      onChanged: () => setState(() {}),
                      onDelete: () => _removeQuestion(entry.key),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDraft {
  _QuestionDraft({
    required this.type,
    required this.promptController,
    required this.answerController,
    required this.choiceControllers,
    this.correctChoiceIndex,
    this.trueFalseAnswer = true,
  });

  factory _QuestionDraft.empty() {
    return _QuestionDraft(
      type: QuestionType.multipleChoice,
      promptController: TextEditingController(),
      answerController: TextEditingController(),
      choiceControllers: List<TextEditingController>.generate(
        4,
        (_) => TextEditingController(),
      ),
      correctChoiceIndex: 0,
    );
  }

  factory _QuestionDraft.fromQuestion(QuestionModel question) {
    final choiceControllers = question.type == QuestionType.multipleChoice
        ? List<TextEditingController>.generate(
            4,
            (index) => TextEditingController(
              text: question.choices.elementAtOrNull(index) ?? '',
            ),
          )
        : <TextEditingController>[];

    final matchedIndex = question.choices.indexOf(question.answer);
    final correctIndex = question.type == QuestionType.multipleChoice
        ? (matchedIndex >= 0 ? matchedIndex : 0)
        : 0;

    return _QuestionDraft(
      type: question.type,
      promptController: TextEditingController(text: question.prompt),
      answerController: TextEditingController(
        text: question.type == QuestionType.multipleChoice ||
                question.type == QuestionType.trueFalse
            ? ''
            : question.answer,
      ),
      choiceControllers: choiceControllers,
      correctChoiceIndex: correctIndex,
      trueFalseAnswer: question.answer.toLowerCase() != 'false',
    );
  }

  QuestionType type;
  final TextEditingController promptController;
  final TextEditingController answerController;
  List<TextEditingController> choiceControllers;
  int? correctChoiceIndex;
  bool trueFalseAnswer;

  void updateType(QuestionType nextType) {
    type = nextType;
    answerController.clear();

    if (nextType == QuestionType.multipleChoice) {
      if (choiceControllers.isEmpty) {
        choiceControllers = List<TextEditingController>.generate(
          4,
          (_) => TextEditingController(),
        );
      }
      correctChoiceIndex ??= 0;
    } else {
      for (final controller in choiceControllers) {
        controller.dispose();
      }
      choiceControllers = <TextEditingController>[];
      correctChoiceIndex = null;
    }
  }

  QuestionModel? buildQuestion({required String id}) {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      return null;
    }

    switch (type) {
      case QuestionType.multipleChoice:
        final choices = choiceControllers
            .map((controller) => controller.text.trim())
            .toList();
        if (choices.any((choice) => choice.isEmpty)) {
          return null;
        }
        final answerIndex = correctChoiceIndex;
        if (answerIndex == null || answerIndex < 0 || answerIndex >= choices.length) {
          return null;
        }
        return QuestionModel(
          id: id,
          type: type,
          prompt: prompt,
          answer: choices[answerIndex],
          choices: choices,
        );
      case QuestionType.trueFalse:
        return QuestionModel(
          id: id,
          type: type,
          prompt: prompt,
          answer: trueFalseAnswer ? 'True' : 'False',
          choices: const ['True', 'False'],
        );
      case QuestionType.identification:
      case QuestionType.shortAnswer:
        final answer = answerController.text.trim();
        if (answer.isEmpty) {
          return null;
        }
        return QuestionModel(
          id: id,
          type: type,
          prompt: prompt,
          answer: answer,
        );
    }
  }

  void dispose() {
    promptController.dispose();
    answerController.dispose();
    for (final controller in choiceControllers) {
      controller.dispose();
    }
  }
}

class _QuestionEditorCard extends StatelessWidget {
  const _QuestionEditorCard({
    required this.index,
    required this.draft,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final _QuestionDraft draft;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question $index',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Delete question',
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<QuestionType>(
            value: draft.type,
            decoration: const InputDecoration(
              labelText: 'Question type',
            ),
            items: QuestionType.values
                .map(
                  (type) => DropdownMenuItem<QuestionType>(
                    value: type,
                    child: Text(type.typeLabel),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              draft.updateType(value);
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: draft.promptController,
            decoration: const InputDecoration(
              labelText: 'Question prompt',
              hintText: 'Enter the question',
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),
          if (draft.type == QuestionType.multipleChoice) ...[
            for (var i = 0; i < 4; i++) ...[
              TextField(
                controller: draft.choiceControllers[i],
                decoration: InputDecoration(
                  labelText: 'Option ${String.fromCharCode(65 + i)}',
                ),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 10),
            ],
            DropdownButtonFormField<int>(
              value: draft.correctChoiceIndex ?? 0,
              decoration: const InputDecoration(
                labelText: 'Correct option',
              ),
              items: List<DropdownMenuItem<int>>.generate(
                4,
                (index) => DropdownMenuItem<int>(
                  value: index,
                  child: Text('Option ${String.fromCharCode(65 + index)}'),
                ),
              ),
              onChanged: (value) {
                draft.correctChoiceIndex = value ?? 0;
                onChanged();
              },
            ),
          ] else if (draft.type == QuestionType.trueFalse) ...[
            Text(
              'Correct answer',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(value: true, label: Text('True')),
                ButtonSegment<bool>(value: false, label: Text('False')),
              ],
              selected: <bool>{draft.trueFalseAnswer},
              onSelectionChanged: (selection) {
                draft.trueFalseAnswer = selection.first;
                onChanged();
              },
            ),
          ] else ...[
            TextField(
              controller: draft.answerController,
              minLines: 1,
              maxLines: draft.type == QuestionType.shortAnswer ? 4 : 1,
              decoration: InputDecoration(
                labelText: draft.type == QuestionType.shortAnswer
                    ? 'Expected answer'
                    : 'Correct answer',
                hintText: draft.type == QuestionType.shortAnswer
                    ? 'Enter a short model answer'
                    : 'Enter the exact answer',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) {
      return null;
    }
    return this[index];
  }
}
