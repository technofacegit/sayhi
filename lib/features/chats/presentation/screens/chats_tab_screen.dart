import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/chats/data/mock_chat_threads.dart';
import 'package:qr_dating_app/features/chats/presentation/model/chat_thread.dart';
import 'package:qr_dating_app/features/chats/presentation/utils/chat_time_format.dart';

class ChatsTabScreen extends StatefulWidget {
  const ChatsTabScreen({super.key});

  @override
  State<ChatsTabScreen> createState() => _ChatsTabScreenState();
}

class _ChatsTabScreenState extends State<ChatsTabScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ChatThread> get _filtered {
    final q = _search.text.trim().toLowerCase();
    final list = MockChatThreads.all;
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _search,
          builder: (context, _) {
            final items = _filtered;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    'Chats',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SearchBar(
                    controller: _search,
                    hintText: 'Search',
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
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
                    ),
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            _search.text.trim().isEmpty
                                ? 'No conversations yet'
                                : 'No conversations match your search',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 88,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                          ),
                          itemBuilder: (context, index) {
                            final thread = items[index];
                            return _ChatThreadTile(
                              thread: thread,
                              onTap: () => context.push(
                                AppRouter.chatConversationPath(thread.id),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
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
                    backgroundColor:
                        colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                    backgroundImage: NetworkImage(thread.avatarUrl),
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
                          formatChatListTimestamp(thread.lastMessageAt),
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
