import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/widgets/zone_icebreaker_game.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Warm Up: icebreaker questions only; after completion opens Lobby to see profiles.
class ZoneWarmUpScreen extends StatelessWidget {
  const ZoneWarmUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final zone = ActiveZoneSession.current;
    final zoneId = zone?['id'] as String?;
    final venueName =
        (zone?['name'] as String?)?.trim().isNotEmpty == true
            ? zone!['name'] as String
            : l10n.defaultVenueName;
    final onSurfaceMuted = colorScheme.onSurface.withValues(alpha: 0.62);
    final repo = ZoneRepository();

    if (zoneId == null || zoneId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.zoneWarmUpTitle)),
        body: Center(child: Text(l10n.zoneMainMissingZoneId)),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRouter.zoneMainPath);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.zoneWarmUpTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          venueName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ZoneIcebreakerGame(
                zoneId: zoneId,
                repository: repo,
                onIcebreakerComplete: () {
                  context.push(AppRouter.zoneLobbyPath);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
