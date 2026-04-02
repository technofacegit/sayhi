import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/auth_session.dart';
import 'package:qr_dating_app/features/auth/domain/auth_input_validators.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailPasswordScreen extends StatefulWidget {
  const EmailPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailPasswordScreen> createState() => _EmailPasswordScreenState();
}

class _EmailPasswordScreenState extends State<EmailPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String? _fieldError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final password = _passwordController.text;
    final policy = AuthInputValidators.passwordPolicyError(l10n, password);
    setState(() => _fieldError = policy);
    if (policy != null) return;

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: widget.email.trim(),
        password: password,
      );
      final user = response.user ?? Supabase.instance.client.auth.currentUser;
      final email = widget.email.trim();
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'name': user.userMetadata?['full_name'] as String? ??
              (email.contains('@') ? email.split('@').first : l10n.authDefaultUserName),
          'bio': null,
          'age': null,
          'avatar_url': null,
        });
      }
      AuthSession.signIn();
      if (mounted) {
        context.go(AppRouter.homePath);
      }
    } on AuthException catch (e, st) {
      debugPrint('signInWithPassword AuthException: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e, st) {
      debugPrint('signInWithPassword error: $e');
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
    final l10n = context.l10n;
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
                l10n.authPasswordTitle,
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
                  labelText: l10n.authPasswordRequirementsLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                child: Text(
                  AuthInputValidators.passwordRequirementsDescription(l10n),
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                onChanged: (_) {
                  if (_fieldError != null) {
                    setState(() => _fieldError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.authPassword,
                  border: const OutlineInputBorder(),
                  errorText: _fieldError,
                  suffixIcon: IconButton(
                    tooltip: _obscure ? l10n.authShowPassword : l10n.authHidePassword,
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(
                    AppRouter.emailForgotPasswordPath,
                    extra: widget.email.trim(),
                  ),
                  child: Text(l10n.authForgotPasswordLink),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.authSignIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
