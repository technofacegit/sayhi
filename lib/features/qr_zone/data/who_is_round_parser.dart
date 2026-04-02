import 'dart:convert';

import 'package:qr_dating_app/features/qr_zone/presentation/model/who_is_game_round.dart';

/// Parses JSON from Supabase RPC [get_who_is_game_round_v5].
///
/// Backend typically draws from:
/// - [synthetic_profiles] — decoy / option rows
/// - [who_is_questions] — prompt text
/// - [who_is_game_history] — round / attempt row (optional ids in the payload)
///
/// Keys are matched flexibly so small RPC JSON differences still work.
WhoIsGameRound parseWhoIsGameRoundResponse(dynamic raw) {
  final m = _normalizeRpcPayload(raw);
  if (m == null) {
    throw FormatException(
      'Who Is round: empty or unexpected response (${raw?.runtimeType})',
    );
  }

  final question = _extractQuestion(m);
  final correctIndex = _extractCorrectIndex(m);
  var profiles = _extractProfiles(m);

  if (profiles.length > 3) {
    profiles = profiles.sublist(0, 3);
  }
  if (profiles.length < 3) {
    throw FormatException(
      'Who Is round: need 3 profiles, got ${profiles.length}. Keys tried: '
      '${m.keys.take(12).join(", ")}',
    );
  }

  final historyRaw = _firstString(m, const [
    'history_id',
    'game_history_id',
    'who_is_game_history_id',
  ]);
  final historyId = historyRaw.isEmpty ? null : historyRaw;

  var roundId = _firstString(m, const [
    'round_id',
    'round_uuid',
    'game_round_id',
  ]);
  if (roundId.isEmpty && historyId != null) {
    roundId = historyId;
  }

  return WhoIsGameRound(
    roundId: roundId,
    historyId: historyId,
    question: question,
    correctIndex: correctIndex.clamp(0, 2),
    profiles: profiles,
  );
}

/// Unwraps common PostgREST / RPC shapes: json string, single-row array, {data: ...}.
Map<String, dynamic>? _normalizeRpcPayload(dynamic raw) {
  dynamic x = raw;
  if (x == null) return null;

  if (x is String) {
    final t = x.trim();
    if (t.isEmpty) return null;
    try {
      x = jsonDecode(t);
    } catch (_) {
      return null;
    }
  }

  if (x is List) {
    if (x.isEmpty) return null;
    x = x.first;
  }

  if (x is! Map) return null;

  var m = _stringKeyMap(x);

  for (final key in const [
    'data',
    'result',
    'round',
    'payload',
    'game',
    'get_who_is_game_round_v5',
  ]) {
    final inner = m[key];
    if (inner is Map) {
      m = _stringKeyMap(inner);
      break;
    }
  }

  return m;
}

Map<String, dynamic> _stringKeyMap(Map<dynamic, dynamic> m) {
  return m.map((k, v) => MapEntry(k.toString(), v));
}

String _extractQuestion(Map<String, dynamic> m) {
  final direct = m['question'];
  if (direct is String && direct.trim().isNotEmpty) {
    return direct.trim();
  }
  if (direct is Map) {
    final inner = _firstString(_stringKeyMap(direct), const [
      'text',
      'prompt',
      'question_text',
      'body',
      'title',
    ]);
    if (inner.isNotEmpty) return inner;
  }

  final flat = _firstString(m, const [
    'question_text',
    'prompt',
    'clue',
    'body',
  ]);
  if (flat.isNotEmpty) return flat;

  final wq = m['who_is_questions'];
  if (wq is Map<String, dynamic>) {
    final nested = _firstString(wq, const [
      'text',
      'prompt',
      'question',
      'question_text',
      'body',
    ]);
    if (nested.isNotEmpty) return nested;
  }
  if (wq is Map) {
    final nested = _firstString(_stringKeyMap(wq), const [
      'text',
      'prompt',
      'question',
      'question_text',
      'body',
    ]);
    if (nested.isNotEmpty) return nested;
  }
  if (wq is List && wq.isNotEmpty) {
    final first = wq.first;
    if (first is Map) {
      final nested = _firstString(_stringKeyMap(first), const [
        'text',
        'prompt',
        'question',
        'question_text',
        'body',
        'content',
      ]);
      if (nested.isNotEmpty) return nested;
    }
  }

  return '';
}

int _extractCorrectIndex(Map<String, dynamic> m) {
  final v = m['correct_index'] ??
      m['correct_option_index'] ??
      m['answer_index'] ??
      m['correct_answer_index'] ??
      m['correct_idx'];
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

List<WhoIsSyntheticProfile> _extractProfiles(Map<String, dynamic> m) {
  final rawList = m['profiles'] ??
      m['options'] ??
      m['choices'] ??
      m['synthetic_profiles'] ??
      m['profile_options'] ??
      m['decoys'] ??
      m['candidates'] ??
      m['answers'] ??
      m['profile_list'];

  if (rawList is! List) {
    return const [];
  }

  final out = <WhoIsSyntheticProfile>[];
  for (final e in rawList) {
    if (e is! Map) continue;
    final row = _stringKeyMap(e);
    out.add(_parseProfileRow(row));
  }
  return out;
}

WhoIsSyntheticProfile _parseProfileRow(Map<String, dynamic> e) {
  final id = _firstString(e, const [
    'id',
    'synthetic_profile_id',
    'profile_id',
  ]);
  final name = _firstString(e, const [
    'display_name',
    'name',
    'full_name',
    'username',
  ]);
  final avatar = _firstString(e, const [
    'avatar_url',
    'photo_url',
    'image_url',
    'picture_url',
  ]);
  final bio = _firstString(e, const [
    'bio',
    'description',
    'about',
    'tagline',
  ]);

  return WhoIsSyntheticProfile(
    id: id,
    displayName: name,
    avatarUrl: avatar,
    bio: bio,
  );
}

String _firstString(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return '';
}
