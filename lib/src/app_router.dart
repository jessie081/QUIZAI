import 'package:flutter/material.dart';

import 'models/ai_assistant_models.dart';
import 'models/pdf_document_model.dart';
import 'models/quiz_model.dart';
import 'models/quiz_result_model.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/general_ai_chat_screen.dart';
import 'screens/generated_quiz_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manual_quiz_builder_screen.dart';
import 'screens/pdf_processing_screen.dart';
import 'screens/pdf_ai_chat_screen.dart';
import 'screens/pdf_quiz_hub_screen.dart';
import 'screens/quiz_result_screen.dart';
import 'screens/quiz_review_screen.dart';
import 'screens/quiz_settings_screen.dart';
import 'screens/saved_quizzes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/take_quiz_screen.dart';
import 'screens/upload_pdf_screen.dart';
import 'widgets/app_shell_app_bar.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const generalAiChat = '/general-ai-chat';
  static const pdfAiChat = '/pdf-ai-chat';
  static const uploadPdf = '/upload-pdf';
  static const pdfQuizHub = '/pdf-quiz-hub';
  static const manualQuizBuilder = '/manual-quiz-builder';
  static const pdfProcessing = '/pdf-processing';
  static const quizSettings = '/quiz-settings';
  static const generatedQuiz = '/generated-quiz';
  static const takeQuiz = '/take-quiz';
  static const quizResult = '/quiz-result';
  static const quizReview = '/quiz-review';
  static const aiChat = '/ai-chat';
  static const savedQuizzes = '/saved-quizzes';
  static const settings = '/settings';
}

class PdfProcessingRouteArgs {
  const PdfProcessingRouteArgs({required this.document});

  final PdfDocumentModel document;
}

class QuizSettingsRouteArgs {
  const QuizSettingsRouteArgs({required this.document});

  final PdfDocumentModel document;
}

class GeneratedQuizRouteArgs {
  const GeneratedQuizRouteArgs({
    required this.document,
    required this.quiz,
  });

  final PdfDocumentModel document;
  final QuizModel quiz;
}

class QuizResultRouteArgs {
  const QuizResultRouteArgs({
    required this.quiz,
    required this.result,
  });

  final QuizModel quiz;
  final QuizResultModel result;
}

class QuizReviewRouteArgs {
  const QuizReviewRouteArgs({
    required this.quiz,
    this.result,
  });

  final QuizModel quiz;
  final QuizResultModel? result;
}

class AiChatRouteArgs {
  const AiChatRouteArgs({
    this.document,
    this.initialMode = AiChatMode.general,
    this.initialPrompt,
    this.initialActionType = AiActionType.ask,
  });

  final PdfDocumentModel? document;
  final AiChatMode initialMode;
  final String? initialPrompt;
  final AiActionType initialActionType;
}

class PdfAiChatRouteArgs {
  const PdfAiChatRouteArgs({
    required this.document,
    this.initialPrompt,
    this.initialActionType = AiActionType.ask,
  });

  final PdfDocumentModel document;
  final String? initialPrompt;
  final AiActionType initialActionType;
}

class ManualQuizBuilderRouteArgs {
  const ManualQuizBuilderRouteArgs({
    this.quiz,
  });

  final QuizModel? quiz;
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);
      case AppRoutes.home:
        return _page(const HomeScreen(), settings);
      case AppRoutes.generalAiChat:
        return _page(const GeneralAiChatScreen(), settings);
      case AppRoutes.pdfAiChat:
        final args = settings.arguments;
        if (args is PdfAiChatRouteArgs) {
          return _page(
            PdfAiChatScreen(
              document: args.document,
              initialPrompt: args.initialPrompt,
              initialActionType: args.initialActionType,
            ),
            settings,
          );
        }
        return _errorRoute('Missing PDF AI chat arguments.', settings);
      case AppRoutes.uploadPdf:
        return _page(const UploadPdfScreen(), settings);
      case AppRoutes.pdfQuizHub:
        return _page(const PdfQuizHubScreen(), settings);
      case AppRoutes.manualQuizBuilder:
        final args = settings.arguments;
        if (args == null) {
          return _page(const ManualQuizBuilderScreen(), settings);
        }
        if (args is ManualQuizBuilderRouteArgs) {
          return _page(
            ManualQuizBuilderScreen(initialQuiz: args.quiz),
            settings,
          );
        }
        return _errorRoute('Invalid manual quiz builder arguments.', settings);
      case AppRoutes.pdfProcessing:
        final args = settings.arguments;
        if (args is PdfProcessingRouteArgs) {
          return _page(PdfProcessingScreen(document: args.document), settings);
        }
        return _errorRoute('Missing PDF processing arguments.', settings);
      case AppRoutes.quizSettings:
        final args = settings.arguments;
        if (args is QuizSettingsRouteArgs) {
          return _page(QuizSettingsScreen(document: args.document), settings);
        }
        return _errorRoute('Missing quiz settings arguments.', settings);
      case AppRoutes.generatedQuiz:
        final args = settings.arguments;
        if (args is GeneratedQuizRouteArgs) {
          return _page(
            GeneratedQuizScreen(document: args.document, quiz: args.quiz),
            settings,
          );
        }
        return _errorRoute('Missing generated quiz arguments.', settings);
      case AppRoutes.takeQuiz:
        final args = settings.arguments;
        if (args is QuizModel) {
          return _page(TakeQuizScreen(quiz: args), settings);
        }
        return _errorRoute('Missing quiz to take.', settings);
      case AppRoutes.quizResult:
        final args = settings.arguments;
        if (args is QuizResultRouteArgs) {
          return _page(
            QuizResultScreen(
              quiz: args.quiz,
              result: args.result,
            ),
            settings,
          );
        }
        return _errorRoute('Missing quiz result arguments.', settings);
      case AppRoutes.quizReview:
        final args = settings.arguments;
        if (args is QuizReviewRouteArgs) {
          return _page(
            QuizReviewScreen(
              quiz: args.quiz,
              result: args.result,
            ),
            settings,
          );
        }
        return _errorRoute('Missing quiz review arguments.', settings);
      case AppRoutes.aiChat:
        final args = settings.arguments;
        if (args == null) {
          return _page(const AiChatScreen(), settings);
        }
        if (args is AiChatRouteArgs) {
          return _page(
            AiChatScreen(
              document: args.document,
              initialMode: args.initialMode,
              initialPrompt: args.initialPrompt,
              initialActionType: args.initialActionType,
            ),
            settings,
          );
        }
        return _errorRoute('Missing AI chat arguments.', settings);
      case AppRoutes.savedQuizzes:
        return _page(const SavedQuizzesScreen(), settings);
      case AppRoutes.settings:
        return _page(const SettingsScreen(), settings);
      default:
        return _errorRoute('Route not found: ${settings.name}', settings);
    }
  }

  static MaterialPageRoute<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<void>(
      builder: (_) => child,
      settings: settings,
    );
  }

  static MaterialPageRoute<dynamic> _errorRoute(
    String message,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: const AppShellAppBar(title: 'Navigation Error'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
