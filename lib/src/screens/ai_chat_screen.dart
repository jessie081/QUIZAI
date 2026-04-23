import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_prompt_templates.dart';
import '../app_router.dart';
import '../models/ai_assistant_models.dart';
import '../models/chat_message_model.dart';
import '../models/pdf_document_model.dart';
import '../providers.dart';
import '../widgets/app_primary_navigation_bar.dart';
import '../widgets/app_shell_app_bar.dart';
import '../widgets/app_status_banner.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({
    super.key,
    this.document,
    this.initialMode = AiChatMode.general,
    this.initialPrompt,
    this.initialActionType = AiActionType.ask,
    this.showPrimaryNavigation = false,
  });

  final PdfDocumentModel? document;
  final AiChatMode initialMode;
  final String? initialPrompt;
  final AiActionType initialActionType;
  final bool showPrimaryNavigation;

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AiChatMode _selectedMode;
  bool _didSendInitialPrompt = false;

  bool get _hasPdfContext {
    final document = widget.document;
    if (document == null) {
      return false;
    }
    return document.extractedText.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _selectedMode =
        widget.initialMode == AiChatMode.pdf && _hasPdfContext
            ? AiChatMode.pdf
            : AiChatMode.general;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _submitInitialPromptIfNeeded();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitInitialPromptIfNeeded() {
    final initialPrompt = widget.initialPrompt?.trim();
    if (_didSendInitialPrompt || initialPrompt == null || initialPrompt.isEmpty) {
      return;
    }

    if (!ref.read(isOnlineProvider)) {
      return;
    }

    _didSendInitialPrompt = true;
    _notifierForMode(_selectedMode).submitPrompt(
      prompt: initialPrompt,
      actionType: widget.initialActionType,
    );
  }

  Future<void> _sendMessage({AiActionType actionType = AiActionType.ask}) async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    _controller.clear();
    await _notifierForMode(_selectedMode).submitPrompt(
      prompt: prompt,
      actionType: actionType,
    );

    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  AiConversationNotifier _notifierForMode(AiChatMode mode) {
    switch (mode) {
      case AiChatMode.general:
        return ref.read(generalConversationProvider.notifier);
      case AiChatMode.pdf:
        final doc = widget.document;
        if (doc == null) {
          return ref.read(generalConversationProvider.notifier);
        }
        return ref.read(pdfConversationProvider(doc).notifier);
    }
  }

  AiConversationState _conversationForSelectedMode() {
    switch (_selectedMode) {
      case AiChatMode.general:
        return ref.watch(generalConversationProvider);
      case AiChatMode.pdf:
        final doc = widget.document;
        if (doc == null) {
          return ref.watch(generalConversationProvider);
        }
        return ref.watch(pdfConversationProvider(doc));
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversationForSelectedMode();
    final isOnline = ref.watch(isOnlineProvider);
    final promptSuggestions = _selectedMode == AiChatMode.general
        ? AiPromptTemplates.generalActions
        : AiPromptTemplates.studyActions;

    return Scaffold(
      appBar: AppShellAppBar(
        title: _selectedMode == AiChatMode.general ? 'Chat' : 'This PDF',
      ),
      bottomNavigationBar: widget.showPrimaryNavigation
          ? const AppPrimaryNavigationBar(
              currentDestination: PrimaryDestination.chat,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ChatHeader(
                mode: _selectedMode,
                document: widget.document,
                hasPdfContext: _hasPdfContext,
                isOnline: isOnline,
                onModeChanged: _hasPdfContext
                    ? (mode) {
                        if (_selectedMode == mode) {
                          return;
                        }
                        setState(() {
                          _selectedMode = mode;
                        });
                      }
                    : null,
              ),
            ),
            if (!isOnline)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AppStatusBanner(
                  icon: Icons.wifi_off_rounded,
                  title: 'Offline mode',
                  message:
                      'You can read cached AI conversations here, but sending new AI requests requires internet connection.',
                  backgroundColor: Color(0xFFF2F4F7),
                  borderColor: Color(0xFFD0D5DD),
                  foregroundColor: Color(0xFF344054),
                ),
              ),
            if (conversation.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: AppStatusBanner(
                  icon: Icons.error_outline_rounded,
                  title: 'AI unavailable',
                  message: conversation.errorMessage!,
                  backgroundColor: const Color(0xFFFEF3F2),
                  borderColor: const Color(0xFFFDA29B),
                  foregroundColor: const Color(0xFFB42318),
                  primaryActionLabel: conversation.lastFailedPrompt != null
                      ? 'Retry'
                      : null,
                  onPrimaryAction: conversation.lastFailedPrompt != null &&
                          !conversation.isLoading
                      ? _notifierForMode(_selectedMode).retryLastPrompt
                      : null,
                  secondaryActionLabel: 'Settings',
                  onSecondaryAction: () {
                    Navigator.pushNamed(context, AppRoutes.settings);
                  },
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: promptSuggestions
                    .map(
                      (prompt) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(prompt.label),
                          onPressed: isOnline
                              ? () {
                            _notifierForMode(_selectedMode).submitPrompt(
                              prompt: prompt.prompt,
                              actionType: prompt.actionType,
                            );
                          }
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD0D5DD)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  itemCount:
                      conversation.messages.length + (conversation.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= conversation.messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 8, top: 10),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                        ),
                      );
                    }

                    final message = conversation.messages[index];
                    return _ChatBubble(message: message);
                  },
                ),
              ),
            ),
            _ChatComposer(
              controller: _controller,
              isOnline: isOnline,
              isLoading: conversation.isLoading,
              hintText: _selectedMode == AiChatMode.general
                  ? 'Ask anything'
                  : 'Ask about this PDF',
              onSubmitted: () => _sendMessage(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.mode,
    required this.document,
    required this.hasPdfContext,
    required this.isOnline,
    this.onModeChanged,
  });

  final AiChatMode mode;
  final PdfDocumentModel? document;
  final bool hasPdfContext;
  final bool isOnline;
  final ValueChanged<AiChatMode>? onModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
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
                      mode == AiChatMode.general
                          ? 'AI conversation'
                          : (document?.fileName ?? 'This PDF'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mode == AiChatMode.general
                          ? 'Use this for quick questions, brainstorming, and study help on any topic.'
                          : 'Responses stay grounded in the uploaded document.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (mode == AiChatMode.pdf && document != null)
                Chip(label: Text('${document!.wordCount} words')),
            ],
          ),
          const SizedBox(height: 14),
          if (hasPdfContext)
            SegmentedButton<AiChatMode>(
              segments: const <ButtonSegment<AiChatMode>>[
                ButtonSegment<AiChatMode>(
                  value: AiChatMode.general,
                  label: Text('General'),
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                ),
                ButtonSegment<AiChatMode>(
                  value: AiChatMode.pdf,
                  label: Text('This PDF'),
                  icon: Icon(Icons.description_outlined),
                ),
              ],
              selected: <AiChatMode>{mode},
              onSelectionChanged: (selection) {
                if (onModeChanged != null) {
                  onModeChanged!(selection.first);
                }
              },
            )
          else if (document != null)
            const AppStatusBanner(
              icon: Icons.warning_amber_rounded,
              title: 'PDF mode unavailable',
              message:
                  'This file does not have readable extracted text yet, so document-grounded chat is turned off.',
            ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF155EEF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUser ? const Color(0xFF155EEF) : const Color(0xFFD0D5DD),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser ? Colors.white : const Color(0xFF101828),
                height: 1.5,
              ),
            ),
            if (!isUser && message.citations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Grounded passages',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF155EEF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              ...message.citations.map(
                (citation) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '- $citation',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.isOnline,
    required this.isLoading,
    required this.hintText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isOnline;
  final bool isLoading;
  final String hintText;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(color: Color(0xFFD0D5DD)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              enabled: isOnline,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText:
                    isOnline ? hintText : 'Connect to the internet to use AI',
              ),
              onSubmitted: isOnline ? (_) => onSubmitted() : null,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            height: 56,
            child: ElevatedButton(
              onPressed: !isOnline || isLoading ? null : onSubmitted,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
