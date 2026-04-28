import 'package:flutter/material.dart';

import '../app_router.dart';

class AppShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppShellAppBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.automaticallyImplyLeading = true,
    this.showHomeAction = true,
  });

  final String title;
  final List<Widget> actions;
  final bool automaticallyImplyLeading;
  final bool showHomeAction;

  static void goHome(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName == AppRoutes.home) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: <Widget>[
        ...actions,
        if (showHomeAction)
          IconButton(
            tooltip: 'Home',
            onPressed: () => goHome(context),
            icon: const Icon(Icons.home_rounded),
          ),
      ],
    );
  }
}
