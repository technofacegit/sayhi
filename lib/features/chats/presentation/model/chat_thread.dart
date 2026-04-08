class ChatThread {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final DateTime? lastOnlineAt;
  final bool lastMessageIsMine;
  final DateTime? lastMessageReadAt;

  const ChatThread({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.lastOnlineAt,
    this.lastMessageIsMine = false,
    this.lastMessageReadAt,
  });
}
