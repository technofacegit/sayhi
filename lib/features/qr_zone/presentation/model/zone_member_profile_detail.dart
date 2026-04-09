/// Full lobby profile payload from [ZoneRepository.fetchZoneMemberProfileDetail].
class ZoneMemberProfileDetail {
  const ZoneMemberProfileDetail({
    required this.userId,
    required this.name,
    required this.bio,
    this.age,
    this.gender,
    this.country,
    required this.avatarUrl,
    required this.galleryUrls,
    this.swipe,
    required this.isFavorite,
  });

  final String userId;
  final String name;
  final String bio;
  final int? age;
  final String? gender;
  final String? country;
  final String avatarUrl;
  final List<String> galleryUrls;

  /// `like`, `dislike`, or null if cleared / never set.
  final String? swipe;
  final bool isFavorite;

  /// Avatar first, then extra gallery URLs (deduped).
  List<String> get allPhotoUrls {
    final out = <String>[];
    if (avatarUrl.isNotEmpty) out.add(avatarUrl);
    for (final u in galleryUrls) {
      if (u.isNotEmpty && !out.contains(u)) out.add(u);
    }
    return out;
  }
}
