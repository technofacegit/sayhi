import 'package:qr_dating_app/l10n/app_localizations.dart';

/// Email ve şifre alanları için istemci tarafı doğrulama.
abstract final class AuthInputValidators {
  static bool isValidEmail(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(s);
  }

  /// Geçersizse kullanıcıya gösterilecek ilk kural ihlali mesajı.
  static String? passwordPolicyError(AppLocalizations l10n, String password) {
    if (password.length < 8) {
      return l10n.authPasswordTooShort;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return l10n.authPasswordNeedUpper;
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return l10n.authPasswordNeedLower;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return l10n.authPasswordNeedDigit;
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      return l10n.authPasswordNeedSpecial;
    }
    return null;
  }

  static String? passwordMismatchError(AppLocalizations l10n, String password, String confirm) {
    if (password != confirm) {
      return l10n.authPasswordMismatch;
    }
    return null;
  }

  static String passwordRequirementsDescription(AppLocalizations l10n) =>
      l10n.authPasswordRequirementsBody;
}
