import 'package:qr_dating_app/features/chats/presentation/model/chat_message.dart';
import 'package:qr_dating_app/l10n/app_localizations.dart';

class MockChatMessages {
  MockChatMessages._();

  static Map<String, List<ChatMessage>> _map(AppLocalizations l10n) => {
        'elena': [
          ChatMessage(
            id: '1',
            text: l10n.mockMsgElena1,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
          ),
          ChatMessage(
            id: '2',
            text: l10n.mockMsgElena2,
            isMe: true,
            sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 50)),
          ),
          ChatMessage(
            id: '3',
            text: l10n.mockMsgElena3,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 40)),
          ),
          ChatMessage(
            id: '4',
            text: l10n.mockMsgElena4,
            isMe: true,
            sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 4, minutes: 30)),
          ),
          ChatMessage(
            id: '5',
            text: l10n.mockMsgElena5,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
          ),
        ],
        'marcus': [
          ChatMessage(
            id: 'm1',
            text: l10n.mockMsgMarcus1,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          ChatMessage(
            id: 'm2',
            text: l10n.mockMsgMarcus2,
            isMe: true,
            sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
          ),
          ChatMessage(
            id: 'm3',
            text: l10n.mockMsgMarcus3,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 4)),
          ),
        ],
        'sofia': [
          ChatMessage(
            id: 's1',
            text: l10n.mockMsgSofia1,
            isMe: true,
            sentAt: DateTime.now().subtract(const Duration(hours: 4)),
          ),
          ChatMessage(
            id: 's2',
            text: l10n.mockMsgSofia2,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
        'james': [
          ChatMessage(
            id: 'j1',
            text: l10n.mockMsgJames1,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          ),
        ],
        'nina': [
          ChatMessage(
            id: 'n1',
            text: l10n.mockMsgNina1,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          ChatMessage(
            id: 'n2',
            text: l10n.mockMsgNina2,
            isMe: true,
            sentAt: DateTime.now().subtract(
              const Duration(days: 2) - const Duration(minutes: 5),
            ),
          ),
        ],
        'alex': [
          ChatMessage(
            id: 'a1',
            text: l10n.mockMsgAlex1,
            isMe: true,
            sentAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          ChatMessage(
            id: 'a2',
            text: l10n.mockMsgAlex2,
            isMe: false,
            sentAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
        ],
      };

  static List<ChatMessage> forChat(AppLocalizations l10n, String chatId) {
    return List<ChatMessage>.from(_map(l10n)[chatId] ?? const []);
  }
}
