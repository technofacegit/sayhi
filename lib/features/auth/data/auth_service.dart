import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth çağrıları (data katmanı).
class AuthService {
  AuthService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> sendPasswordResetEmail({
    required String email,
    required String redirectTo,
  }) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Deep link URI’sindeki token’larla oturum kurar (recovery / magic link).
  Future<void> establishSessionFromDeepLink(Uri uri) async {
    await _client.auth.getSessionFromUrl(uri);
  }
}
