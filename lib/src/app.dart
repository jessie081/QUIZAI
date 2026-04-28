import 'package:flutter/material.dart';

import 'app_router.dart';
import 'theme/app_theme.dart';

class QuizPdfApp extends StatelessWidget {
  const QuizPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizPDF AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('en', 'US'),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
