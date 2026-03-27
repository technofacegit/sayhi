import 'package:flutter/material.dart';

import 'router/go_router_config.dart';
import 'theme/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Say Hi',
      theme: buildAppTheme(),
      routerConfig: AppGoRouter.router,
    );
  }
}

