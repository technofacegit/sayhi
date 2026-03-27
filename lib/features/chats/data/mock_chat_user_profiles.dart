import 'package:qr_dating_app/features/chats/presentation/model/chat_user_profile.dart';

class MockChatUserProfiles {
  MockChatUserProfiles._();

  static final Map<String, ChatUserProfile> _byId = {
    'elena': ChatUserProfile(
      chatId: 'elena',
      name: 'Elena',
      photoUrls: [
        'https://picsum.photos/seed/elena_p1/600/750',
        'https://picsum.photos/seed/elena_p2/600/750',
        'https://picsum.photos/seed/elena_p3/600/750',
        'https://picsum.photos/seed/elena_p4/600/750',
      ],
      description:
          'Product designer who loves rooftop sunsets and indie concerts. '
          'Always up for a good espresso and honest conversation. '
          'Looking for someone curious and kind.',
    ),
    'marcus': ChatUserProfile(
      chatId: 'marcus',
      name: 'Marcus',
      photoUrls: [
        'https://picsum.photos/seed/marcus_p1/600/750',
        'https://picsum.photos/seed/marcus_p2/600/750',
        'https://picsum.photos/seed/marcus_p3/600/750',
        'https://picsum.photos/seed/marcus_p4/600/750',
      ],
      description:
          'Weekend hiker, weekday engineer. Big on football, cooking, and bad puns. '
          'Say hi if you want to swap playlist recommendations.',
    ),
    'sofia': ChatUserProfile(
      chatId: 'sofia',
      name: 'Sofia',
      photoUrls: [
        'https://picsum.photos/seed/sofia_p1/600/750',
        'https://picsum.photos/seed/sofia_p2/600/750',
        'https://picsum.photos/seed/sofia_p3/600/750',
        'https://picsum.photos/seed/sofia_p4/600/750',
      ],
      description:
          'Art history grad, café hopper, sometimes painter. '
          'I value humor, empathy, and people who read more than their algorithm suggests.',
    ),
    'james': ChatUserProfile(
      chatId: 'james',
      name: 'James',
      photoUrls: [
        'https://picsum.photos/seed/james_p1/600/750',
        'https://picsum.photos/seed/james_p2/600/750',
        'https://picsum.photos/seed/james_p3/600/750',
        'https://picsum.photos/seed/james_p4/600/750',
      ],
      description:
          'Runner, podcast addict, dog person. '
          'Looking for real chemistry and low-drama plans.',
    ),
    'nina': ChatUserProfile(
      chatId: 'nina',
      name: 'Nina',
      photoUrls: [
        'https://picsum.photos/seed/nina_p1/600/750',
        'https://picsum.photos/seed/nina_p2/600/750',
        'https://picsum.photos/seed/nina_p3/600/750',
        'https://picsum.photos/seed/nina_p4/600/750',
      ],
      description:
          'Yoga in the morning, vinyl in the evening. '
          'I believe the best dates are half planned, half spontaneous.',
    ),
    'alex': ChatUserProfile(
      chatId: 'alex',
      name: 'Alex',
      photoUrls: [
        'https://picsum.photos/seed/alex_p1/600/750',
        'https://picsum.photos/seed/alex_p2/600/750',
        'https://picsum.photos/seed/alex_p3/600/750',
        'https://picsum.photos/seed/alex_p4/600/750',
      ],
      description:
          'Travel photographer, homebody on rainy days. '
          'Fluent in memes and long walks. Let’s skip small talk when it feels right.',
    ),
  };

  static ChatUserProfile? byChatId(String chatId) => _byId[chatId];
}
