import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/app/router/go_router_config.dart';
import 'package:qr_dating_app/features/auth/data/auth_repository.dart';
import 'package:qr_dating_app/features/auth/data/auth_service.dart';

/// [myapp://reset-password] linklerini dinler; Supabase oturumu kurularak
/// [ResetPasswordScreen] rotasına gider.
class AuthDeepLinkCoordinator {
  AuthDeepLinkCoordinator({
    AuthRepository? authRepository,
  }) : _authRepository = authRepository ?? AuthRepository(AuthService());

  final AuthRepository _authRepository;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  static bool isResetPasswordLink(Uri uri) {
    return uri.scheme == 'myapp' &&
        (uri.host == 'reset-password' || uri.path == '/reset-password');
  }

  Future<void> init() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      await _handle(initial);
    }
    _subscription = _appLinks.uriLinkStream.listen(_handle);
  }

  Future<void> _handle(Uri uri) async {
    if (!isResetPasswordLink(uri)) return;
    try {
      await _authRepository.establishSessionFromDeepLink(uri);
      AppGoRouter.router.go(AppRouter.resetPasswordPath);
    } catch (e, st) {
      debugPrint('Auth deep link error: $e');
      debugPrint('$st');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
