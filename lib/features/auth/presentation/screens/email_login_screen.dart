import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/auth/data/profile_lookup_service.dart';
import 'package:qr_dating_app/features/auth/domain/auth_input_validators.dart';
import 'package:qr_dating_app/l10n/app_localizations.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  bool _submitAttempted = false;
  bool _loading = false;

  String? _emailError(AppLocalizations l10n) {
    final text = _emailController.text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return _submitAttempted ? l10n.authEmailRequired : null;
    }
    if (!AuthInputValidators.isValidEmail(text)) {
      return l10n.authEmailInvalid;
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final l10n = context.l10n;
    setState(() => _submitAttempted = true);
    final email = _emailController.text.trim();
    if (!AuthInputValidators.isValidEmail(email)) return;

    setState(() => _loading = true);
    try {
      final exists = await ProfileLookupService().emailExistsInProfiles(email);
      if (!mounted) return;
      if (exists) {
        context.push(AppRouter.emailPasswordPath, extra: email);
      } else {
        context.push(AppRouter.emailRegisterPath, extra: email);
      }
    } catch (e, st) {
      debugPrint('profile lookup error: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.authProfileLookupFailed(e.toString())),
          ),
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
    final l10n = context.l10n;

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
                l10n.authContinueWithEmailTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.authContinueWithEmailSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                enabled: !_loading,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => setState(() {
                  _submitAttempted = false;
                }),
                decoration: InputDecoration(
                  labelText: l10n.authEmailLabel,
                  border: const OutlineInputBorder(),
                  errorText: _emailError(l10n),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _continue,
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.authEmailContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
