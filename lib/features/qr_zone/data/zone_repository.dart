import 'package:qr_dating_app/features/qr_zone/presentation/model/icebreaker_question.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/model/zone_member_preview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of [ZoneRepository.fetchZoneMemberPreviews].
class ZoneMemberPreviewsResult {
  const ZoneMemberPreviewsResult({
    required this.activeCount,
    required this.members,
  });

  final int activeCount;
  final List<ZoneMemberPreview> members;
}

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
      final name = venue?['name'] as String? ?? '';
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
        'name': (map['name'] as String?) ?? '',
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
      'name': (raw['name'] as String?) ?? '',
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

  /// Active members in [zoneId] with profile fields; excludes current user.
  /// Caller must be an active member (24h window). Updates [activeCount] from server.
  Future<ZoneMemberPreviewsResult> fetchZoneMemberPreviews(String zoneId) async {
    final raw = await _client.rpc<dynamic>(
      'get_zone_member_previews_for_zone',
      params: {'input_zone_id': zoneId},
    );
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid zone members response');
    }
    final count = (raw['active_count'] as num?)?.toInt() ?? 0;
    final list = raw['members'] as List? ?? const [];
    final members = list.map<ZoneMemberPreview>((e) {
      final m = e as Map<String, dynamic>;
      final uid = m['user_id'] as String? ?? '';
      final avatar = m['avatar_url'] as String?;
      return ZoneMemberPreview(
        id: uid,
        photoUrl: (avatar != null && avatar.isNotEmpty) ? avatar : '',
        name: m['display_name'] as String? ?? '',
        age: (m['age'] as num?)?.toInt(),
        bio: m['bio'] as String? ?? '',
      );
    }).toList(growable: false);
    return ZoneMemberPreviewsResult(activeCount: count, members: members);
  }

  /// Active icebreaker prompts for the empty-zone mini-game (ordered, capped).
  Future<List<IcebreakerQuestion>> fetchIcebreakerQuestions({int limit = 3}) async {
    final rows = await _client
        .from('icebreaker_questions')
        .select('id, prompt, options')
        .eq('is_active', true)
        .order('sort_order')
        .limit(limit);
    final list = rows as List;
    return list.map<IcebreakerQuestion>((raw) {
      final m = raw as Map<String, dynamic>;
      final opts = m['options'];
      final labels = <String>[];
      if (opts is List) {
        for (final o in opts) {
          if (o != null) labels.add(o.toString());
        }
      }
      return IcebreakerQuestion(
        id: m['id'] as String,
        prompt: m['prompt'] as String? ?? '',
        options: labels,
      );
    }).toList(growable: false);
  }

  /// Persists one answer; requires active zone membership (24h), enforced server-side.
  Future<void> submitIcebreakerAnswer({
    required String zoneId,
    required String questionId,
    required int optionIndex,
  }) async {
    await _client.rpc<void>(
      'submit_icebreaker_answer',
      params: {
        'p_zone_id': zoneId,
        'p_question_id': questionId,
        'p_option_index': optionIndex,
      },
    );
  }

  /// Marks membership inactive for the current user (leave zone).
  Future<void> leaveZone(String zoneId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Not signed in');
    }
    await _client.from('zone_members').update({
      'is_active': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('zone_id', zoneId).eq('user_id', uid);
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

