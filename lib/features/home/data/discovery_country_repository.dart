import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoveryCountryRepository {
  DiscoveryCountryRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<String>> fetchCountryNames() async {
    final raw = await _client.rpc<dynamic>('get_discovery_countries');
    if (raw is! List) return const <String>[];
    final out = <String>[];
    for (final row in raw) {
      if (row is! Map) continue;
      final name = (row['name']?.toString() ?? '').trim();
      if (name.isNotEmpty) out.add(name);
    }
    return out;
  }

  /// Maps ISO 3166-1 alpha-2 (e.g. TR) to [discovery_countries.name] for filter matching.
  Future<String?> countryNameForIsoCode(String isoCode) async {
    final code = isoCode.trim().toUpperCase();
    if (code.isEmpty) return null;
    final raw = await _client.rpc<dynamic>('get_discovery_countries');
    if (raw is! List) return null;
    for (final row in raw) {
      if (row is! Map) continue;
      final c = (row['code']?.toString() ?? '').trim().toUpperCase();
      if (c == code) {
        final name = (row['name']?.toString() ?? '').trim();
        return name.isEmpty ? null : name;
      }
    }
    return null;
  }
}
