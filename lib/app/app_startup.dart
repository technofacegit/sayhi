import 'package:flutter/material.dart';

import 'package:qr_dating_app/app/app.dart';
import 'package:qr_dating_app/app/theme/theme.dart';

/// Shows the first frame immediately, then [App] after Supabase is ready.
/// Avoids blocking [runApp] on network/local auth restore (cold start feels faster).
class AppStartup extends StatelessWidget {
  const AppStartup({super.key, required this.bootstrapFuture});

  final Future<void> bootstrapFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          final theme = buildAppTheme();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: Scaffold(
              backgroundColor: theme.colorScheme.surface,
              body: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          final theme = buildAppTheme();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: Scaffold(
              backgroundColor: theme.colorScheme.surface,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return const App();
      },
    );
  }
}
