import 'package:flutter/foundation.dart';
import 'package:qr_dating_app/features/home/presentation/model/story_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads story groups + slides from Supabase.
///
/// Schema expected (see migrations):
/// - story_groups(id, label, ring_image_url, expires_at, created_at)
/// - story_slides(id, story_group_id, slide_index, image_url, title?, body?)
/// - story_views(user_id, story_group_id, viewed_at)
///
/// Non-expired rows are enforced by RLS; slides are ordered in Dart by [slide_index].
class StoryRepository {
  StoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _selectFull =
      'id, label, ring_image_url, story_slides ( slide_index, image_url, title, body ), story_views!left ( user_id )';

  static const _selectMinimal =
      'id, label, ring_image_url, story_slides ( slide_index, image_url ), story_views!left ( user_id )';

  Future<List<StoryGroup>> fetchStoryGroups() async {
    try {
      return await _fetchWithSelect(_selectFull);
    } catch (e1, st1) {
      debugPrint('StoryRepository.fetchStoryGroups (full): $e1');
      debugPrint('$st1');
      try {
        return await _fetchWithSelect(_selectMinimal);
      } catch (e2, st2) {
        debugPrint('StoryRepository.fetchStoryGroups (minimal): $e2');
        debugPrint('$st2');
        return <StoryGroup>[];
      }
    }
  }

  Future<List<StoryGroup>> _fetchWithSelect(String select) async {
    final rows = await _client
        .from('story_groups')
        .select(select)
        .order('created_at', ascending: false);

    final list = rows as List;
    if (kDebugMode) {
      debugPrint('StoryRepository: story_groups rows from API: ${list.length}');
    }

    final groups = list.map<StoryGroup>((raw) {
      final map = raw as Map<String, dynamic>;
      final id = map['id'] == null ? '' : map['id'].toString();
      final label = (map['label'] ?? '') as String;
      final ringImageUrl = (map['ring_image_url'] ?? '') as String;
      final slidesRaw = (map['story_slides'] as List?) ?? const [];
      final viewsRaw = (map['story_views'] as List?) ?? const [];

      final slideMaps = slidesRaw.whereType<Map<String, dynamic>>().toList()
        ..sort((a, b) {
          final ia = (a['slide_index'] as num?)?.toInt() ?? 0;
          final ib = (b['slide_index'] as num?)?.toInt() ?? 0;
          return ia.compareTo(ib);
        });

      final urls = <String>[];
      final titles = <String>[];
      final bodies = <String>[];

      for (final rawSlide in slideMaps) {
        final url = (rawSlide['image_url'] ?? '') as String;
        if (url.isEmpty) continue;
        urls.add(url);
        titles.add((rawSlide['title'] ?? '') as String);
        bodies.add((rawSlide['body'] ?? '') as String);
      }

      final isUnseen = viewsRaw.isEmpty;

      if (urls.isEmpty) {
        return StoryGroup(
          id: id.isNotEmpty ? id : null,
          label: label.isNotEmpty ? label : 'Story',
          ringImageUrl: ringImageUrl,
          slideImageUrls: ringImageUrl.isNotEmpty ? [ringImageUrl] : const [],
          slideTitles: const [],
          slideBodies: const [],
          isUnseen: isUnseen,
        );
      }

      return StoryGroup(
        id: id.isNotEmpty ? id : null,
        label: label.isNotEmpty ? label : 'Story',
        ringImageUrl: ringImageUrl.isNotEmpty ? ringImageUrl : urls.first,
        slideImageUrls: urls,
        slideTitles: titles,
        slideBodies: bodies,
        isUnseen: isUnseen,
      );
    }).where((g) => g.slideImageUrls.isNotEmpty).toList(growable: false);

    if (kDebugMode && list.isNotEmpty && groups.isEmpty) {
      debugPrint(
        'StoryRepository: all groups dropped (need non-empty image_url on slides or ring_image_url on group)',
      );
    }

    final unseen = groups.where((g) => g.isUnseen).toList();
    final seen = groups.where((g) => !g.isUnseen).toList();
    return [...unseen, ...seen];
  }

  /// Marks a story group as viewed for the current user.
  /// No-ops if [storyGroupId] is not a valid UUID (safety guard).
  Future<void> markStoryGroupViewed(String storyGroupId) async {
    if (!_isUuid(storyGroupId)) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('story_views').upsert({
      'user_id': userId,
      'story_group_id': storyGroupId,
    });
  }
}

bool _isUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value.trim());
}
