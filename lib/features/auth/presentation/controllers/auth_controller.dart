import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:qr_dating_app/core/auth_session.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final SupabaseClient _client;

  AuthController({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<void> signInWithApple() async {
    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw Exception('Apple Sign In is not available on this device.');
    }

    final rawNonce = _client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Apple identity token is missing.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    AuthSession.signIn();
  }

  Future<void> signInGuestAndEnsureProfile() async {
    final response = await _client.auth.signInAnonymously();
    final user = response.user ?? _client.auth.currentUser;
    if (user == null) {
      throw Exception('Guest sign in failed.');
    }

    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('profiles').insert({
        'id': user.id,
        'name': 'Guest',
        'bio': null,
        'age': null,
        'avatar_url': null,
      });
    }

    // Guest mode should not unlock chats/auth-required UI.
    AuthSession.signOut();
  }
}

