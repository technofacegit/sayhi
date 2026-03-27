import 'package:qr_dating_app/features/chats/presentation/model/chat_thread.dart';

class MockChatThreads {
  MockChatThreads._();

  static final List<ChatThread> all = [
    ChatThread(
      id: 'elena',
      name: 'Elena',
      avatarUrl: 'https://picsum.photos/seed/elena/200/200',
      lastMessage: 'See you at the rooftop tonight ✨',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 2,
    ),
    ChatThread(
      id: 'marcus',
      name: 'Marcus',
      avatarUrl: 'https://picsum.photos/seed/marcus/200/200',
      lastMessage: 'Haha that was a good one',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 4)),
      unreadCount: 0,
    ),
    ChatThread(
      id: 'sofia',
      name: 'Sofia',
      avatarUrl: 'https://picsum.photos/seed/sofia/200/200',
      lastMessage: 'Are you still at the café?',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 1,
    ),
    ChatThread(
      id: 'james',
      name: 'James',
      avatarUrl: 'https://picsum.photos/seed/james/200/200',
      lastMessage: 'Sent you a voice note — check when you can',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      unreadCount: 0,
    ),
    ChatThread(
      id: 'nina',
      name: 'Nina',
      avatarUrl: 'https://picsum.photos/seed/nina/200/200',
      lastMessage: 'Thanks for the intro yesterday!',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 0,
    ),
    ChatThread(
      id: 'alex',
      name: 'Alex',
      avatarUrl: 'https://picsum.photos/seed/alex/200/200',
      lastMessage: 'Maybe next weekend works better for me',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 4)),
      unreadCount: 0,
    ),
  ];

  static ChatThread? byId(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
