import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:qr_dating_app/core/perf_log.dart';
import 'package:qr_dating_app/features/auth/presentation/deep_link/auth_deep_link_coordinator.dart';
import 'package:qr_dating_app/l10n/app_localizations.dart';

import 'router/go_router_config.dart';
import 'theme/theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AuthDeepLinkCoordinator? _deepLinks;

  @override
  void initState() {
    super.initState();
    _deepLinks = AuthDeepLinkCoordinator();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      perfLog('App', 'first frame (MaterialApp.router mounted)');
      _deepLinks?.init();
    });
  }

  @override
  void dispose() {
    _deepLinks?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'Say Hi',
      theme: buildAppTheme(),
      routerConfig: AppGoRouter.router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
