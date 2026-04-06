import 'package:flutter/material.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Favorites tab (saved profiles); content TBD.
class FavoritesTabScreen extends StatelessWidget {
  const FavoritesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.62);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.favoritesTabTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Text(
                    l10n.favoritesTabPlaceholder,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
