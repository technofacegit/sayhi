import 'package:flutter/foundation.dart';

/// Debug-only timing logs. Grep console for `[perf]`.
void perfLog(String tag, String message, [Stopwatch? sinceStart]) {
  if (!kDebugMode) return;
  final total = sinceStart != null
      ? '${sinceStart.elapsedMilliseconds}ms '
      : '';
  debugPrint('[perf] $total[$tag] $message');
}
