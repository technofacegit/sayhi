import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/auth/data/auth_repository.dart';
import 'package:qr_dating_app/features/auth/data/auth_service.dart';
import 'package:qr_dating_app/features/auth/domain/auth_input_validators.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Deep link ile recovery oturumu açıldıktan sonra yeni şifre belirleme.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    AuthRepository? repository,
  }) : _repository = repository;

  final AuthRepository? _repository;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final AuthRepository _repository;
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _fieldError;

  @override
  void initState() {
    super.initState();
    _repository = widget._repository ??
        AuthRepository(AuthService(Supabase.instance.client));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final password = _passwordController.text;
    final err = AuthInputValidators.passwordPolicyError(l10n, password);
    setState(() => _fieldError = err);
    if (err != null) return;

    setState(() => _loading = true);
    try {
      await _repository.updatePassword(password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.authResetSuccess)),
      );
      context.go(AppRouter.homePath);
    } on AuthException catch (e, st) {
      debugPrint('updatePassword AuthException: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e, st) {
      debugPrint('updatePassword error: $e');
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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.authResetTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authResetSubtitle,
                style: theme.textTheme.bodyLarge,
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
                enabled: !_loading,
                obscureText: _obscure,
                onChanged: (_) {
                  if (_fieldError != null) {
                    setState(() => _fieldError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: l10n.authResetNewPassword,
                  border: const OutlineInputBorder(),
                  errorText: _fieldError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: _loading
                        ? null
                        : () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) {
                  if (!_loading) _submit();
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.authResetUpdate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
