import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';

class ActiveZoneScreen extends StatelessWidget {
  final Map<String, dynamic> zone;

  const ActiveZoneScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = zone['name'] as String? ?? '';
    final imageUrl = zone['imageUrl'] as String?;
    final count = zone['activeCount'] as int? ?? 0;

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
              Text(
                'Active Zone',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ZoneImageFallback(
                            zoneName: name.isEmpty ? 'Zone' : name,
                          ),
                        )
                      : _ZoneImageFallback(
                          zoneName: name.isEmpty ? 'Zone' : name,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name.isEmpty ? 'Zone' : name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count aktif kullanici',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    final zoneId = (zone['id'] as String?)?.trim();
                    if (zoneId == null || zoneId.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bu zone icin gecerli bir ID yok.'),
                        ),
                      );
                      return;
                    }
                    context.go(AppRouter.qrJoinPath, extra: zoneId);
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

class _ZoneImageFallback extends StatelessWidget {
  final String zoneName;

  const _ZoneImageFallback({required this.zoneName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.35),
            colorScheme.secondary.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Center(
        child: Text(
          zoneName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
