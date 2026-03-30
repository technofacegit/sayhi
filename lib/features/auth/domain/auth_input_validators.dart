/// Email ve şifre alanları için istemci tarafı doğrulama.
abstract final class AuthInputValidators {
  static bool isValidEmail(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(s);
  }

  /// Geçersizse kullanıcıya gösterilecek ilk kural ihlali mesajı.
  static String? passwordPolicyError(String password) {
    if (password.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'En az bir büyük harf (A-Z) içermelidir.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'En az bir küçük harf (a-z) içermelidir.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'En az bir rakam içermelidir.';
    }
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      return 'En az bir özel karakter (harf ve rakam dışı) içermelidir.';
    }
    return null;
  }

  static String? passwordMismatchError(String password, String confirm) {
    if (password != confirm) {
      return 'Şifreler eşleşmiyor.';
    }
    return null;
  }

  static const String passwordRequirementsDescription = '''
Şifreniz şunları içermelidir:
• En az 8 karakter
• En az bir büyük harf (A-Z)
• En az bir küçük harf (a-z)
• En az bir rakam (0-9)
• En az bir özel karakter (!@#\$%^&* vb.)''';
}
