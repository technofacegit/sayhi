import 'package:flutter/foundation.dart';

/// MVP: in-memory “logged in” flag (no backend). Set when email flow completes.
abstract final class AuthSession {
  static final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);

  static void signIn() {
    isLoggedIn.value = true;
  }

  static void signOut() {
    isLoggedIn.value = false;
  }
}
