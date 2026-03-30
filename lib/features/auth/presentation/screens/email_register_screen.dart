import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/auth_session.dart';
import 'package:qr_dating_app/features/auth/domain/auth_input_validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailRegisterScreen extends StatefulWidget {
  const EmailRegisterScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailRegisterScreen> createState() => _EmailRegisterScreenState();
}

class _EmailRegisterScreenState extends State<EmailRegisterScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _defaultName(String email) {
    final local = email.split('@').first.trim();
    return local.isNotEmpty ? local : 'User';
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    final policy = AuthInputValidators.passwordPolicyError(password);
    final mismatch = AuthInputValidators.passwordMismatchError(password, confirm);

    setState(() {
      _passwordError = policy;
      _confirmError = policy == null ? mismatch : null;
    });

    if (policy != null) return;
    if (mismatch != null) return;

    final email = widget.email.trim();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user == null) {
        throw Exception('Kayıt oluşturulamadı.');
      }

      if (session != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'name': _defaultName(email),
          'bio': null,
          'age': null,
          'avatar_url': null,
        });
        AuthSession.signIn();
        if (mounted) {
          context.go(AppRouter.homePath);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Hesabınızı tamamlamak için e-postadaki onay bağlantısına tıklayın.',
              ),
            ),
          );
          context.go(AppRouter.loginPath);
        }
      }
    } on AuthException catch (e, st) {
      debugPrint('signUp AuthException: $e');
      debugPrint('$st');
      if (mounted) {
        final msg = e.code == 'over_email_send_rate_limit'
            ? 'E-posta gönderim limiti aşıldı. Birkaç dakika sonra tekrar deneyin.'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e, st) {
      debugPrint('signUp error: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final email = widget.email.trim();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Hesap oluştur',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 20),
              InputDecorator(
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Şifre gereksinimleri',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                child: Text(
                  AuthInputValidators.passwordRequirementsDescription,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  border: const OutlineInputBorder(),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Göster' : 'Gizle',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onChanged: (_) {
                  if (_confirmError != null) {
                    setState(() => _confirmError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Şifre tekrar',
                  border: const OutlineInputBorder(),
                  errorText: _confirmError,
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirm ? 'Göster' : 'Gizle',
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Kayıt ol'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
