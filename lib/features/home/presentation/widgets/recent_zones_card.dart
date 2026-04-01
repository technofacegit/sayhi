import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/zone_activity.dart';

class RecentZonesCard extends StatefulWidget {
  final List<Map<String, dynamic>> zones;

  const RecentZonesCard({super.key, required this.zones});

  @override
  State<RecentZonesCard> createState() => _RecentZonesCardState();
}

class _RecentZonesCardState extends State<RecentZonesCard> {
  late final ValueNotifier<DateTime> _ticker;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _ticker = ValueNotifier<DateTime>(DateTime.now());
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _ticker.value = DateTime.now(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<DateTime>(
      valueListenable: _ticker,
      builder: (context, now, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent zones',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final zone = widget.zones[index];
              return _RecentZoneFeedCard(
                zone: zone,
                now: now,
                onTap: () {
                  context.push(
                    AppRouter.activeZonePath,
                    extra: Map<String, dynamic>.from(zone),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentZoneFeedCard extends StatelessWidget {
  final Map<String, dynamic> zone;
  final DateTime now;
  final VoidCallback onTap;

  const _RecentZoneFeedCard({
    required this.zone,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = zone['name'] as String? ?? '';
    final count = zone['activeCount'] as int? ?? 0;
    final imageUrl = zone['imageUrl'] as String?;
    final activeUntilIso = zone['activeUntil'] as String?;
    final remaining = zoneRemainingFromActiveUntil(activeUntilIso, now);
    final isActive = zoneIsActiveFromRemaining(
      remaining,
      isActiveNow: zone['isActiveNow'] as bool?,
    );
    final statusColor = isActive ? Colors.green : Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 2.2,
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _FallbackZoneImage(label: name),
                  )
                else
                  _FallbackZoneImage(label: name),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count active',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.circle, size: 10, color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              isActive
                                  ? 'Kalan: ${formatZoneRemainingHm(remaining)}'
                                  : 'Pasif',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _FallbackZoneImage extends StatelessWidget {
  final String label;

  const _FallbackZoneImage({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
        ),
      ),
    );
  }
}
