import 'package:qr_dating_app/features/home/presentation/model/story_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads story groups + slides from Supabase.
///
/// Schema expected (see migrations):
/// - story_groups(id, label, ring_image_url, expires_at, created_at)
/// - story_slides(id, story_group_id, slide_index, image_url)
class StoryRepository {
  StoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<StoryGroup>> fetchStoryGroups() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final rows = await _client
        .from('story_groups')
        .select(
          'id, label, ring_image_url, story_slides ( slide_index, image_url )',
        )
        .gt('expires_at', nowIso)
        .order('created_at', ascending: false)
        .order('slide_index', referencedTable: 'story_slides', ascending: true);

    final list = rows as List;

    return list.map<StoryGroup>((raw) {
      final map = raw as Map<String, dynamic>;
      final label = (map['label'] ?? '') as String;
      final ringImageUrl = (map['ring_image_url'] ?? '') as String;
      final slidesRaw = (map['story_slides'] as List?) ?? const [];

      final slideUrls = slidesRaw
          .whereType<Map<String, dynamic>>()
          .map((s) => (s['image_url'] ?? '') as String)
          .where((u) => u.isNotEmpty)
          .toList(growable: false);

      if (slideUrls.isEmpty) {
        return StoryGroup(
          label: label.isNotEmpty ? label : 'Story',
          ringImageUrl: ringImageUrl,
          slideImageUrls: ringImageUrl.isNotEmpty ? [ringImageUrl] : const [],
        );
      }

      return StoryGroup(
        label: label.isNotEmpty ? label : 'Story',
        ringImageUrl: ringImageUrl.isNotEmpty ? ringImageUrl : slideUrls.first,
        slideImageUrls: slideUrls,
      );
    }).where((g) => g.slideImageUrls.isNotEmpty).toList(growable: false);
  }
}

