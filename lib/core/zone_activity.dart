import 'package:flutter/material.dart';

/// Remaining time as "15 h 57 m" (hours and minutes only, no seconds).
String formatZoneRemainingHm(Duration? remaining) {
  if (remaining == null || remaining.inSeconds <= 0) {
    return '0 h 0 m';
  }
  final ceilMin = (remaining.inSeconds / 60).ceil();
  final h = ceilMin ~/ 60;
  final m = ceilMin % 60;
  return '$h h $m m';
}

/// Parses [activeUntilIso] (UTC or local) and returns remaining until then from [now].
Duration? zoneRemainingFromActiveUntil(String? activeUntilIso, DateTime now) {
  if (activeUntilIso == null || activeUntilIso.isEmpty) return null;
  final end = DateTime.tryParse(activeUntilIso)?.toLocal();
  if (end == null) return null;
  return end.difference(now);
}

bool zoneIsActiveFromRemaining(Duration? remaining, {bool? isActiveNow}) {
  if (remaining != null) return remaining.inSeconds > 0;
  return isActiveNow == true;
}

/// True when the user is still within the 24h window for this zone (may enter without QR).
bool isZoneMembershipActiveForUser(
  Map<String, dynamic> zone, [
  DateTime? now,
]) {
  final t = now ?? DateTime.now();
  final rem = zoneRemainingFromActiveUntil(zone['activeUntil'] as String?, t);
  return zoneIsActiveFromRemaining(
    rem,
    isActiveNow: zone['isActiveNow'] as bool?,
  );
}

/// Short line for map marker subtitle: "Kalan: 15 h 57 m" or "Pasif".
String zoneActivityMapSnippet(Map<String, dynamic> zone, DateTime now) {
  final rem = zoneRemainingFromActiveUntil(
    zone['activeUntil'] as String?,
    now,
  );
  final active = zoneIsActiveFromRemaining(
    rem,
    isActiveNow: zone['isActiveNow'] as bool?,
  );
  if (active) {
    return 'Kalan: ${formatZoneRemainingHm(rem)}';
  }
  return 'Pasif';
}

/// Green dot + "Kalan: …" or grey + "Pasif" for zone maps / lists.
class ZoneActivityStatusRow extends StatelessWidget {
  final String? activeUntilIso;
  final DateTime now;
  final bool? isActiveNowFallback;
  final TextStyle? style;
  final double iconSize;

  const ZoneActivityStatusRow({
    super.key,
    required this.activeUntilIso,
    required this.now,
    this.isActiveNowFallback,
    this.style,
    this.iconSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = zoneRemainingFromActiveUntil(activeUntilIso, now);
    final isActive = zoneIsActiveFromRemaining(remaining, isActiveNow: isActiveNowFallback);
    final color = isActive ? Colors.green : Colors.grey;
    final text = isActive
        ? 'Kalan: ${formatZoneRemainingHm(remaining)}'
        : 'Pasif';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: iconSize, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: style ??
                theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
