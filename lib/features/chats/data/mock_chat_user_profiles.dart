import 'package:qr_dating_app/features/chats/presentation/model/chat_user_profile.dart';
import 'package:qr_dating_app/l10n/app_localizations.dart';

class MockChatUserProfiles {
  MockChatUserProfiles._();

  static ChatUserProfile? byChatId(AppLocalizations l10n, String chatId) {
    switch (chatId) {
      case 'elena':
        return ChatUserProfile(
          chatId: 'elena',
          name: 'Elena',
          photoUrls: const [
            'https://picsum.photos/seed/elena_p1/600/750',
            'https://picsum.photos/seed/elena_p2/600/750',
            'https://picsum.photos/seed/elena_p3/600/750',
            'https://picsum.photos/seed/elena_p4/600/750',
          ],
          description: l10n.mockBioElena,
        );
      case 'marcus':
        return ChatUserProfile(
          chatId: 'marcus',
          name: 'Marcus',
          photoUrls: const [
            'https://picsum.photos/seed/marcus_p1/600/750',
            'https://picsum.photos/seed/marcus_p2/600/750',
            'https://picsum.photos/seed/marcus_p3/600/750',
            'https://picsum.photos/seed/marcus_p4/600/750',
          ],
          description: l10n.mockBioMarcus,
        );
      case 'sofia':
        return ChatUserProfile(
          chatId: 'sofia',
          name: 'Sofia',
          photoUrls: const [
            'https://picsum.photos/seed/sofia_p1/600/750',
            'https://picsum.photos/seed/sofia_p2/600/750',
            'https://picsum.photos/seed/sofia_p3/600/750',
            'https://picsum.photos/seed/sofia_p4/600/750',
          ],
          description: l10n.mockBioSofia,
        );
      case 'james':
        return ChatUserProfile(
          chatId: 'james',
          name: 'James',
          photoUrls: const [
            'https://picsum.photos/seed/james_p1/600/750',
            'https://picsum.photos/seed/james_p2/600/750',
            'https://picsum.photos/seed/james_p3/600/750',
            'https://picsum.photos/seed/james_p4/600/750',
          ],
          description: l10n.mockBioJames,
        );
      case 'nina':
        return ChatUserProfile(
          chatId: 'nina',
          name: 'Nina',
          photoUrls: const [
            'https://picsum.photos/seed/nina_p1/600/750',
            'https://picsum.photos/seed/nina_p2/600/750',
            'https://picsum.photos/seed/nina_p3/600/750',
            'https://picsum.photos/seed/nina_p4/600/750',
          ],
          description: l10n.mockBioNina,
        );
      case 'alex':
        return ChatUserProfile(
          chatId: 'alex',
          name: 'Alex',
          photoUrls: const [
            'https://picsum.photos/seed/alex_p1/600/750',
            'https://picsum.photos/seed/alex_p2/600/750',
            'https://picsum.photos/seed/alex_p3/600/750',
            'https://picsum.photos/seed/alex_p4/600/750',
          ],
          description: l10n.mockBioAlex,
        );
      default:
        return null;
    }
  }
}
