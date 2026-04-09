import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class MyProfileData {
  const MyProfileData({
    required this.userId,
    required this.name,
    required this.bio,
    this.age,
    required this.location,
    required this.avatarUrl,
    required this.galleryUrls,
    required this.interests,
    required this.perfectDatePrompt,
  });

  final String userId;
  final String name;
  final String bio;
  final int? age;
  final String location;
  final String avatarUrl;
  final List<String> galleryUrls;
  final List<String> interests;
  final String perfectDatePrompt;

  List<String> get photoUrls {
    final out = <String>[];
    if (avatarUrl.trim().isNotEmpty) out.add(avatarUrl.trim());
    for (final p in galleryUrls) {
      final t = p.trim();
      if (t.isNotEmpty && !out.contains(t)) out.add(t);
    }
    return out.take(5).toList(growable: false);
  }

  /// Updates only [location] (DB `country`) for UI after a GPS sync without touching other fields.
  MyProfileData copyWithLocation(String location) {
    return MyProfileData(
      userId: userId,
      name: name,
      bio: bio,
      age: age,
      location: location,
      avatarUrl: avatarUrl,
      galleryUrls: galleryUrls,
      interests: interests,
      perfectDatePrompt: perfectDatePrompt,
    );
  }
}

class MyProfileRepository {
  MyProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const _profileMediaBucket = 'chat-media';

  String? get _uid => _client.auth.currentUser?.id;

  Future<MyProfileData> fetchMyProfile() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final row = await _client
        .from('profiles')
        .select(
          'id, name, bio, age, country, avatar_url, gallery_urls, interests, prompt_perfect_date',
        )
        .eq('id', uid)
        .maybeSingle();
    if (row == null || row is! Map) {
      throw Exception('Profile not found');
    }
    final m = Map<String, dynamic>.from(row);
    final gallery = <String>[];
    final rawGallery = m['gallery_urls'];
    if (rawGallery is List) {
      for (final e in rawGallery) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) gallery.add(s);
      }
    }
    final interests = <String>[];
    final rawInterests = m['interests'];
    if (rawInterests is List) {
      for (final e in rawInterests) {
        final s = e?.toString().trim() ?? '';
        if (s.isNotEmpty) interests.add(s);
      }
    }
    return MyProfileData(
      userId: uid,
      name: (m['name'] as String? ?? '').trim(),
      bio: (m['bio'] as String? ?? '').trim(),
      age: (m['age'] as num?)?.toInt(),
      location: (m['country'] as String? ?? '').trim(),
      avatarUrl: (m['avatar_url'] as String? ?? '').trim(),
      galleryUrls: gallery,
      interests: interests,
      perfectDatePrompt: (m['prompt_perfect_date'] as String? ?? '').trim(),
    );
  }

  Future<String> fetchMyCountry() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final row = await _client
        .from('profiles')
        .select('country')
        .eq('id', uid)
        .maybeSingle();
    if (row == null || row is! Map) {
      throw Exception('Profile not found');
    }
    return (Map<String, dynamic>.from(row)['country'] as String? ?? '').trim();
  }

  Future<void> updateMyProfile({
    required String name,
    required String bio,
    required int? age,
    required List<String> interests,
    required String perfectDatePrompt,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    await _client.from('profiles').update({
      'name': name.trim(),
      'bio': bio.trim(),
      'age': age,
      'interests': interests.isEmpty ? null : interests,
      'prompt_perfect_date':
          perfectDatePrompt.trim().isEmpty ? null : perfectDatePrompt.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  Future<String> uploadProfilePhoto({
    required String filePath,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Photo file not found');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) throw Exception('Photo file is empty');
    final ts = DateTime.now().millisecondsSinceEpoch;
    final primaryPath = '$uid/profile_photos/$ts.jpg';
    try {
      await _client.storage.from(_profileMediaBucket).uploadBinary(
        primaryPath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      return _client.storage.from(_profileMediaBucket).getPublicUrl(primaryPath);
    } catch (_) {
      // Fallback to the folder already used by chat image uploads.
      final fallbackPath = '$uid/chat_images/profile_$ts.jpg';
      await _client.storage.from(_profileMediaBucket).uploadBinary(
        fallbackPath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      return _client.storage.from(_profileMediaBucket).getPublicUrl(fallbackPath);
    }
  }

  Future<void> updateMyPhotoUrls(List<String> photoUrls) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');
    final cleaned = photoUrls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    final avatar = cleaned.isEmpty ? null : cleaned.first;
    final gallery = cleaned.length <= 1 ? <String>[] : cleaned.sublist(1);
    await _client.from('profiles').update({
      'avatar_url': avatar,
      'gallery_urls': gallery,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }
}
