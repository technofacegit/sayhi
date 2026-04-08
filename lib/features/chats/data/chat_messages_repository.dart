import 'dart:convert';

import 'package:qr_dating_app/features/chats/presentation/model/chat_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Partner header for chat UI (mutual match required).
class ChatPartnerPreview {
  const ChatPartnerPreview({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.galleryUrls,
    required this.lastOnlineAt,
  });

  final String userId;
  final String name;
  final String avatarUrl;
  final String bio;
  final List<String> galleryUrls;
  final DateTime? lastOnlineAt;
}

/// Loads and sends 1:1 messages ([chatId] in routes = other user's id).
class ChatMessagesRepository {
  ChatMessagesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _myId => _client.auth.currentUser?.id;

  Future<ChatPartnerPreview?> fetchPartnerPreview(String otherUserId) async {
    try {
      final raw = await _client.rpc<dynamic>(
        'get_chat_partner_preview',
        params: {'p_other_user_id': otherUserId},
      );
      if (raw == null) return null;
      final m = _asMap(raw);
      final gallery = m['gallery_urls'];
      final urls = <String>[];
      if (gallery is List) {
        for (final e in gallery) {
          final s = e?.toString().trim() ?? '';
          if (s.isNotEmpty) urls.add(s);
        }
      }
      return ChatPartnerPreview(
        userId: (m['user_id'] ?? m['userId'])?.toString() ?? '',
        name: (m['name'] as String? ?? '').trim().isEmpty
            ? 'Member'
            : (m['name'] as String).trim(),
        avatarUrl: (m['avatar_url'] as String? ?? '').trim(),
        bio: (m['bio'] as String? ?? '').trim(),
        galleryUrls: urls,
        lastOnlineAt: DateTime.tryParse(
          (m['last_online_at']?.toString() ?? '').trim(),
        )?.toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<ChatMessage>> fetchMessages(String otherUserId) async {
    final myId = _myId;
    if (myId == null) return const [];

    final raw = await _client.rpc<dynamic>(
      'get_chat_messages',
      params: {
        'p_other_user_id': otherUserId,
        'p_limit': 200,
      },
    );
    final list = _decodeJsonArray(raw);
    return list.map((e) => _parseMessage(Map<String, dynamic>.from(e as Map), myId)).toList();
  }

  Future<void> markChatRead(String otherUserId) async {
    await _client.rpc<dynamic>(
      'mark_chat_read',
      params: {'p_other_user_id': otherUserId},
    );
  }

  Future<void> touchMyPresence() async {
    await _client.rpc<dynamic>('touch_my_presence');
  }

  Future<ChatMessage?> sendMessage(String recipientId, String body) async {
    final myId = _myId;
    if (myId == null) return null;

    final raw = await _client.rpc<dynamic>(
      'send_chat_message',
      params: {
        'p_recipient_id': recipientId,
        'p_body': body,
      },
    );
    final m = _asMap(raw);
    return _parseMessage(m, myId);
  }

  ChatMessage _parseMessage(Map<String, dynamic> m, String myId) {
    final id = m['id']?.toString() ?? '';
    final text = (m['body'] as String? ?? '').trim();
    final senderId = m['sender_id']?.toString() ?? '';
    final tsRaw = m['created_at']?.toString();
    final sentAt = tsRaw == null
        ? DateTime.now()
        : (DateTime.tryParse(tsRaw)?.toLocal() ?? DateTime.now());
    return ChatMessage(
      id: id.isEmpty ? 'local' : id,
      text: text,
      isMe: senderId == myId,
      sentAt: sentAt,
    );
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return {};
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
