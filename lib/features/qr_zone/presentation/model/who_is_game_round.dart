/// One round from [get_who_is_game_round_v5]: a clue question and three synthetic profiles.
///
/// Data is usually composed from [who_is_questions], [synthetic_profiles], and
/// [who_is_game_history] on the server; [historyId] is set when the RPC returns it.
class WhoIsGameRound {
  const WhoIsGameRound({
    required this.roundId,
    this.historyId,
    required this.question,
    required this.correctIndex,
    required this.profiles,
  });

  final String roundId;

  /// Optional [who_is_game_history] row id from the RPC (for future submit/telemetry).
  final String? historyId;
  final String question;

  /// Index 0..2 into [profiles].
  final int correctIndex;
  final List<WhoIsSyntheticProfile> profiles;
}

class WhoIsSyntheticProfile {
  const WhoIsSyntheticProfile({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
  });

  final String id;
  final String displayName;
  final String avatarUrl;
  final String bio;
}
