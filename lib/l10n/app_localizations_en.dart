// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Say Hi';

  @override
  String get navHome => 'Home';

  @override
  String get navZones => 'Zones';

  @override
  String get navSayHi => 'Say Hi';

  @override
  String get navChats => 'Chats';

  @override
  String get navProfile => 'Profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonStart => 'Start';

  @override
  String get commonBack => 'Back';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonBlock => 'Block';

  @override
  String get commonReport => 'Report';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonOk => 'OK';

  @override
  String get homeTitle => 'Say Hi';

  @override
  String get zonePreviewActiveZone => 'Active zone';

  @override
  String get zonePreviewNoActiveZone => 'No active zone';

  @override
  String zonePreviewActiveNow(int count) {
    return '$count active now';
  }

  @override
  String get zonePreviewJoinHint => 'Join a zone to see who is here right now.';

  @override
  String get recentZonesTitle => 'Recent zones';

  @override
  String recentZoneActive(int count) {
    return '$count active';
  }

  @override
  String recentZoneRemaining(Object time) {
    return 'Remaining: $time';
  }

  @override
  String get recentZoneInactive => 'Inactive';

  @override
  String get defaultZoneName => 'Zone';

  @override
  String get defaultVenueName => 'Venue';

  @override
  String zoneRemainingPrefix(Object time) {
    return 'Remaining: $time';
  }

  @override
  String get zoneInactive => 'Inactive';

  @override
  String get zoneDurationZero => '0 h 0 m';

  @override
  String zoneDurationHm(int hours, int minutes) {
    return '$hours h $minutes m';
  }

  @override
  String get zoneMainLeaveZone => 'Leave zone';

  @override
  String zoneMainActiveNow(int count) {
    return '$count active now';
  }

  @override
  String get zoneMainLeaveError => 'Could not leave zone. Try again.';

  @override
  String get zoneMainMissingZoneId => 'Missing zone id.';

  @override
  String get zoneMainLoadError => 'Could not load people in this zone.';

  @override
  String get zoneMainFetchingProfiles => 'Loading profiles…';

  @override
  String get zoneMainEmptyAfterIcebreaker =>
      'No one else is here yet. Pull to refresh or check back soon.';

  @override
  String get zoneMainMemberBioPlaceholder => '—';

  @override
  String get zoneHubHeadline => 'Choose a mode';

  @override
  String get zoneModeWarmUp => 'Warm Up';

  @override
  String get zoneModeWarmUpSubtitle =>
      'Quick icebreaker questions before you mingle.';

  @override
  String get zoneModeWhoIs => 'Who is Game';

  @override
  String get zoneModeWhoIsSubtitle => 'Guess who — coming soon.';

  @override
  String get zoneModeLobby => 'Lobby';

  @override
  String get zoneModeLobbySubtitle => 'See who is here in this zone.';

  @override
  String get zoneLobbyTitle => 'Lobby';

  @override
  String get zoneWarmUpTitle => 'Warm Up';

  @override
  String get zoneWhoIsTitle => 'Who is Game';

  @override
  String get whoIsLoadError => 'Could not load this round. Try again.';

  @override
  String get whoIsCorrect => 'Correct!';

  @override
  String get whoIsWrongFeedback =>
      'Not quite — the right profile is highlighted.';

  @override
  String get whoIsNextRound => 'Next round';

  @override
  String get whoIsChooseHint => 'Tap the profile that fits the clue.';

  @override
  String get icebreakerSaveError => 'Could not save answer. Try again.';

  @override
  String get icebreakerEarlyTitle => 'You\'re early';

  @override
  String get icebreakerEarlySubtitle =>
      'Kick things off with a quick icebreaker.';

  @override
  String get icebreakerCardTitle => 'Icebreaker';

  @override
  String get icebreakerWarmedUp => 'You\'re warmed up!';

  @override
  String icebreakerDoneBody(int count) {
    return 'Nice work on all $count questions. When someone joins the zone, they\'ll show up here.';
  }

  @override
  String get icebreakerLoadError => 'Couldn\'t load icebreaker questions.';

  @override
  String get icebreakerRetry => 'Retry';

  @override
  String icebreakerProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingStart => 'Start';

  @override
  String get onboardingPage1Title => 'Scan into the moment';

  @override
  String get onboardingPage1Subtitle =>
      'Join a venue zone by scanning a QR code—only people here, right now.';

  @override
  String get onboardingPage2Title => 'Discover nearby';

  @override
  String get onboardingPage2Subtitle =>
      'Swipe through profiles in your zone and keep it effortlessly respectful.';

  @override
  String get onboardingPage3Title => 'Match & chat';

  @override
  String get onboardingPage3Subtitle =>
      'When it\'s mutual, start a conversation and meet—no endless scrolling.';

  @override
  String get loginWelcomeTitle => 'Welcome to Say Hi';

  @override
  String get loginWelcomeSubtitle => 'Meet people in the same place—right now.';

  @override
  String get loginContinueApple => 'Continue with Apple';

  @override
  String get loginContinueEmail => 'Continue with Email';

  @override
  String get loginContinueGuest => 'Continue as Guest';

  @override
  String loginGuestFailed(Object error) {
    return 'Guest login failed: $error';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLogout => 'Logout';

  @override
  String get logoutDialogTitle => 'Sign out';

  @override
  String get logoutDialogMessage => 'You are about to sign out. Continue?';

  @override
  String get logoutConfirm => 'Sign out';

  @override
  String get logoutCancel => 'Cancel';

  @override
  String get routerMissingZone => 'Missing zone';

  @override
  String get activeZoneAppBar => 'Active Zone';

  @override
  String get activeZoneHeadline => 'Active Zone';

  @override
  String activeZoneUserCount(int count) {
    return '$count active users';
  }

  @override
  String get activeZoneEnter => 'Enter Zone';

  @override
  String get activeZoneInvalidId => 'No valid ID for this zone.';

  @override
  String get activeZoneCancel => 'Cancel';

  @override
  String get qrJoinTitle => 'Join a Zone';

  @override
  String get qrJoinCameraHint => 'Point your camera at the venue QR code';

  @override
  String get qrJoinManualTitle => 'Enter code manually';

  @override
  String get qrJoinZoneCodeLabel => 'Zone Code';

  @override
  String get qrJoinZoneCodeHint => 'e.g. ROOFTOP';

  @override
  String get qrJoinBack => 'Back';

  @override
  String get qrJoinTorch => 'Torch';

  @override
  String get qrJoinVerifying => 'Verifying…';

  @override
  String get qrJoinEnterManually => 'Enter code manually';

  @override
  String get qrJoinInvalidCode => 'Invalid or wrong QR code.';

  @override
  String qrJoinFailed(Object error) {
    return 'Could not join zone: $error';
  }

  @override
  String get zonesGoToEntry => 'Go to zone entry';

  @override
  String get zonesSearchHint => 'Search venues';

  @override
  String get zonesClearTooltip => 'Clear';

  @override
  String get zonesStatus => 'Status';

  @override
  String get zonesFilterAll => 'All';

  @override
  String get zonesFilterActive => 'Active';

  @override
  String get zonesFilterInactive => 'Inactive';

  @override
  String get zonesMap => 'Map';

  @override
  String get zonesGrid => 'Grid';

  @override
  String get zonesNoResults => 'No results';

  @override
  String get zonesLocationOff => 'Location services are off.';

  @override
  String get zonesLocationPermission => 'Location permission required.';

  @override
  String zonesLocationError(Object error) {
    return 'Could not get location: $error';
  }

  @override
  String get zonesMapUnsupported => 'Platform map is not supported.';

  @override
  String get zonesRecenter => 'Center on my location';

  @override
  String get zonesYourLocation => 'Your location';

  @override
  String zonesCityActiveMembers(Object city, int count) {
    return '$city • $count active members';
  }

  @override
  String zonesActiveMembers(int count) {
    return '$count active members';
  }

  @override
  String zonesActiveCount(int count) {
    return '$count active';
  }

  @override
  String get storyLoading => 'Loading…';

  @override
  String get storyLoadError => 'Stories could not be loaded';

  @override
  String get storyEmpty => 'No stories yet';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordRequirementsLabel => 'Password requirements';

  @override
  String get authPasswordConfirm => 'Confirm password';

  @override
  String get authShowPassword => 'Show';

  @override
  String get authHidePassword => 'Hide';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailRequired => 'Email is required.';

  @override
  String get authEmailInvalid => 'Enter a valid email address.';

  @override
  String authProfileLookupFailed(Object error) {
    return 'Profile check failed (migration / RLS): $error';
  }

  @override
  String get authContinueWithEmailTitle => 'Continue with Email';

  @override
  String get authContinueWithEmailSubtitle =>
      'Use your email to sign in or create an account.';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubmit => 'Sign up';

  @override
  String get authRegisterConfirmEmail =>
      'Click the confirmation link in your email to finish.';

  @override
  String get authRegisterFailed => 'Could not create account.';

  @override
  String get authRegisterEmailRateLimit =>
      'Email send rate limit exceeded. Try again in a few minutes.';

  @override
  String get authForgotTitle => 'Reset password';

  @override
  String get authForgotSubtitle =>
      'We will send a link to your email. Open it on this phone to finish resetting your password.';

  @override
  String get authForgotSendLink => 'Send reset link';

  @override
  String get authForgotEmailSent =>
      'Check your email. Open the link on this device to set a new password.';

  @override
  String get authResetTitle => 'Reset password';

  @override
  String get authResetSubtitle => 'Choose a new password for your account.';

  @override
  String get authResetNewPassword => 'New password';

  @override
  String get authResetUpdate => 'Update password';

  @override
  String get authResetSuccess => 'Password updated successfully';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authForgotPasswordLink => 'Forgot password';

  @override
  String get authPasswordTitle => 'Password';

  @override
  String get authEmailContinue => 'Continue';

  @override
  String get authDefaultUserName => 'User';

  @override
  String get authPasswordTooShort => 'Password must be at least 8 characters.';

  @override
  String get authPasswordNeedUpper =>
      'Include at least one uppercase letter (A-Z).';

  @override
  String get authPasswordNeedLower =>
      'Include at least one lowercase letter (a-z).';

  @override
  String get authPasswordNeedDigit => 'Include at least one digit.';

  @override
  String get authPasswordNeedSpecial =>
      'Include at least one special character (non-alphanumeric).';

  @override
  String get authPasswordMismatch => 'Passwords do not match.';

  @override
  String get authPasswordRequirementsBody =>
      'Your password must include:\n• At least 8 characters\n• At least one uppercase letter (A-Z)\n• At least one lowercase letter (a-z)\n• At least one digit (0-9)\n• At least one special character (!@#\\\$%^&* etc.)';

  @override
  String get chatsTitle => 'Chats';

  @override
  String get chatsEmpty => 'No conversations yet';

  @override
  String get chatsNoMatch => 'No conversations match your search';

  @override
  String get chatsSignInTitle => 'Sign in to see your chats.';

  @override
  String get chatsSignInSubtitle =>
      'When signed in, your conversations appear here.';

  @override
  String get chatsSignInButton => 'Sign in';

  @override
  String get chatNotFound => 'Chat not found';

  @override
  String get chatMessageHint => 'Message…';

  @override
  String get chatProfileNotFound => 'Profile not found';

  @override
  String get chatAbout => 'About';

  @override
  String get chatSafety => 'Safety';

  @override
  String chatBlockTitle(Object name) {
    return 'Block $name?';
  }

  @override
  String get chatBlockBody =>
      'They won\'t be able to message you or see your profile in this chat.';

  @override
  String get chatBlockConfirm => 'Block';

  @override
  String chatBlockSuccess(Object name) {
    return '$name has been blocked.';
  }

  @override
  String get chatDeleteTitle => 'Delete conversation?';

  @override
  String get chatDeleteBody =>
      'This chat will be removed from your list. This can\'t be undone.';

  @override
  String get chatDeleteConfirm => 'Delete';

  @override
  String get chatDeleteSuccess => 'Conversation deleted.';

  @override
  String get chatReportSubmitted =>
      'Report submitted. Thanks for helping keep Say Hi safe.';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get chatWeekdayMon => 'Mon';

  @override
  String get chatWeekdayTue => 'Tue';

  @override
  String get chatWeekdayWed => 'Wed';

  @override
  String get chatWeekdayThu => 'Thu';

  @override
  String get chatWeekdayFri => 'Fri';

  @override
  String get chatWeekdaySat => 'Sat';

  @override
  String get chatWeekdaySun => 'Sun';

  @override
  String get mockThreadElenaLast => 'See you at the rooftop tonight ✨';

  @override
  String get mockThreadMarcusLast => 'Haha that was a good one';

  @override
  String get mockThreadSofiaLast => 'Are you still at the café?';

  @override
  String get mockThreadJamesLast =>
      'Sent you a voice note — check when you can';

  @override
  String get mockThreadNinaLast => 'Thanks for the intro yesterday!';

  @override
  String get mockThreadAlexLast => 'Maybe next weekend works better for me';

  @override
  String get mockMsgElena1 => 'Hey! Loved your profile.';

  @override
  String get mockMsgElena2 => 'Thanks! Yours too — especially the travel pics.';

  @override
  String get mockMsgElena3 => 'Are you free this week?';

  @override
  String get mockMsgElena4 => 'Thursday or Friday evening works for me.';

  @override
  String get mockMsgElena5 => 'See you at the rooftop tonight ✨';

  @override
  String get mockMsgMarcus1 => 'Did you see the match?';

  @override
  String get mockMsgMarcus2 => 'Only the highlights — insane finish';

  @override
  String get mockMsgMarcus3 => 'Haha that was a good one';

  @override
  String get mockMsgSofia1 => 'Still at the market near the bridge?';

  @override
  String get mockMsgSofia2 => 'Are you still at the café?';

  @override
  String get mockMsgJames1 => 'Sent you a voice note — check when you can';

  @override
  String get mockMsgNina1 => 'Thanks for the intro yesterday!';

  @override
  String get mockMsgNina2 => 'Anytime — glad you two hit it off';

  @override
  String get mockMsgAlex1 => 'Rain check on Sunday?';

  @override
  String get mockMsgAlex2 => 'Maybe next weekend works better for me';

  @override
  String get mockBioElena =>
      'Product designer who loves rooftop sunsets and indie concerts. Always up for a good espresso and honest conversation. Looking for someone curious and kind.';

  @override
  String get mockBioMarcus =>
      'Weekend hiker, weekday engineer. Big on football, cooking, and bad puns. Say hi if you want to swap playlist recommendations.';

  @override
  String get mockBioSofia =>
      'Art history grad, café hopper, sometimes painter. I value humor, empathy, and people who read more than their algorithm suggests.';

  @override
  String get mockBioJames =>
      'Runner, podcast addict, dog person. Looking for real chemistry and low-drama plans.';

  @override
  String get mockBioNina =>
      'Yoga in the morning, vinyl in the evening. I believe the best dates are half planned, half spontaneous.';

  @override
  String get mockBioAlex =>
      'Photographer, traveler, coffee snob. Prefer plans that start with a walk and end with dessert.';

  @override
  String get chatDeleteChatLabel => 'Delete chat';

  @override
  String get defaultMemberName => 'Member';
}
