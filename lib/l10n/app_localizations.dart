import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Say Hi'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get navZones;

  /// No description provided for @navSayHi.
  ///
  /// In en, this message translates to:
  /// **'Say Hi'**
  String get navSayHi;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get navLikes;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @whoLikedMeTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Who Liked Me'**
  String get whoLikedMeTabTitle;

  /// No description provided for @whoLikedMeEmptyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No one has liked you yet.'**
  String get whoLikedMeEmptyPlaceholder;

  /// No description provided for @sayHiLobbyBrowseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No profiles to show yet. Check back soon.'**
  String get sayHiLobbyBrowseEmpty;

  /// No description provided for @likesTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesTabTitle;

  /// No description provided for @myLikesTabTitle.
  ///
  /// In en, this message translates to:
  /// **'My Likes'**
  String get myLikesTabTitle;

  /// No description provided for @likesTabPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'People you liked will appear here.'**
  String get likesTabPlaceholder;

  /// No description provided for @favoritesTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTabTitle;

  /// No description provided for @favoritesTabPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Profiles you save will appear here.'**
  String get favoritesTabPlaceholder;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get commonStart;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get commonBlock;

  /// No description provided for @commonReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commonReport;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Say Hi'**
  String get homeTitle;

  /// No description provided for @homeDiscoveryEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up. Pull to refresh to try again.'**
  String get homeDiscoveryEmpty;

  /// No description provided for @homeDiscoveryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load profiles to show.'**
  String get homeDiscoveryLoadError;

  /// No description provided for @zonePreviewActiveZone.
  ///
  /// In en, this message translates to:
  /// **'Active zone'**
  String get zonePreviewActiveZone;

  /// No description provided for @zonePreviewNoActiveZone.
  ///
  /// In en, this message translates to:
  /// **'No active zone'**
  String get zonePreviewNoActiveZone;

  /// No description provided for @zonePreviewActiveNow.
  ///
  /// In en, this message translates to:
  /// **'{count} active now'**
  String zonePreviewActiveNow(int count);

  /// No description provided for @zonePreviewJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Join a zone to see who is here right now.'**
  String get zonePreviewJoinHint;

  /// No description provided for @recentZonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent zones'**
  String get recentZonesTitle;

  /// No description provided for @recentZoneActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String recentZoneActive(int count);

  /// No description provided for @recentZoneRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {time}'**
  String recentZoneRemaining(Object time);

  /// No description provided for @recentZoneInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get recentZoneInactive;

  /// No description provided for @defaultZoneName.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get defaultZoneName;

  /// No description provided for @defaultVenueName.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get defaultVenueName;

  /// No description provided for @zoneRemainingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {time}'**
  String zoneRemainingPrefix(Object time);

  /// No description provided for @zoneInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get zoneInactive;

  /// No description provided for @zoneDurationZero.
  ///
  /// In en, this message translates to:
  /// **'0 h 0 m'**
  String get zoneDurationZero;

  /// No description provided for @zoneDurationHm.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} m'**
  String zoneDurationHm(int hours, int minutes);

  /// No description provided for @zoneMainLeaveZone.
  ///
  /// In en, this message translates to:
  /// **'Leave zone'**
  String get zoneMainLeaveZone;

  /// No description provided for @zoneMainActiveNow.
  ///
  /// In en, this message translates to:
  /// **'{count} active now'**
  String zoneMainActiveNow(int count);

  /// No description provided for @zoneMainLeaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not leave zone. Try again.'**
  String get zoneMainLeaveError;

  /// No description provided for @zoneMainMissingZoneId.
  ///
  /// In en, this message translates to:
  /// **'Missing zone id.'**
  String get zoneMainMissingZoneId;

  /// No description provided for @zoneMainLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load people in this zone.'**
  String get zoneMainLoadError;

  /// No description provided for @zoneMainFetchingProfiles.
  ///
  /// In en, this message translates to:
  /// **'Loading profiles…'**
  String get zoneMainFetchingProfiles;

  /// No description provided for @zoneMainEmptyAfterIcebreaker.
  ///
  /// In en, this message translates to:
  /// **'No one else is here yet. Pull to refresh or check back soon.'**
  String get zoneMainEmptyAfterIcebreaker;

  /// No description provided for @zoneMainMemberBioPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get zoneMainMemberBioPlaceholder;

  /// No description provided for @zoneHubHeadline.
  ///
  /// In en, this message translates to:
  /// **'Choose a mode'**
  String get zoneHubHeadline;

  /// No description provided for @zoneModeWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Warm Up'**
  String get zoneModeWarmUp;

  /// No description provided for @zoneModeWarmUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick icebreaker questions before you mingle.'**
  String get zoneModeWarmUpSubtitle;

  /// No description provided for @zoneModeWhoIs.
  ///
  /// In en, this message translates to:
  /// **'Who is Game'**
  String get zoneModeWhoIs;

  /// No description provided for @zoneModeWhoIsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guess who — coming soon.'**
  String get zoneModeWhoIsSubtitle;

  /// No description provided for @zoneModeLobby.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get zoneModeLobby;

  /// No description provided for @zoneModeLobbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'See who is here in this zone.'**
  String get zoneModeLobbySubtitle;

  /// No description provided for @zoneLobbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Lobby'**
  String get zoneLobbyTitle;

  /// No description provided for @zoneLobbyFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get zoneLobbyFilterTooltip;

  /// No description provided for @zoneLobbyFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get zoneLobbyFilterTitle;

  /// No description provided for @zoneLobbyFilterGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get zoneLobbyFilterGender;

  /// No description provided for @zoneLobbyFilterGenderAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get zoneLobbyFilterGenderAll;

  /// No description provided for @zoneLobbyFilterGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get zoneLobbyFilterGenderFemale;

  /// No description provided for @zoneLobbyFilterGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get zoneLobbyFilterGenderMale;

  /// No description provided for @zoneLobbyFilterGenderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get zoneLobbyFilterGenderOther;

  /// No description provided for @zoneLobbyFilterAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get zoneLobbyFilterAge;

  /// No description provided for @zoneLobbyFilterAgeToggle.
  ///
  /// In en, this message translates to:
  /// **'Limit by age'**
  String get zoneLobbyFilterAgeToggle;

  /// No description provided for @zoneLobbyFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get zoneLobbyFilterApply;

  /// No description provided for @zoneLobbyFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get zoneLobbyFilterClear;

  /// No description provided for @zoneLobbyFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one matches these filters. Try changing them or clear filters.'**
  String get zoneLobbyFilterEmpty;

  /// No description provided for @zoneMemberProfileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get zoneMemberProfileAbout;

  /// No description provided for @zoneMemberProfileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this profile.'**
  String get zoneMemberProfileLoadError;

  /// No description provided for @zoneMemberProfileLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get zoneMemberProfileLike;

  /// No description provided for @zoneMemberProfileDislike.
  ///
  /// In en, this message translates to:
  /// **'Dislike'**
  String get zoneMemberProfileDislike;

  /// No description provided for @zoneMemberProfileFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get zoneMemberProfileFavoriteTooltip;

  /// No description provided for @zoneMemberProfileSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get zoneMemberProfileSendMessage;

  /// No description provided for @zoneMemberProfileMessageSoon.
  ///
  /// In en, this message translates to:
  /// **'Messaging will be available soon. Chats tab opened.'**
  String get zoneMemberProfileMessageSoon;

  /// No description provided for @zoneMemberProfileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Try again.'**
  String get zoneMemberProfileSaveError;

  /// No description provided for @discoveryProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get discoveryProfileDescription;

  /// No description provided for @zoneWarmUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Warm Up'**
  String get zoneWarmUpTitle;

  /// No description provided for @zoneWhoIsTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is Game'**
  String get zoneWhoIsTitle;

  /// No description provided for @whoIsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this round. Try again.'**
  String get whoIsLoadError;

  /// No description provided for @whoIsCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get whoIsCorrect;

  /// No description provided for @whoIsWrongFeedback.
  ///
  /// In en, this message translates to:
  /// **'Not quite — the right profile is highlighted.'**
  String get whoIsWrongFeedback;

  /// No description provided for @whoIsNextRound.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get whoIsNextRound;

  /// No description provided for @whoIsChooseHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the profile that fits the clue.'**
  String get whoIsChooseHint;

  /// No description provided for @icebreakerSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save answer. Try again.'**
  String get icebreakerSaveError;

  /// No description provided for @icebreakerEarlyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re early'**
  String get icebreakerEarlyTitle;

  /// No description provided for @icebreakerEarlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Kick things off with a quick icebreaker.'**
  String get icebreakerEarlySubtitle;

  /// No description provided for @icebreakerCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Icebreaker'**
  String get icebreakerCardTitle;

  /// No description provided for @icebreakerWarmedUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re warmed up!'**
  String get icebreakerWarmedUp;

  /// No description provided for @icebreakerDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Nice work on all {count} questions. When someone joins the zone, they\'ll show up here.'**
  String icebreakerDoneBody(int count);

  /// No description provided for @icebreakerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load icebreaker questions.'**
  String get icebreakerLoadError;

  /// No description provided for @icebreakerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get icebreakerRetry;

  /// No description provided for @icebreakerProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String icebreakerProgress(int current, int total);

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Scan into the moment'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Join a venue zone by scanning a QR code—only people here, right now.'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Discover nearby'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe through profiles in your zone and keep it effortlessly respectful.'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Match & chat'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'When it\'s mutual, start a conversation and meet—no endless scrolling.'**
  String get onboardingPage3Subtitle;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Say Hi'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meet people in the same place—right now.'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginContinueApple;

  /// No description provided for @loginContinueEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get loginContinueEmail;

  /// No description provided for @loginContinueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get loginContinueGuest;

  /// No description provided for @loginGuestFailed.
  ///
  /// In en, this message translates to:
  /// **'Guest login failed: {error}'**
  String loginGuestFailed(Object error);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @logoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutDialogTitle;

  /// No description provided for @logoutDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You are about to sign out. Continue?'**
  String get logoutDialogMessage;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutConfirm;

  /// No description provided for @logoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get logoutCancel;

  /// No description provided for @routerMissingZone.
  ///
  /// In en, this message translates to:
  /// **'Missing zone'**
  String get routerMissingZone;

  /// No description provided for @activeZoneAppBar.
  ///
  /// In en, this message translates to:
  /// **'Active Zone'**
  String get activeZoneAppBar;

  /// No description provided for @activeZoneHeadline.
  ///
  /// In en, this message translates to:
  /// **'Active Zone'**
  String get activeZoneHeadline;

  /// No description provided for @activeZoneUserCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active users'**
  String activeZoneUserCount(int count);

  /// No description provided for @activeZoneEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter Zone'**
  String get activeZoneEnter;

  /// No description provided for @activeZoneInvalidId.
  ///
  /// In en, this message translates to:
  /// **'No valid ID for this zone.'**
  String get activeZoneInvalidId;

  /// No description provided for @activeZoneCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get activeZoneCancel;

  /// No description provided for @qrJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a Zone'**
  String get qrJoinTitle;

  /// No description provided for @qrJoinCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at the venue QR code'**
  String get qrJoinCameraHint;

  /// No description provided for @qrJoinManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get qrJoinManualTitle;

  /// No description provided for @qrJoinZoneCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Zone Code'**
  String get qrJoinZoneCodeLabel;

  /// No description provided for @qrJoinZoneCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ROOFTOP'**
  String get qrJoinZoneCodeHint;

  /// No description provided for @qrJoinBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get qrJoinBack;

  /// No description provided for @qrJoinTorch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get qrJoinTorch;

  /// No description provided for @qrJoinVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get qrJoinVerifying;

  /// No description provided for @qrJoinEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter code manually'**
  String get qrJoinEnterManually;

  /// No description provided for @qrJoinInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or wrong QR code.'**
  String get qrJoinInvalidCode;

  /// No description provided for @qrJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not join zone: {error}'**
  String qrJoinFailed(Object error);

  /// No description provided for @zonesGoToEntry.
  ///
  /// In en, this message translates to:
  /// **'Go to zone entry'**
  String get zonesGoToEntry;

  /// No description provided for @zonesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search venues'**
  String get zonesSearchHint;

  /// No description provided for @zonesClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get zonesClearTooltip;

  /// No description provided for @zonesStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get zonesStatus;

  /// No description provided for @zonesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get zonesFilterAll;

  /// No description provided for @zonesFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get zonesFilterActive;

  /// No description provided for @zonesFilterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get zonesFilterInactive;

  /// No description provided for @zonesMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get zonesMap;

  /// No description provided for @zonesGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get zonesGrid;

  /// No description provided for @zonesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get zonesNoResults;

  /// No description provided for @zonesLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off.'**
  String get zonesLocationOff;

  /// No description provided for @zonesLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission required.'**
  String get zonesLocationPermission;

  /// No description provided for @zonesLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get location: {error}'**
  String zonesLocationError(Object error);

  /// No description provided for @zonesMapUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Platform map is not supported.'**
  String get zonesMapUnsupported;

  /// No description provided for @zonesRecenter.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get zonesRecenter;

  /// No description provided for @zonesYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get zonesYourLocation;

  /// No description provided for @zonesCityActiveMembers.
  ///
  /// In en, this message translates to:
  /// **'{city} • {count} active members'**
  String zonesCityActiveMembers(Object city, int count);

  /// No description provided for @zonesActiveMembers.
  ///
  /// In en, this message translates to:
  /// **'{count} active members'**
  String zonesActiveMembers(int count);

  /// No description provided for @zonesActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String zonesActiveCount(int count);

  /// No description provided for @storyLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get storyLoading;

  /// No description provided for @storyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Stories could not be loaded'**
  String get storyLoadError;

  /// No description provided for @storyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stories yet'**
  String get storyEmpty;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordRequirementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Password requirements'**
  String get authPasswordRequirementsLabel;

  /// No description provided for @authPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authPasswordConfirm;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get authHidePassword;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authEmailInvalid;

  /// No description provided for @authProfileLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Profile check failed (migration / RLS): {error}'**
  String authProfileLookupFailed(Object error);

  /// No description provided for @authContinueWithEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get authContinueWithEmailTitle;

  /// No description provided for @authContinueWithEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your email to sign in or create an account.'**
  String get authContinueWithEmailSubtitle;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authRegisterSubmit;

  /// No description provided for @authRegisterConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Click the confirmation link in your email to finish.'**
  String get authRegisterConfirmEmail;

  /// No description provided for @authRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create account.'**
  String get authRegisterFailed;

  /// No description provided for @authRegisterEmailRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Email send rate limit exceeded. Try again in a few minutes.'**
  String get authRegisterEmailRateLimit;

  /// No description provided for @authForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authForgotTitle;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will send a link to your email. Open it on this phone to finish resetting your password.'**
  String get authForgotSubtitle;

  /// No description provided for @authForgotSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get authForgotSendLink;

  /// No description provided for @authForgotEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email. Open the link on this device to set a new password.'**
  String get authForgotEmailSent;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get authResetSubtitle;

  /// No description provided for @authResetNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authResetNewPassword;

  /// No description provided for @authResetUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authResetUpdate;

  /// No description provided for @authResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get authResetSuccess;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authForgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get authForgotPasswordLink;

  /// No description provided for @authPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordTitle;

  /// No description provided for @authEmailContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authEmailContinue;

  /// No description provided for @authDefaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get authDefaultUserName;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordNeedUpper.
  ///
  /// In en, this message translates to:
  /// **'Include at least one uppercase letter (A-Z).'**
  String get authPasswordNeedUpper;

  /// No description provided for @authPasswordNeedLower.
  ///
  /// In en, this message translates to:
  /// **'Include at least one lowercase letter (a-z).'**
  String get authPasswordNeedLower;

  /// No description provided for @authPasswordNeedDigit.
  ///
  /// In en, this message translates to:
  /// **'Include at least one digit.'**
  String get authPasswordNeedDigit;

  /// No description provided for @authPasswordNeedSpecial.
  ///
  /// In en, this message translates to:
  /// **'Include at least one special character (non-alphanumeric).'**
  String get authPasswordNeedSpecial;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordRequirementsBody.
  ///
  /// In en, this message translates to:
  /// **'Your password must include:\n• At least 8 characters\n• At least one uppercase letter (A-Z)\n• At least one lowercase letter (a-z)\n• At least one digit (0-9)\n• At least one special character (!@#\\\$%^&* etc.)'**
  String get authPasswordRequirementsBody;

  /// No description provided for @chatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatsTitle;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatsEmpty;

  /// No description provided for @chatsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No conversations match your search'**
  String get chatsNoMatch;

  /// No description provided for @chatsSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your chats.'**
  String get chatsSignInTitle;

  /// No description provided for @chatsSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When signed in, your conversations appear here.'**
  String get chatsSignInSubtitle;

  /// No description provided for @chatsSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get chatsSignInButton;

  /// No description provided for @chatNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chat not found'**
  String get chatNotFound;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get chatMessageHint;

  /// No description provided for @chatPreparingCameraSession.
  ///
  /// In en, this message translates to:
  /// **'Preparing camera…'**
  String get chatPreparingCameraSession;

  /// No description provided for @chatCameraFirstRecordingHint.
  ///
  /// In en, this message translates to:
  /// **'First recording may take a moment…'**
  String get chatCameraFirstRecordingHint;

  /// No description provided for @chatCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get chatCameraUnavailable;

  /// No description provided for @chatTranslateSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get chatTranslateSettingsTitle;

  /// No description provided for @chatTranslateTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Translate message to'**
  String get chatTranslateTargetTitle;

  /// No description provided for @chatTranslateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get chatTranslateOff;

  /// No description provided for @chatTranslatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get chatTranslatedBadge;

  /// No description provided for @chatMenuTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get chatMenuTranslate;

  /// No description provided for @chatMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatMenuDelete;

  /// No description provided for @chatProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get chatProfileNotFound;

  /// No description provided for @chatAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get chatAbout;

  /// No description provided for @chatSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get chatSafety;

  /// No description provided for @chatBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String chatBlockTitle(Object name);

  /// No description provided for @chatBlockBody.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to message you or see your profile in this chat.'**
  String get chatBlockBody;

  /// No description provided for @chatBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get chatBlockConfirm;

  /// No description provided for @chatBlockSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} has been blocked.'**
  String chatBlockSuccess(Object name);

  /// No description provided for @chatDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get chatDeleteTitle;

  /// No description provided for @chatDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This chat will be removed from your list. This can\'t be undone.'**
  String get chatDeleteBody;

  /// No description provided for @chatDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get chatDeleteConfirm;

  /// No description provided for @chatDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Conversation deleted.'**
  String get chatDeleteSuccess;

  /// No description provided for @chatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Message could not be deleted.'**
  String get chatDeleteFailed;

  /// No description provided for @chatReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thanks for helping keep Say Hi safe.'**
  String get chatReportSubmitted;

  /// No description provided for @chatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// No description provided for @chatWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get chatWeekdayMon;

  /// No description provided for @chatWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get chatWeekdayTue;

  /// No description provided for @chatWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get chatWeekdayWed;

  /// No description provided for @chatWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get chatWeekdayThu;

  /// No description provided for @chatWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get chatWeekdayFri;

  /// No description provided for @chatWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get chatWeekdaySat;

  /// No description provided for @chatWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get chatWeekdaySun;

  /// No description provided for @mockThreadElenaLast.
  ///
  /// In en, this message translates to:
  /// **'See you at the rooftop tonight ✨'**
  String get mockThreadElenaLast;

  /// No description provided for @mockThreadMarcusLast.
  ///
  /// In en, this message translates to:
  /// **'Haha that was a good one'**
  String get mockThreadMarcusLast;

  /// No description provided for @mockThreadSofiaLast.
  ///
  /// In en, this message translates to:
  /// **'Are you still at the café?'**
  String get mockThreadSofiaLast;

  /// No description provided for @mockThreadJamesLast.
  ///
  /// In en, this message translates to:
  /// **'Sent you a voice note — check when you can'**
  String get mockThreadJamesLast;

  /// No description provided for @mockThreadNinaLast.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the intro yesterday!'**
  String get mockThreadNinaLast;

  /// No description provided for @mockThreadAlexLast.
  ///
  /// In en, this message translates to:
  /// **'Maybe next weekend works better for me'**
  String get mockThreadAlexLast;

  /// No description provided for @mockMsgElena1.
  ///
  /// In en, this message translates to:
  /// **'Hey! Loved your profile.'**
  String get mockMsgElena1;

  /// No description provided for @mockMsgElena2.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Yours too — especially the travel pics.'**
  String get mockMsgElena2;

  /// No description provided for @mockMsgElena3.
  ///
  /// In en, this message translates to:
  /// **'Are you free this week?'**
  String get mockMsgElena3;

  /// No description provided for @mockMsgElena4.
  ///
  /// In en, this message translates to:
  /// **'Thursday or Friday evening works for me.'**
  String get mockMsgElena4;

  /// No description provided for @mockMsgElena5.
  ///
  /// In en, this message translates to:
  /// **'See you at the rooftop tonight ✨'**
  String get mockMsgElena5;

  /// No description provided for @mockMsgMarcus1.
  ///
  /// In en, this message translates to:
  /// **'Did you see the match?'**
  String get mockMsgMarcus1;

  /// No description provided for @mockMsgMarcus2.
  ///
  /// In en, this message translates to:
  /// **'Only the highlights — insane finish'**
  String get mockMsgMarcus2;

  /// No description provided for @mockMsgMarcus3.
  ///
  /// In en, this message translates to:
  /// **'Haha that was a good one'**
  String get mockMsgMarcus3;

  /// No description provided for @mockMsgSofia1.
  ///
  /// In en, this message translates to:
  /// **'Still at the market near the bridge?'**
  String get mockMsgSofia1;

  /// No description provided for @mockMsgSofia2.
  ///
  /// In en, this message translates to:
  /// **'Are you still at the café?'**
  String get mockMsgSofia2;

  /// No description provided for @mockMsgJames1.
  ///
  /// In en, this message translates to:
  /// **'Sent you a voice note — check when you can'**
  String get mockMsgJames1;

  /// No description provided for @mockMsgNina1.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the intro yesterday!'**
  String get mockMsgNina1;

  /// No description provided for @mockMsgNina2.
  ///
  /// In en, this message translates to:
  /// **'Anytime — glad you two hit it off'**
  String get mockMsgNina2;

  /// No description provided for @mockMsgAlex1.
  ///
  /// In en, this message translates to:
  /// **'Rain check on Sunday?'**
  String get mockMsgAlex1;

  /// No description provided for @mockMsgAlex2.
  ///
  /// In en, this message translates to:
  /// **'Maybe next weekend works better for me'**
  String get mockMsgAlex2;

  /// No description provided for @mockBioElena.
  ///
  /// In en, this message translates to:
  /// **'Product designer who loves rooftop sunsets and indie concerts. Always up for a good espresso and honest conversation. Looking for someone curious and kind.'**
  String get mockBioElena;

  /// No description provided for @mockBioMarcus.
  ///
  /// In en, this message translates to:
  /// **'Weekend hiker, weekday engineer. Big on football, cooking, and bad puns. Say hi if you want to swap playlist recommendations.'**
  String get mockBioMarcus;

  /// No description provided for @mockBioSofia.
  ///
  /// In en, this message translates to:
  /// **'Art history grad, café hopper, sometimes painter. I value humor, empathy, and people who read more than their algorithm suggests.'**
  String get mockBioSofia;

  /// No description provided for @mockBioJames.
  ///
  /// In en, this message translates to:
  /// **'Runner, podcast addict, dog person. Looking for real chemistry and low-drama plans.'**
  String get mockBioJames;

  /// No description provided for @mockBioNina.
  ///
  /// In en, this message translates to:
  /// **'Yoga in the morning, vinyl in the evening. I believe the best dates are half planned, half spontaneous.'**
  String get mockBioNina;

  /// No description provided for @mockBioAlex.
  ///
  /// In en, this message translates to:
  /// **'Photographer, traveler, coffee snob. Prefer plans that start with a walk and end with dessert.'**
  String get mockBioAlex;

  /// No description provided for @chatDeleteChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get chatDeleteChatLabel;

  /// No description provided for @defaultMemberName.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get defaultMemberName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
