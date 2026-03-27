class ChatThread {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatThread({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });
}
