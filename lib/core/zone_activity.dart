import 'package:flutter/material.dart';
import 'package:qr_dating_app/l10n/app_localizations.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Remaining time label using locale (hours and minutes only).
String formatZoneRemainingHm(AppLocalizations l10n, Duration? remaining) {
  if (remaining == null || remaining.inSeconds <= 0) {
    return l10n.zoneDurationZero;
  }
  final ceilMin = (remaining.inSeconds / 60).ceil();
  final h = ceilMin ~/ 60;
  final m = ceilMin % 60;
  return l10n.zoneDurationHm(h, m);
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

/// Short line for map marker subtitle.
String zoneActivityMapSnippet(AppLocalizations l10n, Map<String, dynamic> zone, DateTime now) {
  final rem = zoneRemainingFromActiveUntil(
    zone['activeUntil'] as String?,
    now,
  );
  final active = zoneIsActiveFromRemaining(
    rem,
    isActiveNow: zone['isActiveNow'] as bool?,
  );
  if (active) {
    return l10n.recentZoneRemaining(formatZoneRemainingHm(l10n, rem));
  }
  return l10n.zoneInactive;
}

/// Green dot + remaining line or grey + inactive for zone maps / lists.
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
    final l10n = context.l10n;
    final remaining = zoneRemainingFromActiveUntil(activeUntilIso, now);
    final isActive = zoneIsActiveFromRemaining(remaining, isActiveNow: isActiveNowFallback);
    final color = isActive ? Colors.green : Colors.grey;
    final text = isActive
        ? l10n.recentZoneRemaining(formatZoneRemainingHm(l10n, remaining))
        : l10n.zoneInactive;

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
