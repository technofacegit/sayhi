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
}
