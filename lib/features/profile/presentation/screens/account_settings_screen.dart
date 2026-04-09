import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/auth/data/auth_service.dart';
import 'package:qr_dating_app/features/auth/domain/auth_config.dart';
import 'package:qr_dating_app/features/profile/data/account_deletion_service.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _auth = Supabase.instance.client.auth;
  final AccountDeletionService _deletion = AccountDeletionService();
  final AuthService _authService = AuthService();
  final TextEditingController _deleteConfirmController = TextEditingController();

  bool _loading = true;
  bool _deleting = false;
  List<UserIdentity> _identities = const [];
  User? _user;
  bool _pushGranted = false;

  @override
  void dispose() {
    _deleteConfirmController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ids = await _auth.getUserIdentities();
      final n = await Permission.notification.status;
      if (!mounted) return;
      setState(() {
        _identities = ids;
        _user = _auth.currentUser;
        _pushGranted = n.isGranted;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _user = _auth.currentUser;
        _loading = false;
      });
    }
  }

  bool get _hasEmailProvider =>
      _identities.any((i) => i.provider == 'email');

  String _providerLabel(String provider) {
    final l10n = context.l10n;
    switch (provider) {
      case 'apple':
        return l10n.accountSettingsProviderApple;
      case 'google':
        return l10n.accountSettingsProviderGoogle;
      case 'email':
        return l10n.accountSettingsProviderEmail;
      default:
        return provider;
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _user?.email?.trim();
    final l10n = context.l10n;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsNotSet)),
      );
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(
        email: email,
        redirectTo: AuthConfig.resetPasswordDeepLink,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountSettingsPasswordResetSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _onPushToggle(bool wantOn) async {
    if (wantOn) {
      final s = await Permission.notification.request();
      if (!mounted) return;
      setState(() => _pushGranted = s.isGranted);
      if (!s.isGranted && s.isPermanentlyDenied) {
        await openAppSettings();
      }
    } else {
      await openAppSettings();
      final n = await Permission.notification.status;
      if (!mounted) return;
      setState(() => _pushGranted = n.isGranted);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    _deleteConfirmController.clear();
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountSettingsDeleteConfirmTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.accountSettingsDeleteConfirmBody),
              const SizedBox(height: 16),
              TextField(
                controller: _deleteConfirmController,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.accountSettingsDeleteTypeLabel,
                  hintText: l10n.accountSettingsDeleteTypeHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () {
              final ok = _deleteConfirmController.text.trim() ==
                  l10n.accountSettingsDeleteTypeHint;
              if (!ok) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.accountSettingsDeleteMismatch)),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await _deletion.deleteCurrentUser();
      _deleteConfirmController.clear();
      if (!mounted) return;
      context.go(AppRouter.loginPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.accountSettingsDeleteFailed} $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSettingsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    l10n.accountSettingsContactSection,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined),
                    title: Text(l10n.accountSettingsEmailLabel),
                    subtitle: Text(
                      (_user?.email ?? '').trim().isEmpty
                          ? l10n.accountSettingsNotSet
                          : _user!.email!.trim(),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.phone_outlined),
                    title: Text(l10n.accountSettingsPhoneLabel),
                    subtitle: Text(
                      (_user?.phone ?? '').trim().isEmpty
                          ? l10n.accountSettingsNotSet
                          : _user!.phone!.trim(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.accountSettingsSignInSection,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_identities.isEmpty)
                    Text(
                      l10n.accountSettingsNotSet,
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final id in _identities)
                          Chip(
                            avatar: Icon(
                              _iconForProvider(id.provider),
                              size: 18,
                            ),
                            label: Text(_providerLabel(id.provider)),
                          ),
                      ],
                    ),
                  if (_hasEmailProvider) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _sendPasswordReset,
                        icon: const Icon(Icons.lock_reset_rounded),
                        label: Text(l10n.accountSettingsPasswordReset),
                      ),
                    ),
                  ],
                  if (_identities.any((i) => i.provider == 'apple')) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.accountSettingsAppleHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.accountSettingsGoogleHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.accountSettingsNotificationsSection,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.notifications_outlined),
                    title: Text(l10n.accountSettingsPushLabel),
                    subtitle: Text(l10n.accountSettingsPushSubtitle),
                    value: _pushGranted,
                    onChanged: _deleting ? null : _onPushToggle,
                  ),
                  TextButton.icon(
                    onPressed: openAppSettings,
                    icon: const Icon(Icons.settings_rounded),
                    label: Text(l10n.accountSettingsOpenSettings),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.accountSettingsDangerZone,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_forever_rounded, color: colors.error),
                    title: Text(
                      l10n.accountSettingsDeleteTitle,
                      style: TextStyle(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(l10n.accountSettingsDeleteSubtitle),
                    onTap: _deleting ? null : _confirmDelete,
                  ),
                  if (_deleting)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.error,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(l10n.accountSettingsDeleting),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  IconData _iconForProvider(String provider) {
    switch (provider) {
      case 'apple':
        return Icons.apple;
      case 'google':
        return Icons.g_mobiledata_rounded;
      default:
        return Icons.login_rounded;
    }
  }
}
