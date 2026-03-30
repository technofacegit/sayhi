import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/features/auth/data/auth_repository.dart';
import 'package:qr_dating_app/features/auth/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// E-posta ile şifre sıfırlama bağlantısı gönderir (deep link: `myapp://reset-password`).
class EmailForgotPasswordScreen extends StatefulWidget {
  const EmailForgotPasswordScreen({
    super.key,
    required this.email,
    AuthRepository? repository,
  }) : _repository = repository;

  final String email;
  final AuthRepository? _repository;

  @override
  State<EmailForgotPasswordScreen> createState() =>
      _EmailForgotPasswordScreenState();
}

class _EmailForgotPasswordScreenState extends State<EmailForgotPasswordScreen> {
  late final AuthRepository _repository;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _repository = widget._repository ??
        AuthRepository(AuthService(Supabase.instance.client));
  }

  String get _email => widget.email.trim();

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await _repository.sendPasswordResetEmail(_email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Check your email. Open the link on this device to set a new password.',
            ),
          ),
        );
      }
    } on AuthException catch (e, st) {
      debugPrint('sendPasswordResetEmail AuthException: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e, st) {
      debugPrint('sendPasswordResetEmail error: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _loading ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Reset password',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We will send a link to your email. Open it on this phone '
                'to finish resetting your password.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _send,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send reset link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
