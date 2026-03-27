/// A story ring on Home can represent one or more full-screen slides (sub-stories).
class StoryGroup {
  final String label;
  /// Shown in the home strip avatar.
  final String ringImageUrl;
  /// Ordered slides for this group (tap through like Instagram).
  final List<String> slideImageUrls;

  const StoryGroup({
    required this.label,
    required this.ringImageUrl,
    required this.slideImageUrls,
  });

  int get slideCount => slideImageUrls.length;
}
