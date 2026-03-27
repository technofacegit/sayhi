import 'package:flutter/material.dart';

class ZonePreviewCard extends StatelessWidget {
  final String? activeZoneName;
  final int? activeUserCount;
  final String? venueImageUrl;
  /// When set and [activeZoneName] is non-empty, the whole card is tappable.
  final VoidCallback? onTap;

  const ZonePreviewCard({
    super.key,
    this.activeZoneName,
    this.activeUserCount,
    this.venueImageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final joined = activeZoneName != null && activeZoneName!.isNotEmpty;
    final tappable = joined && onTap != null;

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                joined ? Icons.place_rounded : Icons.location_off_outlined,
                size: 22,
                color: joined
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  joined ? 'Active zone' : 'No active zone',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (joined) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: venueImageUrl != null
                    ? Image.network(
                        venueImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _FallbackVenueVisual(
                            zoneName: activeZoneName!,
                          );
                        },
                      )
                    : _FallbackVenueVisual(
                        zoneName: activeZoneName!,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              activeZoneName!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${activeUserCount ?? 24} active now',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ] else
            Text(
              'Join a zone to see who is here right now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
        ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tappable ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          ),
          child: content,
        ),
      ),
    );
  }
}

class _FallbackVenueVisual extends StatelessWidget {
  final String zoneName;

  const _FallbackVenueVisual({required this.zoneName});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
