// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Say Hi';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navZones => 'Bölgeler';

  @override
  String get navSayHi => 'Say Hi';

  @override
  String get navChats => 'Sohbetler';

  @override
  String get navLikes => 'Beğeniler';

  @override
  String get navFavorites => 'Favoriler';

  @override
  String get navProfile => 'Profil';

  @override
  String get whoLikedMeTabTitle => 'Beni Beğenenler';

  @override
  String get whoLikedMeEmptyPlaceholder => 'Henüz sizi beğenen kimse yok.';

  @override
  String get sayHiLobbyBrowseEmpty =>
      'Şu an gösterilecek profil yok. Daha sonra tekrar deneyin.';

  @override
  String get likesTabTitle => 'Beğeniler';

  @override
  String get myLikesTabTitle => 'Beğendiklerim';

  @override
  String get likesTabPlaceholder => 'Beğendiğin kişiler burada görünecek.';

  @override
  String get favoritesTabTitle => 'Favoriler';

  @override
  String get favoritesTabPlaceholder =>
      'Kaydettiğin profiller burada görünecek.';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonContinue => 'Devam';

  @override
  String get commonRetry => 'Yeniden dene';

  @override
  String get commonSkip => 'Atla';

  @override
  String get commonStart => 'Başla';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonBlock => 'Engelle';

  @override
  String get commonReport => 'Şikayet et';

  @override
  String get commonSearch => 'Ara';

  @override
  String get commonLoading => 'Yükleniyor…';

  @override
  String get commonOk => 'OK';

  @override
  String get homeTitle => 'Say Hi';

  @override
  String get homeDiscoveryEmpty =>
      'Şimdilik başka profil yok. Yenilemek için aşağı çek.';

  @override
  String get homeDiscoveryLoadError => 'Profiller yüklenemedi.';

  @override
  String get zonePreviewActiveZone => 'Aktif bölge';

  @override
  String get zonePreviewNoActiveZone => 'Aktif bölge yok';

  @override
  String zonePreviewActiveNow(int count) {
    return '$count şu an aktif';
  }

  @override
  String get zonePreviewJoinHint =>
      'Kimlerin burada olduğunu görmek için bir bölgeye katıl.';

  @override
  String get recentZonesTitle => 'Son bölgeler';

  @override
  String recentZoneActive(int count) {
    return '$count aktif';
  }

  @override
  String recentZoneRemaining(Object time) {
    return 'Kalan: $time';
  }

  @override
  String get recentZoneInactive => 'Pasif';

  @override
  String get defaultZoneName => 'Bölge';

  @override
  String get defaultVenueName => 'Mekan';

  @override
  String zoneRemainingPrefix(Object time) {
    return 'Kalan: $time';
  }

  @override
  String get zoneInactive => 'Pasif';

  @override
  String get zoneDurationZero => '0 sa 0 dk';

  @override
  String zoneDurationHm(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get zoneMainLeaveZone => 'Bölgeden ayrıl';

  @override
  String zoneMainActiveNow(int count) {
    return '$count şu an aktif';
  }

  @override
  String get zoneMainLeaveError => 'Bölgeden ayrılamadı. Tekrar deneyin.';

  @override
  String get zoneMainMissingZoneId => 'Bölge kimliği eksik.';

  @override
  String get zoneMainLoadError => 'Bu bölgedeki kişiler yüklenemedi.';

  @override
  String get zoneMainFetchingProfiles => 'Profiller getiriliyor';

  @override
  String get zoneMainEmptyAfterIcebreaker =>
      'Şimdilik başka kimse yok. Yenilemek için aşağı çekin.';

  @override
  String get zoneMainMemberBioPlaceholder => '—';

  @override
  String get zoneHubHeadline => 'Mod seçin';

  @override
  String get zoneModeWarmUp => 'Isınma';

  @override
  String get zoneModeWarmUpSubtitle =>
      'Tanışmadan önce kısa buz kırıcı soruları.';

  @override
  String get zoneModeWhoIs => 'Kim oyunu';

  @override
  String get zoneModeWhoIsSubtitle => 'Tahmin et — çok yakında.';

  @override
  String get zoneModeLobby => 'Lobi';

  @override
  String get zoneModeLobbySubtitle => 'Bu bölgede kimler var, görüntüle.';

  @override
  String get zoneLobbyTitle => 'Lobi';

  @override
  String get zoneLobbyFilterTooltip => 'Filtreler';

  @override
  String get zoneLobbyFilterTitle => 'Filtreler';

  @override
  String get zoneLobbyFilterGender => 'Cinsiyet';

  @override
  String get zoneLobbyFilterGenderAll => 'Tümü';

  @override
  String get zoneLobbyFilterGenderFemale => 'Kadın';

  @override
  String get zoneLobbyFilterGenderMale => 'Erkek';

  @override
  String get zoneLobbyFilterGenderOther => 'Diğer';

  @override
  String get zoneLobbyFilterAge => 'Yaş';

  @override
  String get zoneLobbyFilterAgeToggle => 'Yaşa göre sınırla';

  @override
  String get discoveryFilterCountry => 'Ülke';

  @override
  String get discoveryFilterCountryHint => 'örn. Türkiye';

  @override
  String get discoveryFilterDistance => 'Mesafe';

  @override
  String get discoveryFilterDistanceToggle => 'Mesafeye göre sınırla';

  @override
  String get zoneLobbyFilterApply => 'Uygula';

  @override
  String get zoneLobbyFilterClear => 'Temizle';

  @override
  String get zoneLobbyFilterEmpty =>
      'Bu filtrelere uyan kimse yok. Filtreleri değiştirin veya temizleyin.';

  @override
  String get zoneMemberProfileAbout => 'Hakkında';

  @override
  String get zoneMemberProfileLoadError => 'Profil yüklenemedi.';

  @override
  String get zoneMemberProfileLike => 'Beğen';

  @override
  String get zoneMemberProfileDislike => 'Beğenme';

  @override
  String get zoneMemberProfileFavoriteTooltip => 'Favorilere ekle';

  @override
  String get zoneMemberProfileSendMessage => 'Mesaj gönder';

  @override
  String get zoneMemberProfileMessageSoon =>
      'Mesajlaşma çok yakında. Sohbetler sekmesi açıldı.';

  @override
  String get zoneMemberProfileSaveError => 'Kaydedilemedi. Tekrar deneyin.';

  @override
  String get discoveryProfileDescription => 'Açıklama';

  @override
  String get zoneWarmUpTitle => 'Isınma';

  @override
  String get zoneWhoIsTitle => 'Kim oyunu';

  @override
  String get whoIsLoadError => 'Bu tur yüklenemedi. Tekrar deneyin.';

  @override
  String get whoIsCorrect => 'Doğru!';

  @override
  String get whoIsWrongFeedback => 'Olmadı — doğru profil vurgulandı.';

  @override
  String get whoIsNextRound => 'Sonraki tur';

  @override
  String get whoIsChooseHint => 'İpucuna uyan profili seç.';

  @override
  String get icebreakerSaveError => 'Cevap kaydedilemedi. Tekrar deneyin.';

  @override
  String get icebreakerEarlyTitle => 'Erken geldin';

  @override
  String get icebreakerEarlySubtitle => 'Hızlı bir buz kırıcı ile başla.';

  @override
  String get icebreakerCardTitle => 'Buz kırıcı';

  @override
  String get icebreakerWarmedUp => 'Isındın!';

  @override
  String icebreakerDoneBody(int count) {
    return 'Tüm $count soruyu bitirdin. Birisi bölgeye katıldığında burada görünür.';
  }

  @override
  String get icebreakerLoadError => 'Buz kırıcı soruları yüklenemedi.';

  @override
  String get icebreakerRetry => 'Yeniden dene';

  @override
  String icebreakerProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get onboardingSkip => 'Atla';

  @override
  String get onboardingContinue => 'Devam';

  @override
  String get onboardingStart => 'Başla';

  @override
  String get onboardingPage1Title => 'Anı yakala';

  @override
  String get onboardingPage1Subtitle =>
      'QR kodu tarayarak mekan bölgesine katıl—yalnızca şu an buradaki insanlar.';

  @override
  String get onboardingPage2Title => 'Yakını keşfet';

  @override
  String get onboardingPage2Subtitle =>
      'Bölgenizdeki profilleri kaydır; saygılı ve rahat kal.';

  @override
  String get onboardingPage3Title => 'Eşleş ve sohbet et';

  @override
  String get onboardingPage3Subtitle =>
      'Karşılıklı olunca sohbete başla ve buluş—sonsuz kaydırma yok.';

  @override
  String get loginWelcomeTitle => 'Say Hi\'ye hoş geldin';

  @override
  String get loginWelcomeSubtitle => 'Aynı yerdeki insanlarla tanış—şu an.';

  @override
  String get loginContinueApple => 'Apple ile devam et';

  @override
  String get loginContinueEmail => 'E-posta ile devam et';

  @override
  String get loginContinueGuest => 'Misafir olarak devam et';

  @override
  String loginGuestFailed(Object error) {
    return 'Misafir girişi başarısız: $error';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileLogout => 'Çıkış yap';

  @override
  String get logoutDialogTitle => 'Çıkış';

  @override
  String get logoutDialogMessage =>
      'Çıkış yapmak üzeresiniz. Devam etmek istiyor musunuz?';

  @override
  String get logoutConfirm => 'Çıkış yap';

  @override
  String get logoutCancel => 'İptal';

  @override
  String get routerMissingZone => 'Bölge eksik';

  @override
  String get activeZoneAppBar => 'Aktif bölge';

  @override
  String get activeZoneHeadline => 'Aktif bölge';

  @override
  String activeZoneUserCount(int count) {
    return '$count aktif kullanıcı';
  }

  @override
  String get activeZoneEnter => 'Bölgeye gir';

  @override
  String get activeZoneInvalidId => 'Bu bölge için geçerli bir ID yok.';

  @override
  String get activeZoneCancel => 'İptal';

  @override
  String get qrJoinTitle => 'Bölgeye katıl';

  @override
  String get qrJoinCameraHint => 'Kameranı mekan QR koduna tut';

  @override
  String get qrJoinManualTitle => 'Kodu elle gir';

  @override
  String get qrJoinZoneCodeLabel => 'Bölge kodu';

  @override
  String get qrJoinZoneCodeHint => 'ör. ROOFTOP';

  @override
  String get qrJoinBack => 'Geri';

  @override
  String get qrJoinTorch => 'Fener';

  @override
  String get qrJoinVerifying => 'Doğrulanıyor…';

  @override
  String get qrJoinEnterManually => 'Kodu elle gir';

  @override
  String get qrJoinInvalidCode => 'Yanlış veya geçersiz QR kod.';

  @override
  String qrJoinFailed(Object error) {
    return 'Bölgeye giriş başarısız: $error';
  }

  @override
  String get zonesGoToEntry => 'Bölge giriş ekranına git';

  @override
  String get zonesSearchHint => 'Mekan ara';

  @override
  String get zonesClearTooltip => 'Temizle';

  @override
  String get zonesStatus => 'Durum';

  @override
  String get zonesFilterAll => 'Tümü';

  @override
  String get zonesFilterActive => 'Aktif';

  @override
  String get zonesFilterInactive => 'Pasif';

  @override
  String get zonesMap => 'Harita';

  @override
  String get zonesGrid => 'Grid';

  @override
  String get zonesNoResults => 'Sonuç yok';

  @override
  String get zonesLocationOff => 'Konum servisleri kapalı.';

  @override
  String get zonesLocationPermission => 'Konum izni gerekli.';

  @override
  String zonesLocationError(Object error) {
    return 'Konum alınamadı: $error';
  }

  @override
  String get zonesMapUnsupported => 'Bu platformda harita desteklenmiyor.';

  @override
  String get zonesRecenter => 'Konumumu merkeze al';

  @override
  String get zonesYourLocation => 'Konumun';

  @override
  String zonesCityActiveMembers(Object city, int count) {
    return '$city • $count aktif üye';
  }

  @override
  String zonesActiveMembers(int count) {
    return '$count aktif üye';
  }

  @override
  String zonesActiveCount(int count) {
    return '$count aktif';
  }

  @override
  String get storyLoading => 'Yükleniyor…';

  @override
  String get storyLoadError => 'Storyler yüklenemedi';

  @override
  String get storyEmpty => 'Henüz story yok';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authPasswordRequirementsLabel => 'Şifre gereksinimleri';

  @override
  String get authPasswordConfirm => 'Şifre tekrar';

  @override
  String get authShowPassword => 'Göster';

  @override
  String get authHidePassword => 'Gizle';

  @override
  String get authEmailLabel => 'E-posta';

  @override
  String get authEmailRequired => 'E-posta adresi gerekli.';

  @override
  String get authEmailInvalid => 'Geçerli bir e-posta adresi girin.';

  @override
  String authProfileLookupFailed(Object error) {
    return 'Profil kontrolü başarısız (migration / RLS): $error';
  }

  @override
  String get authContinueWithEmailTitle => 'E-posta ile devam et';

  @override
  String get authContinueWithEmailSubtitle =>
      'Giriş yapmak veya hesap oluşturmak için e-postanı kullan.';

  @override
  String get authRegisterTitle => 'Hesap oluştur';

  @override
  String get authRegisterSubmit => 'Kayıt ol';

  @override
  String get authRegisterConfirmEmail =>
      'Hesabınızı tamamlamak için e-postadaki onay bağlantısına tıklayın.';

  @override
  String get authRegisterFailed => 'Kayıt oluşturulamadı.';

  @override
  String get authRegisterEmailRateLimit =>
      'E-posta gönderim limiti aşıldı. Birkaç dakika sonra tekrar deneyin.';

  @override
  String get authForgotTitle => 'Şifre sıfırla';

  @override
  String get authForgotSubtitle =>
      'E-postana bir bağlantı göndereceğiz. Şifreni sıfırlamak için bu telefonda aç.';

  @override
  String get authForgotSendLink => 'Sıfırlama bağlantısı gönder';

  @override
  String get authForgotEmailSent =>
      'E-postanı kontrol et. Yeni şifre için bağlantıyı bu cihazda aç.';

  @override
  String get authResetTitle => 'Şifre sıfırla';

  @override
  String get authResetSubtitle => 'Hesabın için yeni bir şifre seç.';

  @override
  String get authResetNewPassword => 'Yeni şifre';

  @override
  String get authResetUpdate => 'Şifreyi güncelle';

  @override
  String get authResetSuccess => 'Şifre başarıyla güncellendi';

  @override
  String get authSignIn => 'Giriş yap';

  @override
  String get authForgotPasswordLink => 'Şifremi unuttum';

  @override
  String get authPasswordTitle => 'Şifre';

  @override
  String get authEmailContinue => 'Devam';

  @override
  String get authDefaultUserName => 'Kullanıcı';

  @override
  String get authPasswordTooShort => 'Şifre en az 8 karakter olmalıdır.';

  @override
  String get authPasswordNeedUpper => 'En az bir büyük harf (A-Z) içermelidir.';

  @override
  String get authPasswordNeedLower => 'En az bir küçük harf (a-z) içermelidir.';

  @override
  String get authPasswordNeedDigit => 'En az bir rakam içermelidir.';

  @override
  String get authPasswordNeedSpecial =>
      'En az bir özel karakter (harf ve rakam dışı) içermelidir.';

  @override
  String get authPasswordMismatch => 'Şifreler eşleşmiyor.';

  @override
  String get authPasswordRequirementsBody =>
      'Şifreniz şunları içermelidir:\n• En az 8 karakter\n• En az bir büyük harf (A-Z)\n• En az bir küçük harf (a-z)\n• En az bir rakam (0-9)\n• En az bir özel karakter (!@#\\\$%^&* vb.)';

  @override
  String get chatsTitle => 'Sohbetler';

  @override
  String get chatsEmpty => 'Henüz sohbet yok';

  @override
  String get chatsNoMatch => 'Aramanızla eşleşen sohbet yok';

  @override
  String get chatsSignInTitle => 'Sohbetlerinizi görmek için oturum açın.';

  @override
  String get chatsSignInSubtitle =>
      'Oturum açtığınızda konuşmalarınız burada listelenir.';

  @override
  String get chatsSignInButton => 'Oturum aç';

  @override
  String get chatNotFound => 'Sohbet bulunamadı';

  @override
  String get chatMessageHint => 'Mesaj…';

  @override
  String get chatPreparingCameraSession => 'Kamera hazırlanıyor…';

  @override
  String get chatCameraFirstRecordingHint => 'İlk kayıt biraz sürebilir…';

  @override
  String get chatCameraUnavailable => 'Kamera kullanılamıyor';

  @override
  String get chatTranslateSettingsTitle => 'Çeviri';

  @override
  String get chatTranslateTargetTitle => 'Mesajı şu dile çevir';

  @override
  String get chatTranslateOff => 'Kapalı';

  @override
  String get chatTranslatedBadge => 'Çevrildi';

  @override
  String get chatMenuTranscribe => 'Metne dök';

  @override
  String get chatMenuTranslate => 'Çevir';

  @override
  String get chatMenuDelete => 'Sil';

  @override
  String get chatPhotoTake => 'Fotoğraf çek';

  @override
  String get chatPhotoFromLibrary => 'Galeriden seç';

  @override
  String get chatPhotoUploading => 'Fotoğraf yükleniyor...';

  @override
  String get chatCameraSwitching => 'Kamera değiştiriliyor...';

  @override
  String get chatTranscriptionLoading => 'Metne dökülüyor…';

  @override
  String get chatTranscriptionUnavailable =>
      'Bu cihazda metne dökme kullanılamıyor';

  @override
  String get chatTranscriptionFailed => 'Bu video metne dökülemedi';

  @override
  String get chatProfileNotFound => 'Profil bulunamadı';

  @override
  String get chatAbout => 'Hakkında';

  @override
  String get chatSafety => 'Güvenlik';

  @override
  String chatBlockTitle(Object name) {
    return '$name engellensin mi?';
  }

  @override
  String get chatBlockBody =>
      'Bu sohbette size mesaj atamaz ve profilinizi göremez.';

  @override
  String get chatBlockConfirm => 'Engelle';

  @override
  String chatBlockSuccess(Object name) {
    return '$name engellendi.';
  }

  @override
  String get chatDeleteTitle => 'Sohbet silinsin mi?';

  @override
  String get chatDeleteBody => 'Sohbet listenden kaldırılır. Geri alınamaz.';

  @override
  String get chatDeleteConfirm => 'Sil';

  @override
  String get chatDeleteSuccess => 'Sohbet silindi.';

  @override
  String get chatDeleteFailed => 'Mesaj silinemedi.';

  @override
  String get chatReportSubmitted =>
      'Şikayet gönderildi. Say Hi\'yi güvenli tutmaya yardımcı olduğun için teşekkürler.';

  @override
  String get chatYesterday => 'Dün';

  @override
  String get chatWeekdayMon => 'Pzt';

  @override
  String get chatWeekdayTue => 'Sal';

  @override
  String get chatWeekdayWed => 'Çar';

  @override
  String get chatWeekdayThu => 'Per';

  @override
  String get chatWeekdayFri => 'Cum';

  @override
  String get chatWeekdaySat => 'Cmt';

  @override
  String get chatWeekdaySun => 'Paz';

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
  String get chatDeleteChatLabel => 'Sohbeti sil';

  @override
  String get defaultMemberName => 'Üye';
}
