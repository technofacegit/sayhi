import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/auth_session.dart';
import 'package:qr_dating_app/features/chats/data/chat_threads_repository.dart';
import 'package:qr_dating_app/features/chats/presentation/model/chat_thread.dart';
import 'package:qr_dating_app/features/chats/presentation/utils/chat_time_format.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsTabScreen extends StatefulWidget {
  const ChatsTabScreen({super.key});

  @override
  State<ChatsTabScreen> createState() => _ChatsTabScreenState();
}

class _ChatsTabScreenState extends State<ChatsTabScreen> {
  final TextEditingController _search = TextEditingController();
  final ChatThreadsRepository _repo = ChatThreadsRepository();
  RealtimeChannel? _messagesSenderChannel;
  RealtimeChannel? _messagesRecipientChannel;
  RealtimeChannel? _matchViewerChannel;
  RealtimeChannel? _matchTargetChannel;
  Timer? _reloadDebounce;
  Timer? _updatedIndicatorTimer;
  List<ChatThread> _threads = const [];
  List<ChatThread> _newMatches = const [];
  bool _loading = true;
  bool _justUpdated = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _attachRealtime();
    _loadThreads();
  }

  @override
  void dispose() {
    _messagesSenderChannel?.unsubscribe();
    _messagesRecipientChannel?.unsubscribe();
    _matchViewerChannel?.unsubscribe();
    _matchTargetChannel?.unsubscribe();
    _reloadDebounce?.cancel();
    _updatedIndicatorTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _attachRealtime() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    void onAnyEvent(PostgresChangePayload _) {
      if (!mounted) return;
      _reloadDebounce?.cancel();
      _reloadDebounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _loadThreads();
      });
    }

    _messagesSenderChannel = Supabase.instance.client
        .channel('chats_msg_sender_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'sender_id',
            value: uid,
          ),
          callback: onAnyEvent,
        )
      ..subscribe();

    _messagesRecipientChannel = Supabase.instance.client
        .channel('chats_msg_recipient_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: uid,
          ),
          callback: onAnyEvent,
        )
      ..subscribe();

    _matchViewerChannel = Supabase.instance.client
        .channel('chats_match_viewer_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profile_interactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'viewer_id',
            value: uid,
          ),
          callback: onAnyEvent,
        )
      ..subscribe();

    _matchTargetChannel = Supabase.instance.client
        .channel('chats_match_target_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profile_interactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_id',
            value: uid,
          ),
          callback: onAnyEvent,
        )
      ..subscribe();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait<List<ChatThread>>([
        _repo.fetchThreads(limit: 60),
        _repo.fetchNewMatches(limit: 30),
      ]);
      if (!mounted) return;
      final withMessages = results[0]
          .where((t) => t.lastMessage.trim().isNotEmpty)
          .map((t) => t.id)
          .toSet();
      final topMatches = results[1]
          .where((m) => !withMessages.contains(m.id))
          .toList(growable: false);
      setState(() {
        _threads = results[0];
        _newMatches = topMatches;
        _loading = false;
        _justUpdated = true;
      });
      _updatedIndicatorTimer?.cancel();
      _updatedIndicatorTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _justUpdated = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  List<ChatThread> _filtered() {
    final q = _search.text.trim().toLowerCase();
    final list = _threads;
    if (q.isEmpty) return list;
    return list
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: AuthSession.isLoggedIn,
          builder: (context, loggedIn, _) {
            if (!loggedIn) {
              return _ChatsLoggedOutBody(
                onSignIn: () => context.push(AppRouter.loginPath),
              );
            }
            return ListenableBuilder(
              listenable: _search,
              builder: (context, _) {
                final items = _filtered();
                final chatItems = items
                    .where((t) => t.lastMessage.trim().isNotEmpty)
                    .toList(growable: false);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          Text(
                            l10n.chatsTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _justUpdated
                                ? TweenAnimationBuilder<double>(
                                    key: const ValueKey('updated-dot'),
                                    tween: Tween(begin: 0.55, end: 1),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOut,
                                    builder: (context, value, child) {
                                      return Opacity(opacity: value, child: child);
                                    },
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('updated-dot-empty'),
                                    width: 8,
                                    height: 8,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (_newMatches.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 98,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _newMatches.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final m = _newMatches[index];
                            return _NewMatchCircle(
                              thread: m,
                              onTap: () async {
                                await context.push(
                                  AppRouter.chatConversationPath(m.id),
                                );
                                if (!mounted) return;
                                _loadThreads();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SearchBar(
                        controller: _search,
                        hintText: l10n.commonSearch,
                        leading: const Icon(Icons.search_rounded),
                        trailing: [
                          if (_search.text.isNotEmpty)
                            IconButton(
                              onPressed: () => _search.clear(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                        ],
                        elevation: WidgetStateProperty.all(0),
                        backgroundColor: WidgetStatePropertyAll(
                          colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.65),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _loadError != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cloud_off_outlined,
                                          size: 42,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.homeDiscoveryLoadError,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        FilledButton.tonal(
                                          onPressed: _loadThreads,
                                          child: Text(l10n.commonRetry),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : chatItems.isEmpty
                          ? Center(
                              child: Text(
                                _search.text.trim().isEmpty
                                    ? l10n.chatsEmpty
                                    : l10n.chatsNoMatch,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: chatItems.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                indent: 88,
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.35),
                              ),
                              itemBuilder: (context, index) {
                                final thread = chatItems[index];
                                return _ChatThreadTile(
                                  thread: thread,
                                  onTap: () async {
                                    await context.push(
                                      AppRouter.chatConversationPath(thread.id),
                                    );
                                    if (!mounted) return;
                                    _loadThreads();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ChatsLoggedOutBody extends StatelessWidget {
  final VoidCallback onSignIn;

  const _ChatsLoggedOutBody({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Text(
            l10n.chatsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 56,
                  color: colorScheme.primary.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.chatsSignInTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.chatsSignInSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: onSignIn,
                    child: Text(l10n.chatsSignInButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatThreadTile extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const _ChatThreadTile({
    required this.thread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String formatLastOnline(DateTime? t) {
      if (t == null) return '';
      return formatChatListTimestamp(t, context.l10n);
    }

    String readStatus() {
      if (!thread.lastMessageIsMine || thread.lastMessage.trim().isEmpty) {
        return '';
      }
      return thread.lastMessageReadAt == null ? 'Sent' : 'Seen';
    }

    final readMeta = readStatus();
    final onlineMeta = formatLastOnline(thread.lastOnlineAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.9),
                    backgroundImage:
                        thread.avatarUrl.isEmpty ? null : NetworkImage(thread.avatarUrl),
                    child: thread.avatarUrl.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  if (thread.unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        child: Text(
                          thread.unreadCount > 9
                              ? '9+'
                              : '${thread.unreadCount}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: thread.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          formatChatListTimestamp(thread.lastMessageAt, context.l10n),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: thread.unreadCount > 0
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: thread.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.lastMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(
                          alpha: thread.unreadCount > 0 ? 0.92 : 0.62,
                        ),
                        fontWeight: thread.unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                    if (readMeta.isNotEmpty || onlineMeta.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (readMeta.isNotEmpty) ...[
                            Icon(
                              thread.lastMessageReadAt == null
                                  ? Icons.check_rounded
                                  : Icons.done_all_rounded,
                              size: 14,
                              color: thread.lastMessageReadAt == null
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              readMeta,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: thread.lastMessageReadAt == null
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (readMeta.isNotEmpty && onlineMeta.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '•',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          if (onlineMeta.isNotEmpty) ...[
                            Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              onlineMeta,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewMatchCircle extends StatelessWidget {
  const _NewMatchCircle({
    required this.thread,
    required this.onTap,
  });

  final ChatThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              backgroundImage:
                  thread.avatarUrl.isEmpty ? null : NetworkImage(thread.avatarUrl),
              child: thread.avatarUrl.isEmpty
                  ? Icon(Icons.person_rounded, color: colorScheme.onSurfaceVariant)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              thread.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
