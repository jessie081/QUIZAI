import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_router.dart';
import '../models/pdf_document_model.dart';
import '../providers.dart';
import '../widgets/app_primary_navigation_bar.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class PdfQuizHubScreen extends ConsumerWidget {
  const PdfQuizHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDocument = ref.watch(currentPdfProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final canUseDocument = currentDocument?.extractedText.trim().isNotEmpty ?? false;

    return Scaffold(
      appBar: const AppShellAppBar(
        title: 'Study',
        showHomeAction: false,
      ),
      bottomNavigationBar: const AppPrimaryNavigationBar(
        currentDestination: PrimaryDestination.study,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _StudyIntroPanel(
              isOnline: isOnline,
              onCreateManualQuiz: () {
                Navigator.pushNamed(context, AppRoutes.manualQuizBuilder);
              },
            ),
            if (!isOnline) ...[
              const SizedBox(height: 16),
              const AppStatusBanner(
                icon: Icons.wifi_off_rounded,
                title: 'Offline study mode',
                message:
                    'You can create quizzes manually, open saved quizzes, and review your last processed PDF offline. AI features turn back on automatically when you reconnect.',
                backgroundColor: Color(0xFFF2F4F7),
                borderColor: Color(0xFFD0D5DD),
                foregroundColor: Color(0xFF344054),
              ),
            ],
            const SizedBox(height: 20),
            if (currentDocument == null)
              _NoPdfLoadedState(
                onUploadPressed: () {
                  Navigator.pushNamed(context, AppRoutes.uploadPdf);
                },
                onCreateManualQuiz: () {
                  Navigator.pushNamed(context, AppRoutes.manualQuizBuilder);
                },
              )
            else
              _PdfWorkspaceCard(
                document: currentDocument,
                canUseDocument: canUseDocument,
                isOnline: isOnline,
              ),
          ],
        ),
      ),
    );
  }
}

class _StudyIntroPanel extends StatelessWidget {
  const _StudyIntroPanel({
    required this.isOnline,
    required this.onCreateManualQuiz,
  });

  final bool isOnline;
  final VoidCallback onCreateManualQuiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PDF workspace', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Upload one PDF, ask questions about it, or turn it into quiz practice.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (!isOnline)
                Chip(
                  label: const Text('Offline mode'),
                  avatar: const Icon(Icons.wifi_off_rounded, size: 18),
                ),
              OutlinedButton(
                onPressed: onCreateManualQuiz,
                child: const Text('Create manual quiz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoPdfLoadedState extends StatelessWidget {
  const _NoPdfLoadedState({
    required this.onUploadPressed,
    required this.onCreateManualQuiz,
  });

  final VoidCallback onUploadPressed;
  final VoidCallback onCreateManualQuiz;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No PDF loaded', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Upload a PDF first. Once it is ready, this screen becomes your document workspace.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUploadPressed,
              child: const Text('Upload PDF'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCreateManualQuiz,
              child: const Text('Create manual quiz'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfWorkspaceCard extends StatelessWidget {
  const _PdfWorkspaceCard({
    required this.document,
    required this.canUseDocument,
    required this.isOnline,
  });

  final PdfDocumentModel document;
  final bool canUseDocument;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(document.fileName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('${document.wordCount} words')),
                        if (document.pageCount != null)
                          Chip(label: Text('${document.pageCount} pages')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.uploadPdf);
                  },
                  child: const Text(
                    'Replace PDF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            canUseDocument
                ? document.previewText
                : 'This file is loaded, but readable text extraction failed. Replace it with a cleaner PDF to continue.',
            style: theme.textTheme.bodyMedium,
          ),
          if (!canUseDocument || !isOnline) ...[
            const SizedBox(height: 16),
            AppStatusBanner(
              icon: !canUseDocument
                  ? Icons.warning_amber_rounded
                  : Icons.wifi_off_rounded,
              title: !canUseDocument
                  ? 'Study actions unavailable'
                  : 'AI actions need internet',
              message: !canUseDocument
                  ? 'Document chat and AI quiz generation both need readable extracted text from the PDF.'
                  : 'You can still read the extracted text and work with saved quizzes offline.',
              backgroundColor: !canUseDocument
                  ? null
                  : const Color(0xFFF2F4F7),
              borderColor: !canUseDocument
                  ? null
                  : const Color(0xFFD0D5DD),
              foregroundColor: !canUseDocument
                  ? null
                  : const Color(0xFF344054),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canUseDocument && isOnline
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.pdfAiChat,
                            arguments: PdfAiChatRouteArgs(
                              document: document,
                            ),
                          );
                        }
                      : null,
                  child: const Text('Ask this PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: canUseDocument && isOnline
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.quizSettings,
                            arguments: QuizSettingsRouteArgs(document: document),
                          );
                        }
                      : null,
                  child: const Text('Generate quiz'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.pdfProcessing,
                arguments: PdfProcessingRouteArgs(document: document),
              );
            },
            child: const Text('View document details'),
          ),
        ],
      ),
    );
  }
}
