import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../widgets/app_shell_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final backendHealth = ref.watch(backendHealthProvider);

    return Scaffold(
      appBar: const AppShellAppBar(title: 'Settings'),
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
                  Text('QuizPDF AI', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Chat is the primary experience. PDF study tools and quiz generation stay available as separate workflows.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: const Text('AI provider'),
                    subtitle: backendHealth.when(
                      loading: () => const Text('Checking backend status...'),
                      error: (_, __) =>
                          const Text('Provider status could not be loaded.'),
                      data: (status) => Text(status.modeLabel),
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        ref.invalidate(backendHealthProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                  backendHealth.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (status) => Column(
                      children: [
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            status.groqWorking
                                ? Icons.check_circle_outline
                                : status.groqConfigured
                                    ? Icons.error_outline
                                    : Icons.cloud_off_outlined,
                            color: status.groqWorking
                                ? const Color(0xFF157F3D)
                                : status.groqConfigured
                                    ? const Color(0xFFB54708)
                                    : const Color(0xFF475467),
                          ),
                          title: const Text('Provider status'),
                          subtitle: Text(
                            status.message ?? 'Provider state unavailable.',
                          ),
                        ),
                        if (status.baseUrl != null) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.link_outlined),
                            title: const Text('Backend base URL'),
                            subtitle: Text(status.baseUrl!),
                          ),
                        ],
                        if (status.chatModel != null || status.quizModel != null) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.tune_outlined),
                            title: const Text('Groq models'),
                            subtitle: Text(
                              [
                                if (status.chatModel != null)
                                  'Chat: ${status.chatModel}',
                                if (status.quizModel != null)
                                  'Quiz: ${status.quizModel}',
                              ].join('\n'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.save_outlined),
                    title: Text('Storage'),
                    subtitle: Text('Generated quizzes are saved locally'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Version'),
                    subtitle: Text('0.1.0 MVP'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
