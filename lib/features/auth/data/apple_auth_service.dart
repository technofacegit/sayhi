import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppleAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> signInWithApple() async {
    final rawNonce = _supabase.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple ID token not found.');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    var user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No user after Apple sign-in.');
    }

    final nameParts = <String>[];
    if (credential.givenName != null && credential.givenName!.isNotEmpty) {
      nameParts.add(credential.givenName!);
    }
    if (credential.familyName != null && credential.familyName!.isNotEmpty) {
      nameParts.add(credential.familyName!);
    }
    final fullName = nameParts.join(' ');

    if (credential.givenName != null || credential.familyName != null) {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'given_name': credential.givenName,
            'family_name': credential.familyName,
          },
        ),
      );
      user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user after profile metadata update.');
      }
    }

    await _supabase.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'name': fullName.isNotEmpty
          ? fullName
          : (user.userMetadata?['full_name'] ?? 'User'),
      'bio': null,
      'age': null,
      'avatar_url': null,
    });
  }
}
