import 'package:qr_dating_app/features/chats/presentation/model/chat_thread.dart';
import 'package:qr_dating_app/l10n/app_localizations.dart';

class MockChatThreads {
  MockChatThreads._();

  static List<ChatThread> all(AppLocalizations l10n) => [
        ChatThread(
          id: 'elena',
          name: 'Elena',
          avatarUrl: 'https://picsum.photos/seed/elena/200/200',
          lastMessage: l10n.mockThreadElenaLast,
          lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
          unreadCount: 2,
        ),
        ChatThread(
          id: 'marcus',
          name: 'Marcus',
          avatarUrl: 'https://picsum.photos/seed/marcus/200/200',
          lastMessage: l10n.mockThreadMarcusLast,
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 4)),
          unreadCount: 0,
        ),
        ChatThread(
          id: 'sofia',
          name: 'Sofia',
          avatarUrl: 'https://picsum.photos/seed/sofia/200/200',
          lastMessage: l10n.mockThreadSofiaLast,
          lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
          unreadCount: 1,
        ),
        ChatThread(
          id: 'james',
          name: 'James',
          avatarUrl: 'https://picsum.photos/seed/james/200/200',
          lastMessage: l10n.mockThreadJamesLast,
          lastMessageAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          unreadCount: 0,
        ),
        ChatThread(
          id: 'nina',
          name: 'Nina',
          avatarUrl: 'https://picsum.photos/seed/nina/200/200',
          lastMessage: l10n.mockThreadNinaLast,
          lastMessageAt: DateTime.now().subtract(const Duration(days: 2)),
          unreadCount: 0,
        ),
        ChatThread(
          id: 'alex',
          name: 'Alex',
          avatarUrl: 'https://picsum.photos/seed/alex/200/200',
          lastMessage: l10n.mockThreadAlexLast,
          lastMessageAt: DateTime.now().subtract(const Duration(days: 4)),
          unreadCount: 0,
        ),
      ];

  static ChatThread? byId(AppLocalizations l10n, String id) {
    try {
      return all(l10n).firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
