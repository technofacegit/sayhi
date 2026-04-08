import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/chats/data/chat_messages_repository.dart';
import 'package:qr_dating_app/features/chats/presentation/utils/chat_time_format.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

class ChatUserProfileScreen extends StatefulWidget {
  final String chatId;

  const ChatUserProfileScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatUserProfileScreen> createState() => _ChatUserProfileScreenState();
}

class _ChatUserProfileScreenState extends State<ChatUserProfileScreen> {
  late final Future<ChatPartnerPreview?> _future =
      ChatMessagesRepository().fetchPartnerPreview(widget.chatId);

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

  List<String> _mosaicUrls(ChatPartnerPreview p) {
    final seen = <String>{};
    final out = <String>[];
    void add(String? s) {
      final t = (s ?? '').trim();
      if (t.isEmpty || seen.contains(t)) return;
      seen.add(t);
      out.add(t);
    }

    add(p.avatarUrl);
    for (final g in p.galleryUrls) {
      add(g);
      if (out.length >= 4) break;
    }
    while (out.length < 4) {
      out.add('');
    }
    return out.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<ChatPartnerPreview?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
            body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final profile = snapshot.data;
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

        final photos = _mosaicUrls(profile);
        final lastOnline = profile.lastOnlineAt == null
            ? null
            : formatChatListTimestamp(profile.lastOnlineAt!, l10n);

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
                _PhotoGrid(photos: photos),
                const SizedBox(height: 24),
                if (lastOnline != null && lastOnline.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last online: $lastOnline',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.chatAbout,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.bio.isEmpty ? '—' : profile.bio,
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
      },
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<String> photos;

  const _PhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final p = photos.length >= 4 ? photos : [...photos, ...List.filled(4 - photos.length, '')];
    final u = p.take(4).toList();
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _PhotoTile(url: u[0], radius: radius)),
                const SizedBox(width: 8),
                Expanded(child: _PhotoTile(url: u[1], radius: radius)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _PhotoTile(url: u[2], radius: radius)),
                const SizedBox(width: 8),
                Expanded(child: _PhotoTile(url: u[3], radius: radius)),
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
    final colorScheme = Theme.of(context).colorScheme;
    if (url.trim().isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(Icons.person_outline_rounded, color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return ColoredBox(
              color: colorScheme.surfaceContainerHighest,
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
