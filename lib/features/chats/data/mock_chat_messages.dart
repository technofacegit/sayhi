import 'package:qr_dating_app/features/chats/presentation/model/chat_message.dart';

class MockChatMessages {
  MockChatMessages._();

  static final Map<String, List<ChatMessage>> _byChatId = {
    'elena': [
      ChatMessage(
        id: '1',
        text: 'Hey! Loved your profile.',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      ),
      ChatMessage(
        id: '2',
        text: 'Thanks! Yours too — especially the travel pics.',
        isMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 50)),
      ),
      ChatMessage(
        id: '3',
        text: 'Are you free this week?',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 40)),
      ),
      ChatMessage(
        id: '4',
        text: 'Thursday or Friday evening works for me.',
        isMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 30)),
      ),
      ChatMessage(
        id: '5',
        text: 'See you at the rooftop tonight ✨',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    ],
    'marcus': [
      ChatMessage(
        id: 'm1',
        text: 'Did you see the match?',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        id: 'm2',
        text: 'Only the highlights — insane finish',
        isMe: true,
        sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      ),
      ChatMessage(
        id: 'm3',
        text: 'Haha that was a good one',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 4)),
      ),
    ],
    'sofia': [
      ChatMessage(
        id: 's1',
        text: 'Still at the market near the bridge?',
        isMe: true,
        sentAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      ChatMessage(
        id: 's2',
        text: 'Are you still at the café?',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
    'james': [
      ChatMessage(
        id: 'j1',
        text: 'Sent you a voice note — check when you can',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
    ],
    'nina': [
      ChatMessage(
        id: 'n1',
        text: 'Thanks for the intro yesterday!',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ChatMessage(
        id: 'n2',
        text: 'Anytime — glad you two hit it off',
        isMe: true,
        sentAt: DateTime.now().subtract(
          const Duration(days: 2) - const Duration(minutes: 5),
        ),
      ),
    ],
    'alex': [
      ChatMessage(
        id: 'a1',
        text: 'Rain check on Sunday?',
        isMe: true,
        sentAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      ChatMessage(
        id: 'a2',
        text: 'Maybe next weekend works better for me',
        isMe: false,
        sentAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
    ],
  };

  static List<ChatMessage> forChat(String chatId) {
    return List<ChatMessage>.from(_byChatId[chatId] ?? const []);
  }
}
