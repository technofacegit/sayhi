import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads active zones joined with venues for the Zones tab.
class ZoneRepository {
  ZoneRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const Duration _zoneActiveWindow = Duration(hours: 24);

  /// Returns a list of maps shaped like UI expectations.
  Future<List<Map<String, dynamic>>> fetchZones() async {
    final rows = await _client
        .from('zones')
        .select(
          'id, code, is_active, venues ( name, city, image_url, lat, lng ), zone_members!left ( is_active, updated_at )',
        )
        .eq('is_active', true)
        .order('created_at', ascending: false);

    final list = rows as List;
    final uid = _client.auth.currentUser?.id;
    final Map<String, DateTime> myLastSeenUtc = {};
    if (uid != null) {
      try {
        final mine = await _client
            .from('zone_members')
            .select('zone_id, updated_at')
            .eq('user_id', uid);
        final mineList = mine as List;
        for (final raw in mineList) {
          final m = raw as Map<String, dynamic>;
          final zid = m['zone_id'] as String?;
          final u = m['updated_at'] as String?;
          if (zid == null || u == null) continue;
          final t = DateTime.tryParse(u)?.toUtc();
          if (t != null) {
            myLastSeenUtc[zid] = t;
          }
        }
      } catch (_) {
        // Unauthenticated or RLS: leave myLastSeenUtc empty
      }
    }

    final nowUtc = DateTime.now().toUtc();
    final cutoffUtc = nowUtc.subtract(_zoneActiveWindow);

    return list.map<Map<String, dynamic>>((raw) {
      final map = raw as Map<String, dynamic>;
      final venue = (map['venues'] as Map<String, dynamic>?);
      final members = (map['zone_members'] as List?) ?? const [];
      final name = venue?['name'] as String? ?? 'Zone';
      final city = venue?['city'] as String?;
      final imageUrl = venue?['image_url'] as String?;
      final lat = (venue?['lat'] as num?)?.toDouble();
      final lng = (venue?['lng'] as num?)?.toDouble();
      final activeCount = members.whereType<Map<String, dynamic>>().where((m) {
        if (m['is_active'] != true) return false;
        final u = m['updated_at'] as String?;
        if (u == null) return false;
        final t = DateTime.tryParse(u)?.toUtc();
        return t != null && t.isAfter(cutoffUtc);
      }).length;

      final zoneId = map['id'] as String?;
      String? activeUntilIso;
      var isActiveNow = false;
      if (zoneId != null) {
        final last = myLastSeenUtc[zoneId];
        if (last != null) {
          activeUntilIso = last.add(_zoneActiveWindow).toIso8601String();
          isActiveNow = last.isAfter(cutoffUtc);
        }
      }

      return <String, dynamic>{
        'id': zoneId,
        'code': map['code'] as String?,
        'name': name,
        'city': city,
        'imageUrl': imageUrl,
        'activeCount': activeCount,
        'lat': lat,
        'lng': lng,
        'activeUntil': activeUntilIso,
        'isActiveNow': isActiveNow,
      };
    }).toList(growable: false);
  }

  /// Recent zones for the current user, newest first.
  Future<List<Map<String, dynamic>>> fetchRecentZones({int limit = 5}) async {
    final rows = await _client.rpc<dynamic>(
      'get_recent_zones_for_current_user',
      params: {'limit_count': limit},
    );
    final list = rows as List;

    return list.map<Map<String, dynamic>>((raw) {
      final map = raw as Map<String, dynamic>;
      return <String, dynamic>{
        'id': map['id'] as String?,
        'code': map['code'] as String?,
        'name': (map['name'] as String?) ?? 'Zone',
        'city': map['city'] as String?,
        'imageUrl': map['image_url'] as String?,
        'activeCount': (map['active_count'] as num?)?.toInt() ?? 0,
        'lat': (map['lat'] as num?)?.toDouble(),
        'lng': (map['lng'] as num?)?.toDouble(),
        'lastSeenAt': map['last_seen_at'] as String?,
        'activeUntil': map['active_until'] as String?,
        'isActiveNow': map['is_active_now'] == true,
      };
    }).toList(growable: false);
  }

  /// Current active zone for current user within 24h window.
  Future<Map<String, dynamic>?> fetchCurrentActiveZone() async {
    final raw = await _client.rpc<dynamic>('get_current_active_zone_for_current_user');
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) return null;
    return <String, dynamic>{
      'id': raw['id'] as String?,
      'code': raw['code'] as String?,
      'name': (raw['name'] as String?) ?? 'Zone',
      'city': raw['city'] as String?,
      'imageUrl': raw['image_url'] as String?,
      'activeCount': (raw['active_count'] as num?)?.toInt() ?? 0,
      'lat': (raw['lat'] as num?)?.toDouble(),
      'lng': (raw['lng'] as num?)?.toDouble(),
      'lastSeenAt': raw['last_seen_at'] as String?,
      'activeUntil': raw['active_until'] as String?,
      'isActiveNow': raw['is_active_now'] == true,
    };
  }

  /// Validates zone code, joins user to zone_members and returns zone payload.
  Future<Map<String, dynamic>> joinZoneByCode(String code) async {
    final result = await _client.rpc<dynamic>(
      'join_zone_by_code',
      params: {'input_code': code.trim()},
    );
    if (result is Map<String, dynamic>) {
      final joinedAt = result['lastSeenAt'] as String?;
      return <String, dynamic>{
        ...result,
        'activeUntil': joinedAt == null
            ? null
            : DateTime.tryParse(joinedAt)
                ?.toUtc()
                .add(_zoneActiveWindow)
                .toIso8601String(),
        'isActiveNow': true,
      };
    }
    throw Exception('Invalid zone response');
  }

  /// Validates that scanned/manual code belongs to the selected zone_id.
  Future<Map<String, dynamic>> joinZoneByIdAndCode({
    required String zoneId,
    required String code,
  }) async {
    final result = await _client.rpc<dynamic>(
      'join_zone_by_id_and_code',
      params: {
        'input_zone_id': zoneId,
        'input_code': code.trim(),
      },
    );
    if (result is Map<String, dynamic>) {
      final joinedAt = result['lastSeenAt'] as String?;
      return <String, dynamic>{
        ...result,
        'activeUntil': joinedAt == null
            ? null
            : DateTime.tryParse(joinedAt)
                ?.toUtc()
                .add(_zoneActiveWindow)
                .toIso8601String(),
        'isActiveNow': true,
      };
    }
    throw Exception('Invalid zone response');
  }
}

