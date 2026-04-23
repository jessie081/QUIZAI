import 'package:flutter/widgets.dart';

import '../models/ai_assistant_models.dart';
import 'ai_chat_screen.dart';

class GeneralAiChatScreen extends StatelessWidget {
  const GeneralAiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiChatScreen(
      initialMode: AiChatMode.general,
      showPrimaryNavigation: true,
    );
  }
}
