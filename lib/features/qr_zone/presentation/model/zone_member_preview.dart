/// Zone grid row (people in venue); [age] may be null if not set on profile.
class ZoneMemberPreview {
  const ZoneMemberPreview({
    required this.id,
    required this.photoUrl,
    required this.name,
    this.age,
    required this.bio,
  });

  final String id;
  final String photoUrl;
  final String name;
  final int? age;
  final String bio;
}
