import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';

/// Shown only after user confirms "Enter Zone" on [ActiveZoneScreen].
class ZoneMainScreen extends StatelessWidget {
  const ZoneMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final zone = ActiveZoneSession.current!;
    final name = zone['name'] as String? ?? 'Zone';

    void goBack() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRouter.homePath);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: goBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Zone',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You are in this zone. Feed and discovery will live here.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: goBack,
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
