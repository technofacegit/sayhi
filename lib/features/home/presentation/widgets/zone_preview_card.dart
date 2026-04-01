import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_dating_app/core/zone_activity.dart';

class ZonePreviewCard extends StatefulWidget {
  final String? activeZoneName;
  final int? activeUserCount;
  final String? venueImageUrl;
  final String? activeUntil;
  final bool? isActiveNow;
  /// When set and [activeZoneName] is non-empty, the whole card is tappable.
  final VoidCallback? onTap;

  const ZonePreviewCard({
    super.key,
    this.activeZoneName,
    this.activeUserCount,
    this.venueImageUrl,
    this.activeUntil,
    this.isActiveNow,
    this.onTap,
  });

  @override
  State<ZonePreviewCard> createState() => _ZonePreviewCardState();
}

class _ZonePreviewCardState extends State<ZonePreviewCard> {
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
    final colorScheme = theme.colorScheme;
    final joined = widget.activeZoneName != null && widget.activeZoneName!.isNotEmpty;
    final tappable = joined && widget.onTap != null;
    final activeUntil = DateTime.tryParse(widget.activeUntil ?? '')?.toLocal();

    final content = ValueListenableBuilder<DateTime>(
      valueListenable: _ticker,
      builder: (context, now, _) {
        final remaining = activeUntil?.difference(now);
        final isActive = remaining != null
            ? remaining.inSeconds > 0
            : (widget.isActiveNow == true);
        final statusColor = isActive ? Colors.green : Colors.grey;
        final countdown = formatZoneRemainingHm(remaining);
        return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                joined ? Icons.place_rounded : Icons.location_off_outlined,
                size: 22,
                color: joined ? statusColor : colorScheme.onSurface.withValues(alpha: 0.45),
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
            Text(
              widget.activeZoneName!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.activeUserCount ?? 0} active now',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Kalan: $countdown' : 'Pasif',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
      },
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tappable ? widget.onTap : null,
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
