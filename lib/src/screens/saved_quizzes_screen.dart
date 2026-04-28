import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app_router.dart';
import '../models/quiz_model.dart';
import '../providers.dart';
import '../widgets/app_primary_navigation_bar.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class SavedQuizzesScreen extends ConsumerWidget {
  const SavedQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedQuizzes = ref.watch(savedQuizzesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppShellAppBar(
        title: 'Saved',
        showHomeAction: false,
      ),
      bottomNavigationBar: const AppPrimaryNavigationBar(
        currentDestination: PrimaryDestination.saved,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: savedQuizzes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => const AppStatusBanner(
              icon: Icons.error_outline_rounded,
              title: 'Saved quizzes unavailable',
              message: 'The saved quiz library could not be loaded right now.',
              backgroundColor: Color(0xFFFEF3F2),
              borderColor: Color(0xFFFDA29B),
              foregroundColor: Color(0xFFB42318),
            ),
            data: (items) {
              if (items.isEmpty) {
                return AppStatusBanner(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'No saved quizzes yet',
                  message:
                      'Create a manual quiz offline or generate one with AI when you are online.',
                  backgroundColor: const Color(0xFFEEF4FF),
                  borderColor: const Color(0xFFB2CCFF),
                  foregroundColor: const Color(0xFF004EEB),
                  primaryActionLabel: 'Create manual quiz',
                  onPrimaryAction: () {
                    Navigator.pushNamed(context, AppRoutes.manualQuizBuilder);
                  },
                );
              }

              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final quiz = items[index];
                  return _SavedQuizCard(quiz: quiz);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SavedQuizCard extends ConsumerWidget {
  const _SavedQuizCard({required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = DateFormat('MMM d, yyyy');

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
          Text(quiz.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(quiz.sourcePdfName, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('${quiz.totalQuestions} questions')),
              Chip(label: Text(quiz.difficulty)),
              Chip(label: Text(formatter.format(quiz.createdAt))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    resetQuizTakingProgress(ref, quiz);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.takeQuiz,
                      arguments: quiz,
                    );
                  },
                  child: const Text('Open quiz'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.quizReview,
                      arguments: QuizReviewRouteArgs(quiz: quiz),
                    );
                  },
                  child: const Text('Review'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.manualQuizBuilder,
                    arguments: ManualQuizBuilderRouteArgs(quiz: quiz),
                  );
                },
                child: const Text('Edit'),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () async {
                  await ref.read(quizRepositoryProvider).deleteQuiz(quiz.id);
                  final refreshNotifier =
                      ref.read(savedQuizRefreshTriggerProvider.notifier);
                  refreshNotifier.state = refreshNotifier.state + 1;
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
