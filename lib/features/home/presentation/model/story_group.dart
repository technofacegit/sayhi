/// A story ring on Home can represent one or more full-screen slides (sub-stories).
class StoryGroup {
  /// Database id (story_groups.id) when backed by Supabase.
  final String? id;

  final String label;
  /// Shown in the home strip avatar.
  final String ringImageUrl;
  /// Ordered slides for this group (tap through like Instagram).
  final List<String> slideImageUrls;

  /// Optional per-slide titles (same length as [slideImageUrls] when present).
  final List<String> slideTitles;

  /// Optional per-slide body texts.
  final List<String> slideBodies;

  /// Whether current user has not viewed this group yet.
  final bool isUnseen;

  const StoryGroup({
    this.id,
    required this.label,
    required this.ringImageUrl,
    required this.slideImageUrls,
    this.slideTitles = const [],
    this.slideBodies = const [],
    this.isUnseen = true,
  });

  int get slideCount => slideImageUrls.length;
}
