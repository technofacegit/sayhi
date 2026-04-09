import 'dart:convert';

import 'package:qr_dating_app/features/home/presentation/model/swipe_profile.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads profiles for the home discovery swipe deck.
class DiscoveryRepository {
  DiscoveryRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> updateMyLocation({
    required double lat,
    required double lng,
    String? country,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('profiles')
        .update({
          'lat': lat,
          'lng': lng,
          'country': country?.trim().isEmpty == true ? null : country?.trim(),
          'location_updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', uid);
  }

  Future<List<SwipeProfile>> fetchProfiles({
    int limit = 24,
    ZoneLobbyFilters filters = ZoneLobbyFilters.none,
  }) async {
    final raw = await _client.rpc<dynamic>(
      'get_discovery_profiles',
      params: <String, dynamic>{
        'p_limit': limit,
        'p_gender_filter': filters.gender,
        'p_min_age': filters.minAge,
        'p_max_age': filters.maxAge,
        'p_country_filters': filters.countries,
        'p_max_distance_km': filters.maxDistanceKm,
      },
    );
    final list = _decodeProfileJsonArray(raw);
    return list
        .map<SwipeProfile>((e) {
          final m = Map<String, dynamic>.from(e as Map);
          final uid = (m['user_id']?.toString() ?? '').trim();
          final avatar = m['avatar_url'] as String?;
          final galleryRaw = m['gallery_urls'];
          final gallery = <String>[];
          if (galleryRaw is List) {
            for (final x in galleryRaw) {
              final s = x?.toString() ?? '';
              if (s.isNotEmpty) gallery.add(s);
            }
          }
          final genderRaw = m['gender'] as String?;
          return SwipeProfile(
            id: uid,
            photoUrl: (avatar != null && avatar.isNotEmpty) ? avatar : '',
            name: m['display_name'] as String? ?? '',
            age: (m['age'] as num?)?.toInt(),
            bio: m['bio'] as String? ?? '',
            gender: (genderRaw != null && genderRaw.isNotEmpty)
                ? genderRaw
                : null,
            galleryUrls: gallery,
          );
        })
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  /// PostgREST may return a JSON array as [List], or (rarely) as a JSON string.
  static List<dynamic> _decodeProfileJsonArray(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
      return const [];
    }
    return const [];
  }
}
