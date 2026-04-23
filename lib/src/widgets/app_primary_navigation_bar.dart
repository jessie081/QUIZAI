import 'package:flutter/material.dart';

import '../app_router.dart';

enum PrimaryDestination {
  home,
  chat,
  study,
  saved,
}

class AppPrimaryNavigationBar extends StatelessWidget {
  const AppPrimaryNavigationBar({
    super.key,
    required this.currentDestination,
  });

  final PrimaryDestination currentDestination;

  static const _routeMap = <PrimaryDestination, String>{
    PrimaryDestination.home: AppRoutes.home,
    PrimaryDestination.chat: AppRoutes.generalAiChat,
    PrimaryDestination.study: AppRoutes.pdfQuizHub,
    PrimaryDestination.saved: AppRoutes.savedQuizzes,
  };

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentDestination.index,
      onDestinationSelected: (index) {
        final destination = PrimaryDestination.values[index];
        if (destination == currentDestination) {
          return;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          _routeMap[destination]!,
          (route) => false,
        );
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: Icon(Icons.chat_rounded),
          label: 'Chat',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_stories_outlined),
          selectedIcon: Icon(Icons.auto_stories_rounded),
          label: 'Study',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_outline_rounded),
          selectedIcon: Icon(Icons.bookmark_rounded),
          label: 'Saved',
        ),
      ],
    );
  }
}
