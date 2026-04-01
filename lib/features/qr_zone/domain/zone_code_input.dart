/// Normalizes raw QR/manual input so it matches [zones.code] in Supabase (trim + upper).
///
/// Handles URLs that embed the code (`?code=`, `?c=`, path segment) and invisible chars.
String normalizeZoneCodeForJoin(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;

  s = s.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

  final uri = Uri.tryParse(s);
  if (uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' ||
          uri.scheme == 'https' ||
          uri.scheme == 'myapp')) {
    final fromQuery = uri.queryParameters['code'] ??
        uri.queryParameters['zone_code'] ??
        uri.queryParameters['c'] ??
        uri.queryParameters['zone'];
    if (fromQuery != null && fromQuery.trim().isNotEmpty) {
      return fromQuery.trim();
    }
    final segments =
        uri.pathSegments.where((e) => e.isNotEmpty).toList(growable: false);
    if (segments.isNotEmpty) {
      final last = segments.last.trim();
      if (last.isNotEmpty &&
          !last.contains('.') &&
          RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(last)) {
        return last;
      }
    }
  }

  return s;
}
