import 'package:flutter/material.dart';

import '../models/ai_assistant_models.dart';

class AiAssistantCard extends StatelessWidget {
  const AiAssistantCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.prompts,
    required this.onPromptTap,
    this.enabled = true,
    this.primaryButtonLabel,
    this.onPrimaryPressed,
  });

  final String title;
  final String subtitle;
  final List<AiPromptSuggestion> prompts;
  final ValueChanged<AiPromptSuggestion> onPromptTap;
  final bool enabled;
  final String? primaryButtonLabel;
  final VoidCallback? onPrimaryPressed;

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
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF155EEF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (onPrimaryPressed != null && primaryButtonLabel != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: enabled ? onPrimaryPressed : null,
                child: Text(primaryButtonLabel!),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prompts
                .map(
                  (prompt) => ActionChip(
                      label: Text(prompt.label),
                      onPressed: enabled ? () => onPromptTap(prompt) : null,
                    ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
