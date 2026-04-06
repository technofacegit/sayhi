/// Profile row for the home discovery swipe deck (from [get_discovery_profiles]).
class SwipeProfile {
  const SwipeProfile({
    required this.id,
    required this.photoUrl,
    required this.name,
    this.age,
    required this.bio,
    this.gender,
    this.galleryUrls = const [],
  });

  final String id;
  final String photoUrl;
  final String name;
  final int? age;
  final String bio;
  final String? gender;
  final List<String> galleryUrls;

  /// Primary photo first, then extras (deduped).
  List<String> get imageUrls {
    final u = <String>[];
    if (photoUrl.isNotEmpty) u.add(photoUrl);
    for (final g in galleryUrls) {
      if (g.isNotEmpty && !u.contains(g)) u.add(g);
    }
    if (u.isEmpty) u.add('');
    return u;
  }
}
