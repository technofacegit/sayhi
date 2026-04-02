class AppRouter {
  static const onboardingPath = '/onboarding';
  static const loginPath = '/login';
  static const emailLoginPath = '/email-login';
  static const emailPasswordPath = '/email-login/password';
  static const emailRegisterPath = '/email-login/register';
  static const emailForgotPasswordPath = '/email-login/forgot-password';
  static const resetPasswordPath = '/reset-password';
  static const homePath = '/home';
  static const zonesPath = '/zones';
  static const chatsPath = '/chats';
  static const profilePath = '/profile';

  /// Nested under [chatsPath].
  static String chatConversationPath(String chatId) =>
      '$chatsPath/conversation/$chatId';

  /// Nested under [chatConversationPath] (opens from chat header).
  static String chatUserProfilePath(String chatId) =>
      '${chatConversationPath(chatId)}/profile';

  /// Nested under [homePath]; opens inside the tab shell (bottom bar + FAB).
  static const qrJoinPath = '/home/join-zone';
  static const activeZonePath = '/active-zone';
  static const zoneMainPath = '/zone-main';
  static const zoneWarmUpPath = '/zone-warm-up';
  static const zoneWhoIsPath = '/zone-who-is';
  static const zoneLobbyPath = '/zone-lobby';
}
