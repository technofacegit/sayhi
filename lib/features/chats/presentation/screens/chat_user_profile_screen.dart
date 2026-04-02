import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/chats/data/mock_chat_user_profiles.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

class ChatUserProfileScreen extends StatelessWidget {
  final String chatId;

  const ChatUserProfileScreen({
    super.key,
    required this.chatId,
  });

  Future<void> _confirmAndGoChats(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required String successMessage,
  }) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
    context.go(AppRouter.chatsPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = MockChatUserProfiles.byChatId(l10n, chatId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: Center(child: Text(l10n.chatProfileNotFound)),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          profile.name,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PhotoGrid(photos: profile.photoUrls),
            const SizedBox(height: 24),
            Text(
              l10n.chatAbout,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              profile.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.45,
                color: colorScheme.onSurface.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l10n.chatSafety,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _confirmAndGoChats(
                context,
                title: l10n.chatBlockTitle(profile.name),
                body: l10n.chatBlockBody,
                confirmLabel: l10n.chatBlockConfirm,
                successMessage: l10n.chatBlockSuccess(profile.name),
              ),
              icon: const Icon(Icons.block_rounded),
              label: Text(l10n.commonBlock),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _confirmAndGoChats(
                context,
                title: l10n.chatDeleteTitle,
                body: l10n.chatDeleteBody,
                confirmLabel: l10n.chatDeleteConfirm,
                successMessage: l10n.chatDeleteSuccess,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l10n.chatDeleteChatLabel),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.chatReportSubmitted),
                  ),
                );
              },
              icon: const Icon(Icons.flag_outlined),
              label: Text(l10n.commonReport),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<String> photos;

  const _PhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _PhotoTile(url: photos[0], radius: radius)),
                const SizedBox(width: 8),
                Expanded(child: _PhotoTile(url: photos[1], radius: radius)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _PhotoTile(url: photos[2], radius: radius)),
                const SizedBox(width: 8),
                Expanded(child: _PhotoTile(url: photos[3], radius: radius)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String url;
  final BorderRadius radius;

  const _PhotoTile({
    required this.url,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
