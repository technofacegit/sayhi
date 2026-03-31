import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads active zones joined with venues for the Zones tab.
class ZoneRepository {
  ZoneRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns a list of maps shaped like UI expectations.
  Future<List<Map<String, dynamic>>> fetchZones() async {
    final rows = await _client
        .from('zones')
        .select(
          'id, code, is_active, venues ( name, city, image_url, lat, lng ), zone_members!left ( is_active )',
        )
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final list = rows as List;

    return list.map<Map<String, dynamic>>((raw) {
      final map = raw as Map<String, dynamic>;
      final venue = (map['venues'] as Map<String, dynamic>?);
      final members = (map['zone_members'] as List?) ?? const [];
      final name = venue?['name'] as String? ?? 'Zone';
      final city = venue?['city'] as String?;
      final imageUrl = venue?['image_url'] as String?;
      final lat = (venue?['lat'] as num?)?.toDouble();
      final lng = (venue?['lng'] as num?)?.toDouble();
      final activeCount = members
          .whereType<Map<String, dynamic>>()
          .where((m) => m['is_active'] == true)
          .length;

      return <String, dynamic>{
        'id': map['id'] as String?,
        'code': map['code'] as String?,
        'name': name,
        'city': city,
        'imageUrl': imageUrl,
        'activeCount': activeCount,
        'lat': lat,
        'lng': lng,
      };
    }).toList(growable: false);
  }
}

