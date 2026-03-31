import 'package:qr_dating_app/features/home/presentation/model/story_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads story groups + slides from Supabase.
///
  /// Schema expected (see migrations):
  /// - story_groups(id, label, ring_image_url, expires_at, created_at)
  /// - story_slides(id, story_group_id, slide_index, image_url, title, body)
  /// - story_views(user_id, story_group_id, viewed_at)
class StoryRepository {
  StoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<StoryGroup>> fetchStoryGroups() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final rows = await _client
        .from('story_groups')
        .select(
          'id, label, ring_image_url, story_slides ( slide_index, image_url, title, body ), story_views!left ( user_id )',
        )
        .gt('expires_at', nowIso)
        .order('created_at', ascending: false)
        .order('slide_index', referencedTable: 'story_slides', ascending: true);

    final list = rows as List;

    final groups = list.map<StoryGroup>((raw) {
      final map = raw as Map<String, dynamic>;
      final id = (map['id'] ?? '') as String;
      final label = (map['label'] ?? '') as String;
      final ringImageUrl = (map['ring_image_url'] ?? '') as String;
      final slidesRaw = (map['story_slides'] as List?) ?? const [];
      final viewsRaw = (map['story_views'] as List?) ?? const [];

      final urls = <String>[];
      final titles = <String>[];
      final bodies = <String>[];

      for (final rawSlide in slidesRaw.whereType<Map<String, dynamic>>()) {
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

    // Unseen first, then seen; each group keeps its own created_at order.
    final unseen = groups.where((g) => g.isUnseen).toList();
    final seen = groups.where((g) => !g.isUnseen).toList();
    return [...unseen, ...seen];
  }

  /// Marks a story group as viewed for the current user.
  Future<void> markStoryGroupViewed(String storyGroupId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('story_views').upsert({
      'user_id': userId,
      'story_group_id': storyGroupId,
    });
  }
}

