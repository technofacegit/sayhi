String formatChatListTimestamp(DateTime utcOrLocal) {
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
    return 'Yesterday';
  }
  if (now.difference(local).inDays < 7) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
