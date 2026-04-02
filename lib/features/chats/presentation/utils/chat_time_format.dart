import 'package:qr_dating_app/l10n/app_localizations.dart';

String formatChatListTimestamp(DateTime utcOrLocal, AppLocalizations l10n) {
  final local = utcOrLocal.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final msgDay = DateTime(local.year, local.month, local.day);
  if (msgDay == today) {
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  final yesterday = today.subtract(const Duration(days: 1));
  if (msgDay == yesterday) {
    return l10n.chatYesterday;
  }
  if (now.difference(local).inDays < 7) {
    final weekdays = [
      l10n.chatWeekdayMon,
      l10n.chatWeekdayTue,
      l10n.chatWeekdayWed,
      l10n.chatWeekdayThu,
      l10n.chatWeekdayFri,
      l10n.chatWeekdaySat,
      l10n.chatWeekdaySun,
    ];
    return weekdays[local.weekday - 1];
  }
  return '${local.day}/${local.month}/${local.year}';
}

String formatMessageTime(DateTime t) {
  final local = t.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
