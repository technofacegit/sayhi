import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/core/auth_session.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with WidgetsBindingObserver {
  RealtimeChannel? _likesChannel;
  Timer? _likesRefreshTimer;
  int _incomingLikesUnreadCount = 0;
  DateTime? _likesSeenAtUtc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthSession.isLoggedIn.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthSession.isLoggedIn.removeListener(_onAuthChanged);
    _likesChannel?.unsubscribe();
    _likesRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    if (widget.navigationShell.currentIndex == 1) return;
    _refreshIncomingLikesUnreadCount(uid);
  }

  void _onAuthChanged() {
    _likesChannel?.unsubscribe();
    _likesChannel = null;
    _likesRefreshTimer?.cancel();
    _likesRefreshTimer = null;

    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      _likesSeenAtUtc = null;
      if (mounted) setState(() => _incomingLikesUnreadCount = 0);
      return;
    }
    _loadSeenAndRefresh(uid);
    _likesChannel = Supabase.instance.client
        .channel('likes_badge_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profile_interactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_id',
            value: uid,
          ),
          callback: (payload) => _onLikesRealtimeEvent(uid, payload),
        )
      ..subscribe();

    // Fallback polling keeps badge fresh even if realtime event is missed.
    _likesRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final currentUid = Supabase.instance.client.auth.currentUser?.id;
      if (currentUid == null) return;
      if (widget.navigationShell.currentIndex == 1) return;
      _refreshIncomingLikesUnreadCount(currentUid);
    });
  }

  void _onLikesRealtimeEvent(String uid, PostgresChangePayload payload) {
    if (!mounted) return;
    if (widget.navigationShell.currentIndex == 1) return;

    bool isLike(Object? v) => v?.toString() == 'like';

    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;
    final newTarget = newRecord['target_id']?.toString();
    final oldTarget = oldRecord['target_id']?.toString();

    var delta = 0;
    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        if (newTarget == uid && isLike(newRecord['swipe'])) {
          delta = 1;
        }
        break;
      case PostgresChangeEvent.delete:
        if (oldTarget == uid && isLike(oldRecord['swipe'])) {
          delta = -1;
        }
        break;
      case PostgresChangeEvent.update:
        final oldLiked = oldTarget == uid && isLike(oldRecord['swipe']);
        final newLiked = newTarget == uid && isLike(newRecord['swipe']);
        if (!oldLiked && newLiked) delta = 1;
        if (oldLiked && !newLiked) delta = -1;
        break;
      case PostgresChangeEvent.all:
        break;
    }

    if (delta != 0) {
      setState(() {
        final next = _incomingLikesUnreadCount + delta;
        _incomingLikesUnreadCount = next < 0 ? 0 : next;
      });
    }
    _refreshIncomingLikesUnreadCount(uid);
  }

  Future<void> _loadSeenAndRefresh(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_likesSeenKey(uid));
      _likesSeenAtUtc = raw == null ? null : DateTime.tryParse(raw)?.toUtc();
    } catch (_) {
      _likesSeenAtUtc = null;
    }
    if (!mounted) return;
    if (widget.navigationShell.currentIndex == 1) {
      await _markLikesSeen(uid);
      return;
    }
    await _refreshIncomingLikesUnreadCount(uid);
  }

  Future<void> _refreshIncomingLikesUnreadCount(String uid) async {
    try {
      final raw = await Supabase.instance.client.rpc<dynamic>(
        'get_who_liked_me_unread_count',
        params: {
          'p_seen_at': _likesSeenAtUtc?.toIso8601String(),
        },
      );
      final count = raw is num ? raw.toInt() : 0;
      if (mounted) setState(() => _incomingLikesUnreadCount = count);
    } catch (_) {
      if (mounted) setState(() => _incomingLikesUnreadCount = 0);
    }
  }

  String _likesSeenKey(String uid) => 'likes_badge_seen_at_v1_$uid';

  Future<void> _markLikesSeen(String uid) async {
    final seen = DateTime.now().toUtc();
    _likesSeenAtUtc = seen;
    if (mounted) setState(() => _incomingLikesUnreadCount = 0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_likesSeenKey(uid), seen.toIso8601String());
    } catch (_) {}
  }

  void _onNavTap(BuildContext context, int index) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (index == 1 && uid != null) {
      // Opening Likes tab clears unread badge.
      _markLikesSeen(uid);
    } else if (uid != null) {
      _refreshIncomingLikesUnreadCount(uid);
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final l10n = context.l10n;

    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: widget.navigationShell,
      bottomNavigationBar: keyboardOpen
          ? null
          : BottomAppBar(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    selected: widget.navigationShell.currentIndex == 0,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: l10n.navHome,
                    onTap: () => _onNavTap(context, 0),
                  ),
                  _NavItem(
                    selected: widget.navigationShell.currentIndex == 1,
                    icon: Icons.favorite_border_rounded,
                    selectedIcon: Icons.favorite_rounded,
                    label: l10n.navLikes,
                    badgeCount: _incomingLikesUnreadCount,
                    onTap: () => _onNavTap(context, 1),
                  ),
                  _NavItem(
                    selected: widget.navigationShell.currentIndex == 2,
                    icon: Icons.waving_hand_outlined,
                    selectedIcon: Icons.waving_hand_rounded,
                    label: l10n.navSayHi,
                    onTap: () => _onNavTap(context, 2),
                  ),
                  _NavItem(
                    selected: widget.navigationShell.currentIndex == 3,
                    icon: Icons.chat_bubble_outline_rounded,
                    selectedIcon: Icons.chat_bubble_rounded,
                    label: l10n.navChats,
                    onTap: () => _onNavTap(context, 3),
                  ),
                  _NavItem(
                    selected: widget.navigationShell.currentIndex == 4,
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: l10n.navProfile,
                    onTap: () => _onNavTap(context, 4),
                  ),
                ],
              ),
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
