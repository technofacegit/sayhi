import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/zone_preview_card.dart';

class ActiveZoneScreen extends StatelessWidget {
  final Map<String, dynamic> zone;

  const ActiveZoneScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = zone['name'] as String? ?? '';
    final imageUrl = zone['imageUrl'] as String?;
    final count = zone['activeCount'] as int?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Zone'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ZonePreviewCard(
                activeZoneName: name.isEmpty ? null : name,
                activeUserCount: count,
                venueImageUrl: imageUrl,
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    ActiveZoneSession.enterZone(zone);
                    context.go(AppRouter.zoneMainPath);
                  },
                  child: const Text('Enter Zone'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'İptal',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
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
