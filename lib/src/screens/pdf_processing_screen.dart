import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_prompt_templates.dart';
import '../app_router.dart';
import '../models/pdf_document_model.dart';
import '../providers.dart';
import '../widgets/ai_assistant_card.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class PdfProcessingScreen extends ConsumerWidget {
  const PdfProcessingScreen({
    super.key,
    required this.document,
  });

  final PdfDocumentModel document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOnline = ref.watch(isOnlineProvider);
    final isEmpty = document.extractedText.trim().isEmpty;

    return Scaffold(
      appBar: const AppShellAppBar(title: 'Document Ready'),
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
                    isEmpty ? 'Document not usable yet' : document.fileName,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEmpty
                        ? 'This PDF could not be converted into readable study content. Replace it with a cleaner file.'
                        : 'Your PDF is ready. Go straight into document chat or quiz setup.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('${document.wordCount} words')),
                      if (document.pageCount != null)
                        Chip(label: Text('${document.pageCount} pages')),
                    ],
                  ),
                  if (isEmpty || !isOnline) ...[
                    const SizedBox(height: 16),
                    AppStatusBanner(
                      icon: isEmpty
                          ? Icons.warning_amber_rounded
                          : Icons.wifi_off_rounded,
                      title: isEmpty
                          ? 'Readable text missing'
                          : 'AI actions need internet',
                      message: isEmpty
                          ? 'Without readable extracted text, the document chat and AI quiz tools cannot continue.'
                          : 'You can still read the extracted text offline. Reconnect to ask AI or generate a quiz.',
                      backgroundColor: isEmpty
                          ? null
                          : const Color(0xFFF2F4F7),
                      borderColor: isEmpty
                          ? null
                          : const Color(0xFFD0D5DD),
                      foregroundColor: isEmpty
                          ? null
                          : const Color(0xFF344054),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isEmpty || !isOnline
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.pdfAiChat,
                                    arguments: PdfAiChatRouteArgs(
                                      document: document,
                                    ),
                                  );
                                },
                          child: const Text('Ask this PDF'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isEmpty || !isOnline
                              ? null
                              : () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.quizSettings,
                                    arguments: QuizSettingsRouteArgs(
                                      document: document,
                                    ),
                                  );
                                },
                          child: const Text('Generate quiz'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AiAssistantCard(
              title: 'Quick study actions',
              subtitle:
                  'Use a shortcut instead of typing if you want to move faster.',
              prompts: AiPromptTemplates.studyActions,
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
            const SizedBox(height: 16),
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
                  Text('Preview', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(document.previewText, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
