import 'package:qr_dating_app/features/auth/data/auth_service.dart';
import 'package:qr_dating_app/features/auth/domain/auth_config.dart';

/// Auth use-case’leri için repository.
class AuthRepository {
  AuthRepository(this._service);

  final AuthService _service;

  Future<void> sendPasswordResetEmail(String email) {
    return _service.sendPasswordResetEmail(
      email: email.trim(),
      redirectTo: AuthConfig.resetPasswordDeepLink,
    );
  }

  Future<void> updatePassword(String newPassword) {
    return _service.updatePassword(newPassword);
  }

  Future<void> establishSessionFromDeepLink(Uri uri) {
    return _service.establishSessionFromDeepLink(uri);
  }
}
