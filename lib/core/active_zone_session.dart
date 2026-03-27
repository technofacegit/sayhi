/// In-memory active zone after user taps "Enter Zone" (no backend).
abstract final class ActiveZoneSession {
  static Map<String, dynamic>? _current;

  static Map<String, dynamic>? get current =>
      _current == null ? null : Map<String, dynamic>.from(_current!);

  static void enterZone(Map<String, dynamic> zone) {
    _current = Map<String, dynamic>.from(zone);
  }

  static void clear() {
    _current = null;
  }
}
