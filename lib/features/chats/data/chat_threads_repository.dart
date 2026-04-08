import 'dart:convert';

import 'package:qr_dating_app/features/chats/presentation/model/chat_thread.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads chat thread list for Chats tab.
class ChatThreadsRepository {
  ChatThreadsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ChatThread>> fetchThreads({int limit = 50}) async {
    final raw = await _client.rpc<dynamic>(
      'get_chat_threads',
      params: {'p_limit': limit},
    );
    final list = _decodeJsonArray(raw);
    return list.map<ChatThread>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final id = (m['chat_id']?.toString() ?? '').trim();
      final name = (m['name'] as String? ?? '').trim();
      final avatar = (m['avatar_url'] as String? ?? '').trim();
      final lastMessage = (m['last_message'] as String? ?? '').trim();
      final tsRaw = m['last_message_at']?.toString();
      final ts = tsRaw == null
          ? DateTime.now()
          : (DateTime.tryParse(tsRaw)?.toLocal() ?? DateTime.now());
      final unread = (m['unread_count'] as num?)?.toInt() ?? 0;
      final onlineRaw = m['last_online_at']?.toString();
      final lastOnline = onlineRaw == null
          ? null
          : DateTime.tryParse(onlineRaw)?.toLocal();
      final lastMessageIsMine = m['last_message_is_mine'] == true;
      final readAtRaw = m['last_message_read_at']?.toString();
      final readAt = readAtRaw == null
          ? null
          : DateTime.tryParse(readAtRaw)?.toLocal();
      return ChatThread(
        id: id,
        name: name.isEmpty ? 'Member' : name,
        avatarUrl: avatar,
        lastMessage: lastMessage,
        lastMessageAt: ts,
        unreadCount: unread < 0 ? 0 : unread,
        lastOnlineAt: lastOnline,
        lastMessageIsMine: lastMessageIsMine,
        lastMessageReadAt: readAt,
      );
    }).where((t) => t.id.isNotEmpty).toList(growable: false);
  }

  Future<List<ChatThread>> fetchNewMatches({int limit = 30}) async {
    final raw = await _client.rpc<dynamic>(
      'get_new_matches',
      params: {'p_limit': limit},
    );
    final list = _decodeJsonArray(raw);
    return list.map<ChatThread>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final id = (m['chat_id']?.toString() ?? '').trim();
      final name = (m['name'] as String? ?? '').trim();
      final avatar = (m['avatar_url'] as String? ?? '').trim();
      final tsRaw = m['last_message_at']?.toString();
      final ts = tsRaw == null
          ? DateTime.now()
          : (DateTime.tryParse(tsRaw)?.toLocal() ?? DateTime.now());
      return ChatThread(
        id: id,
        name: name.isEmpty ? 'Member' : name,
        avatarUrl: avatar,
        lastMessage: '',
        lastMessageAt: ts,
        unreadCount: 0,
        lastOnlineAt: null,
        lastMessageIsMine: false,
        lastMessageReadAt: null,
      );
    }).where((t) => t.id.isNotEmpty).toList(growable: false);
  }

  static List<dynamic> _decodeJsonArray(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw;
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
      return const [];
    }
    return const [];
  }
}
