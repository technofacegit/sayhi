import 'dart:convert';

import 'package:qr_dating_app/features/home/presentation/model/swipe_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads profiles for the home discovery swipe deck.
class DiscoveryRepository {
  DiscoveryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<SwipeProfile>> fetchProfiles({int limit = 24}) async {
    final raw = await _client.rpc<dynamic>(
      'get_discovery_profiles',
      params: {'p_limit': limit},
    );
    final list = _decodeProfileJsonArray(raw);
    return list.map<SwipeProfile>((e) {
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
        gender: (genderRaw != null && genderRaw.isNotEmpty) ? genderRaw : null,
        galleryUrls: gallery,
      );
    }).where((p) => p.id.isNotEmpty).toList();
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
