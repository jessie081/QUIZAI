import 'package:flutter/widgets.dart';

import '../models/ai_assistant_models.dart';
import '../models/pdf_document_model.dart';
import 'ai_chat_screen.dart';

class PdfAiChatScreen extends StatelessWidget {
  const PdfAiChatScreen({
    super.key,
    required this.document,
    this.initialPrompt,
    this.initialActionType = AiActionType.ask,
  });

  final PdfDocumentModel document;
  final String? initialPrompt;
  final AiActionType initialActionType;

  @override
  Widget build(BuildContext context) {
    return AiChatScreen(
      document: document,
      initialMode: AiChatMode.pdf,
      initialPrompt: initialPrompt,
      initialActionType: initialActionType,
    );
  }
}
