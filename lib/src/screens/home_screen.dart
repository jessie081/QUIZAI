import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_router.dart';
import '../models/pdf_document_model.dart';
import '../models/quiz_model.dart';
import '../providers.dart';
import '../services/backend_health_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_primary_navigation_bar.dart';
import '../widgets/app_status_banner.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDocument = ref.watch(currentPdfProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final hasPdfContext =
        currentDocument != null && currentDocument.extractedText.trim().isNotEmpty;
    final backendHealth = ref.watch(backendHealthProvider);
    final savedQuizzes = ref.watch(savedQuizzesProvider);

    return Scaffold(
      bottomNavigationBar: const AppPrimaryNavigationBar(
        currentDestination: PrimaryDestination.home,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            _HomeTopBar(
              onOpenSettings: () {
                Navigator.pushNamed(context, AppRoutes.settings);
              },
            ),
            const SizedBox(height: 20),
            _PrimaryChatPanel(
              backendHealth: backendHealth,
              isOnline: isOnline,
              onOpenChat: () {
                Navigator.pushNamed(context, AppRoutes.generalAiChat);
              },
            ),
            if (!isOnline) ...[
              const SizedBox(height: 16),
              const AppStatusBanner(
                icon: Icons.wifi_off_rounded,
                title: 'Offline mode',
                message:
                    'Manual quiz work, saved quizzes, cached chats, and your last processed PDF still work. AI actions return automatically when you reconnect.',
                backgroundColor: Color(0xFFF2F4F7),
                borderColor: Color(0xFFD0D5DD),
                foregroundColor: Color(0xFF344054),
              ),
            ],
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Continue studying',
              subtitle: currentDocument == null
                  ? 'Upload one PDF and the study flow becomes available.'
                  : 'Jump back into your current document right away.',
            ),
            const SizedBox(height: 12),
            if (currentDocument == null)
              _EmptyPdfWorkspaceCard(
                onUploadPressed: () {
                  Navigator.pushNamed(context, AppRoutes.uploadPdf);
                },
              )
            else
              _CurrentPdfWorkspaceCard(
                document: currentDocument,
                hasPdfContext: hasPdfContext,
                isOnline: isOnline,
              ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Saved quizzes',
              subtitle: 'Your saved sets stay separate from the main study flow.',
            ),
            const SizedBox(height: 12),
            _SavedQuizLibraryRow(
              savedQuizzes: savedQuizzes,
              onOpenPressed: () {
                Navigator.pushNamed(context, AppRoutes.savedQuizzes);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({
    required this.onOpenSettings,
  });

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QuizPDF AI', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Chat with AI or continue your PDF study flow.',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _PrimaryChatPanel extends StatelessWidget {
  const _PrimaryChatPanel({
    required this.backendHealth,
    required this.isOnline,
    required this.onOpenChat,
  });

  final AsyncValue<BackendHealthStatus> backendHealth;
  final bool isOnline;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusTheme = Theme.of(context).extension<AppStatusColors>();

    final (label, toneColor, bgColor) = backendHealth.when(
      loading: () => (
        'Checking AI status',
        const Color(0xFF475467),
        const Color(0xFFF2F4F7),
      ),
      error: (_, __) => (
        'AI temporarily unavailable',
        statusTheme?.warning ?? const Color(0xFFB54708),
        const Color(0xFFFFF4ED),
      ),
      data: (status) => !isOnline
          ? (
              'Offline mode',
              const Color(0xFF475467),
              const Color(0xFFF2F4F7),
            )
          : status.groqWorking
          ? (
              'AI online',
              statusTheme?.success ?? const Color(0xFF157F3D),
              const Color(0xFFECFDF3),
            )
          : (
              'AI temporarily unavailable',
              statusTheme?.warning ?? const Color(0xFFB54708),
              const Color(0xFFFFF4ED),
            ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD0D5DD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: toneColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Chat with AI', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Ask anything, get quick answers, and move into document study only when you need it.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpenChat,
              child: const Text('Open chat'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _EmptyPdfWorkspaceCard extends StatelessWidget {
  const _EmptyPdfWorkspaceCard({
    required this.onUploadPressed,
  });

  final VoidCallback onUploadPressed;

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
            'Upload one PDF to unlock document chat and quiz generation.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onUploadPressed,
              child: const Text('Upload PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPdfWorkspaceCard extends StatelessWidget {
  const _CurrentPdfWorkspaceCard({
    required this.document,
    required this.hasPdfContext,
    required this.isOnline,
  });

  final PdfDocumentModel document;
  final bool hasPdfContext;
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
                    Text(
                      document.fileName,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
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
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.uploadPdf);
                },
                child: const Text('Replace'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasPdfContext
                ? document.previewText
                : 'This PDF is loaded, but readable text is missing. Replace it with a cleaner file to continue.',
            style: theme.textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (!hasPdfContext || !isOnline) ...[
            const SizedBox(height: 16),
            AppStatusBanner(
              icon: !hasPdfContext
                  ? Icons.warning_amber_rounded
                  : Icons.wifi_off_rounded,
              title: !hasPdfContext
                  ? 'Document text unavailable'
                  : 'AI actions need internet',
              message: !hasPdfContext
                  ? 'AI document chat and quiz generation need readable extracted text from the PDF.'
                  : 'You can still read this document and use saved quizzes offline. Reconnect to ask AI or generate a new quiz.',
              backgroundColor: !hasPdfContext
                  ? null
                  : const Color(0xFFF2F4F7),
              borderColor: !hasPdfContext
                  ? null
                  : const Color(0xFFD0D5DD),
              foregroundColor: !hasPdfContext
                  ? null
                  : const Color(0xFF344054),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: hasPdfContext && isOnline
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.pdfAiChat,
                            arguments: PdfAiChatRouteArgs(document: document),
                          );
                        }
                      : null,
                  child: const Text('Ask this PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: hasPdfContext && isOnline
                      ? () {
                          Navigator.pushNamed(context, AppRoutes.pdfQuizHub);
                        }
                      : null,
                  child: const Text('Generate quiz'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedQuizLibraryRow extends StatelessWidget {
  const _SavedQuizLibraryRow({
    required this.savedQuizzes,
    required this.onOpenPressed,
  });

  final AsyncValue<List<QuizModel>> savedQuizzes;
  final VoidCallback onOpenPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = savedQuizzes.when(
      loading: () => 'Loading your saved sets...',
      error: (_, __) => 'Could not load saved quizzes right now.',
      data: (items) => items.isEmpty
          ? 'No saved quizzes yet.'
          : '${items.length} saved ${items.length == 1 ? "quiz" : "quizzes"} ready to reopen.',
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bookmark_outline_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved quizzes', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onOpenPressed,
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
