/// Şifre sıfırlama ekranı için basit kurallar (min 6 karakter).
abstract final class ResetPasswordValidation {
  static String? errorForPassword(String password) {
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}
