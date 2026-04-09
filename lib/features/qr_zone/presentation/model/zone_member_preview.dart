/// Zone grid row (people in venue); [age] may be null if not set on profile.
/// [gender] is optional (`female`, `male`, `other` from Supabase); used for card border tint.
class ZoneMemberPreview {
  const ZoneMemberPreview({
    required this.id,
    required this.photoUrl,
    required this.name,
    this.age,
    required this.bio,
    this.gender,
    this.country,
  });

  final String id;
  final String photoUrl;
  final String name;
  final int? age;
  final String bio;
  final String? gender;
  final String? country;
}
