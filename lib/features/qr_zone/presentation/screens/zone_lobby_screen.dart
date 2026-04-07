import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/features/home/data/discovery_filters_storage.dart';
import 'package:qr_dating_app/features/home/presentation/model/swipe_profile.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/discovery_filter_sheet.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/model/zone_member_preview.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/widgets/zone_icebreaker_game.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source and chrome for [ZoneLobbyScreen].
enum ZoneLobbyVariant {
  /// Active zone session (venue lobby).
  inZone,

  /// Say Hi tab: global browse + discovery filters.
  sayHi,

  /// Likes tab: profiles the viewer has liked.
  likes,

  /// Favorites tab: profiles the viewer marked as favorite.
  favorites,
}

/// Lobby: member grid with lazy loading, icebreaker when empty, realtime updates.
class ZoneLobbyScreen extends StatefulWidget {
  const ZoneLobbyScreen({super.key, this.variant = ZoneLobbyVariant.inZone});

  final ZoneLobbyVariant variant;

  @override
  State<ZoneLobbyScreen> createState() => _ZoneLobbyScreenState();
}

class _ZoneLobbyScreenState extends State<ZoneLobbyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ZoneRepository _repo = ZoneRepository();
  final DiscoveryFiltersStorage _discoveryFiltersStorage = DiscoveryFiltersStorage();
  final ScrollController _scrollController = ScrollController();

  RealtimeChannel? _realtimeChannel;
  bool _fetchingProfilesAfterIcebreaker = false;
  bool _icebreakerSessionComplete = false;

  bool _loadingInitial = true;
  Object? _loadError;
  int _activeCount = 0;
  final List<ZoneMemberPreview> _members = [];
  bool _hasMore = true;
  bool _loadingMore = false;

  ZoneLobbyFilters _appliedFilters = ZoneLobbyFilters.none;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scrollController.addListener(_onScroll);

    switch (widget.variant) {
      case ZoneLobbyVariant.sayHi:
        _initStandaloneSayHi();
        break;
      case ZoneLobbyVariant.likes:
        _loadFirstPageLikes();
        break;
      case ZoneLobbyVariant.favorites:
        _loadFirstPageFavorites();
        break;
      case ZoneLobbyVariant.inZone:
        final zoneId = ActiveZoneSession.current?['id'] as String?;
        if (zoneId != null && zoneId.isNotEmpty) {
          _loadFirstPage(zoneId);
          _attachRealtime(zoneId);
        }
        break;
    }
  }

  Future<void> _initStandaloneSayHi() async {
    final stored = await _discoveryFiltersStorage.load();
    if (!mounted) return;
    setState(() => _appliedFilters = stored);
    await _loadFirstPageStandalone();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_loadingInitial || _loadingMore || !_hasMore || _members.isEmpty) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.maxScrollExtent - pos.pixels < 420) {
      switch (widget.variant) {
        case ZoneLobbyVariant.sayHi:
          _loadMoreStandalone();
          break;
        case ZoneLobbyVariant.likes:
          _loadMoreLikes();
          break;
        case ZoneLobbyVariant.favorites:
          _loadMoreFavorites();
          break;
        case ZoneLobbyVariant.inZone:
          final zoneId = ActiveZoneSession.current?['id'] as String?;
          if (zoneId != null && zoneId.isNotEmpty) {
            _loadMore(zoneId);
          }
          break;
      }
    }
  }

  Future<void> _loadFirstPage(String zoneId) async {
    setState(() => _loadError = null);
    try {
      final page = await _repo.fetchZoneMemberPreviewsPage(
        zoneId,
        offset: 0,
        filters: _appliedFilters,
      );
      if (!mounted) return;
      setState(() {
        _members
          ..clear()
          ..addAll(page.members);
        _activeCount = page.activeCount;
        _hasMore = page.hasMore;
        _loadingInitial = false;
        _fetchingProfilesAfterIcebreaker = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final notInZone =
          msg.contains('NOT_IN_ZONE') || msg.contains('not in zone');
      if (notInZone) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ActiveZoneSession.clear();
          if (context.mounted) context.go(AppRouter.homePath);
        });
        return;
      }
      setState(() {
        _loadError = e;
        _loadingInitial = false;
        _fetchingProfilesAfterIcebreaker = false;
      });
    }
  }

  Future<void> _loadFirstPageStandalone() async {
    setState(() => _loadError = null);
    try {
      final page = await _repo.fetchSayHiMemberPreviewsPage(
        offset: 0,
        filters: _appliedFilters,
      );
      if (!mounted) return;
      setState(() {
        _members
          ..clear()
          ..addAll(page.members);
        _activeCount = page.activeCount;
        _hasMore = page.hasMore;
        _loadingInitial = false;
        _fetchingProfilesAfterIcebreaker = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loadingInitial = false;
        _fetchingProfilesAfterIcebreaker = false;
      });
    }
  }

  Future<void> _loadMoreStandalone() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.fetchSayHiMemberPreviewsPage(
        offset: _members.length,
        filters: _appliedFilters,
      );
      if (!mounted) return;
      setState(() {
        _members.addAll(page.members);
        _activeCount = page.activeCount;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadFirstPageLikes() async {
    setState(() => _loadError = null);
    try {
      final page = await _repo.fetchLikedMemberPreviewsPage(offset: 0);
      if (!mounted) return;
      setState(() {
        _members
          ..clear()
          ..addAll(page.members);
        _activeCount = page.activeCount;
        _hasMore = page.hasMore;
        _loadingInitial = false;
        _fetchingProfilesAfterIcebreaker = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loadingInitial = false;
        _fetchingProfilesAfterIcebreaker = false;
      });
    }
  }

  Future<void> _loadMoreLikes() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.fetchLikedMemberPreviewsPage(
        offset: _members.length,
      );
      if (!mounted) return;
      setState(() {
        _members.addAll(page.members);
        _activeCount = page.activeCount;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadFirstPageFavorites() async {
    setState(() => _loadError = null);
    try {
      final page = await _repo.fetchFavoritedMemberPreviewsPage(offset: 0);
      if (!mounted) return;
      setState(() {
        _members
          ..clear()
          ..addAll(page.members);
        _activeCount = page.activeCount;
        _hasMore = page.hasMore;
        _loadingInitial = false;
        _fetchingProfilesAfterIcebreaker = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loadingInitial = false;
        _fetchingProfilesAfterIcebreaker = false;
      });
    }
  }

  Future<void> _loadMoreFavorites() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.fetchFavoritedMemberPreviewsPage(
        offset: _members.length,
      );
      if (!mounted) return;
      setState(() {
        _members.addAll(page.members);
        _activeCount = page.activeCount;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadMore(String zoneId) async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.fetchZoneMemberPreviewsPage(
        zoneId,
        offset: _members.length,
        filters: _appliedFilters,
      );
      if (!mounted) return;
      setState(() {
        _members.addAll(page.members);
        _activeCount = page.activeCount;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _attachRealtime(String zoneId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('zone_members_$zoneId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'zone_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'zone_id',
            value: zoneId,
          ),
          callback: (_) {
            if (!mounted) return;
            _loadFirstPage(zoneId);
          },
        )
      ..subscribe();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _realtimeChannel?.unsubscribe();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _leaveZone() async {
    final zoneId = ActiveZoneSession.current?['id'] as String?;
    if (zoneId == null || zoneId.isEmpty) {
      ActiveZoneSession.clear();
      if (mounted) context.go(AppRouter.homePath);
      return;
    }
    try {
      await _repo.leaveZone(zoneId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.zoneMainLeaveError)),
      );
      return;
    }
    ActiveZoneSession.clear();
    if (mounted) context.go(AppRouter.homePath);
  }

  Future<void> _onRefresh(String? zoneId) async {
    setState(() => _fetchingProfilesAfterIcebreaker = false);
    switch (widget.variant) {
      case ZoneLobbyVariant.sayHi:
        await _loadFirstPageStandalone();
        break;
      case ZoneLobbyVariant.likes:
        await _loadFirstPageLikes();
        break;
      case ZoneLobbyVariant.favorites:
        await _loadFirstPageFavorites();
        break;
      case ZoneLobbyVariant.inZone:
        if (zoneId != null && zoneId.isNotEmpty) {
          await _loadFirstPage(zoneId);
        }
        break;
    }
  }

  void _onIcebreakerComplete(String zoneId) {
    setState(() {
      _icebreakerSessionComplete = true;
      _fetchingProfilesAfterIcebreaker = true;
    });
    _loadFirstPage(zoneId);
  }

  Future<void> _onMemberSwipeCommitted(
    String memberId,
    String swipe,
  ) async {
    try {
      await _repo.setProfileSwipe(targetUserId: memberId, swipe: swipe);
      if (!mounted) return;
      setState(() => _members.removeWhere((e) => e.id == memberId));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.zoneMemberProfileSaveError)),
      );
      rethrow;
    }
  }

  Future<void> _openMemberProfile(ZoneMemberPreview member, {required bool standalone}) async {
    if (standalone) {
      await context.push(
        AppRouter.discoveryProfilePath,
        extra: SwipeProfile(
          id: member.id,
          photoUrl: member.photoUrl,
          name: member.name,
          age: member.age,
          bio: member.bio,
          gender: member.gender,
          galleryUrls: const [],
        ),
      );
    } else {
      await context.push(AppRouter.zoneMemberProfilePath(member.id));
    }

    if (!mounted) return;
    if (widget.variant != ZoneLobbyVariant.likes &&
        widget.variant != ZoneLobbyVariant.favorites) {
      return;
    }

    try {
      final interaction = await _repo.fetchProfileInteractionForTarget(member.id);
      if (!mounted) return;
      final idx = _members.indexWhere((e) => e.id == member.id);
      if (idx < 0) return;

      final shouldRemove = switch (widget.variant) {
        ZoneLobbyVariant.likes => interaction?.swipe != 'like',
        ZoneLobbyVariant.favorites => interaction?.isFavorite != true,
        _ => false,
      };
      if (!shouldRemove) return;

      setState(() => _members.removeAt(idx));
      if (_members.isEmpty && _hasMore) {
        switch (widget.variant) {
          case ZoneLobbyVariant.likes:
            await _loadFirstPageLikes();
            break;
          case ZoneLobbyVariant.favorites:
            await _loadFirstPageFavorites();
            break;
          default:
            break;
        }
      }
    } catch (_) {
      // Keep list as-is if interaction check fails.
    }
  }

  Future<void> _openFilterSheet() async {
    if (widget.variant == ZoneLobbyVariant.sayHi) {
      final result = await showModalBottomSheet<ZoneLobbyFilters>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => DiscoveryFilterSheet(initial: _appliedFilters),
      );
      if (!mounted || result == null) return;
      setState(() => _appliedFilters = result);
      await _discoveryFiltersStorage.save(result);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
      await _loadFirstPageStandalone();
      return;
    }

    final result = await showModalBottomSheet<ZoneLobbyFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _LobbyFilterSheet(initial: _appliedFilters),
    );
    if (!mounted || result == null) return;
    setState(() => _appliedFilters = result);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    final zoneId = ActiveZoneSession.current?['id'] as String?;
    if (zoneId != null && zoneId.isNotEmpty) {
      await _loadFirstPage(zoneId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final onSurfaceMuted = colorScheme.onSurface.withValues(alpha: 0.62);
    final surfaceCard = colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

    if (widget.variant == ZoneLobbyVariant.likes) {
      final headerCount = _loadingInitial ? 0 : _activeCount;
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.likesTabTitle,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.6,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                FadeTransition(
                                  opacity: Tween<double>(begin: 0.45, end: 1).animate(
                                    CurvedAnimation(
                                      parent: _pulseController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent.shade400,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withValues(alpha: 0.45),
                                          blurRadius: 6,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.zoneMainActiveNow(headerCount),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: onSurfaceMuted,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(
                  context,
                  zoneId: null,
                  theme: theme,
                  onSurfaceMuted: onSurfaceMuted,
                  surfaceCard: surfaceCard,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.variant == ZoneLobbyVariant.favorites) {
      final headerCount = _loadingInitial ? 0 : _activeCount;
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.favoritesTabTitle,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.6,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                FadeTransition(
                                  opacity: Tween<double>(begin: 0.45, end: 1).animate(
                                    CurvedAnimation(
                                      parent: _pulseController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent.shade400,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withValues(alpha: 0.45),
                                          blurRadius: 6,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.zoneMainActiveNow(headerCount),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: onSurfaceMuted,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(
                  context,
                  zoneId: null,
                  theme: theme,
                  onSurfaceMuted: onSurfaceMuted,
                  surfaceCard: surfaceCard,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.variant == ZoneLobbyVariant.sayHi) {
      final headerCount = _loadingInitial ? 0 : _activeCount;
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.navSayHi,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.6,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                FadeTransition(
                                  opacity: Tween<double>(begin: 0.45, end: 1).animate(
                                    CurvedAnimation(
                                      parent: _pulseController,
                                      curve: Curves.easeInOut,
                                    ),
                                  ),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.greenAccent.shade400,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withValues(alpha: 0.45),
                                          blurRadius: 6,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.zoneMainActiveNow(headerCount),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: onSurfaceMuted,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Badge(
                      isLabelVisible: _appliedFilters.hasAny,
                      smallSize: 8,
                      child: IconButton(
                        tooltip: l10n.zoneLobbyFilterTooltip,
                        onPressed: _openFilterSheet,
                        icon: const Icon(Icons.tune_rounded, size: 22),
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(
                  context,
                  zoneId: null,
                  theme: theme,
                  onSurfaceMuted: onSurfaceMuted,
                  surfaceCard: surfaceCard,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final zone = ActiveZoneSession.current!;
    final venueName = zone['name'] as String? ?? l10n.defaultVenueName;
    final zoneId = (zone['id'] as String?)?.trim();

    final headerCount =
        _loadingInitial ? ((zone['activeCount'] as int?) ?? 0) : _activeCount;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _leaveZone,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(l10n.zoneMainLeaveZone),
        elevation: 0,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRouter.zoneMainPath);
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.zoneLobbyTitle,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: onSurfaceMuted,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            venueName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.6,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              FadeTransition(
                                opacity: Tween<double>(begin: 0.45, end: 1).animate(
                                  CurvedAnimation(
                                    parent: _pulseController,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.greenAccent.shade400,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.greenAccent.withValues(alpha: 0.45),
                                        blurRadius: 6,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.zoneMainActiveNow(headerCount),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: onSurfaceMuted,
                                  letterSpacing: 0.2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (zoneId != null && zoneId.isNotEmpty)
                    Badge(
                      isLabelVisible: _appliedFilters.hasAny,
                      smallSize: 8,
                      child: IconButton(
                        tooltip: l10n.zoneLobbyFilterTooltip,
                        onPressed: _openFilterSheet,
                        icon: const Icon(Icons.tune_rounded, size: 22),
                        style: IconButton.styleFrom(
                          foregroundColor: colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: zoneId == null || zoneId.isEmpty
                  ? _ZoneErrorState(
                      message: l10n.zoneMainMissingZoneId,
                      onSurfaceMuted: onSurfaceMuted,
                      onRetry: null,
                    )
                  : _buildBody(
                      context,
                      zoneId: zoneId,
                      theme: theme,
                      onSurfaceMuted: onSurfaceMuted,
                      surfaceCard: surfaceCard,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required String? zoneId,
    required ThemeData theme,
    required Color onSurfaceMuted,
    required Color surfaceCard,
  }) {
    final l10n = context.l10n;
    final standalone = zoneId == null;

    if (_loadingInitial || _fetchingProfilesAfterIcebreaker) {
      if (_fetchingProfilesAfterIcebreaker) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 36,
                width: 36,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.zoneMainFetchingProfiles,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: onSurfaceMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_loadError != null) {
      return _ZoneErrorState(
        message: l10n.zoneMainLoadError,
        retryLabel: l10n.commonRetry,
        onSurfaceMuted: onSurfaceMuted,
        onRetry: () {
          setState(() {
            _loadingInitial = true;
            _loadError = null;
          });
          switch (widget.variant) {
            case ZoneLobbyVariant.sayHi:
              _loadFirstPageStandalone();
              break;
            case ZoneLobbyVariant.likes:
              _loadFirstPageLikes();
              break;
            case ZoneLobbyVariant.favorites:
              _loadFirstPageFavorites();
              break;
            case ZoneLobbyVariant.inZone:
              _loadFirstPage(zoneId!);
              break;
          }
        },
      );
    }

    if (_members.isEmpty) {
      if (_appliedFilters.hasAny && widget.variant == ZoneLobbyVariant.sayHi) {
        return RefreshIndicator(
          onRefresh: () => _onRefresh(zoneId),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: true,
                child: _FilterEmptyState(
                  onSurfaceMuted: onSurfaceMuted,
                  onClearFilters: () {
                    setState(() => _appliedFilters = ZoneLobbyFilters.none);
                    _loadFirstPageStandalone();
                  },
                ),
              ),
            ],
          ),
        );
      }
      if (widget.variant == ZoneLobbyVariant.likes) {
        return RefreshIndicator(
          onRefresh: () => _onRefresh(zoneId),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: true,
                child: _LikesEmptyState(onSurfaceMuted: onSurfaceMuted),
              ),
            ],
          ),
        );
      }
      if (widget.variant == ZoneLobbyVariant.favorites) {
        return RefreshIndicator(
          onRefresh: () => _onRefresh(zoneId),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: true,
                child: _FavoritesEmptyState(onSurfaceMuted: onSurfaceMuted),
              ),
            ],
          ),
        );
      }
      if (widget.variant == ZoneLobbyVariant.sayHi) {
        return RefreshIndicator(
          onRefresh: () => _onRefresh(zoneId),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: true,
                child: _SayHiBrowseEmptyState(onSurfaceMuted: onSurfaceMuted),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () => _onRefresh(zoneId),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: true,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _icebreakerSessionComplete
                    ? _EmptyAfterIcebreaker(
                        onSurfaceMuted: onSurfaceMuted,
                      )
                    : ZoneIcebreakerGame(
                        zoneId: zoneId!,
                        repository: _repo,
                        onIcebreakerComplete: () => _onIcebreakerComplete(zoneId),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _onRefresh(zoneId),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, standalone ? 24 : 88),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.68,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final m = _members[index];
                  return _SwipeableMemberCard(
                    key: ValueKey(m.id),
                    member: m,
                    surfaceCard: surfaceCard,
                    onSurfaceMuted: onSurfaceMuted,
                    onOpenProfile: () => _openMemberProfile(m, standalone: standalone),
                    onSwipeCommitted: (swipe) => _onMemberSwipeCommitted(m.id, swipe),
                  );
                },
                childCount: _members.length,
              ),
            ),
          ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 96, top: 8),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeableMemberCard extends StatefulWidget {
  const _SwipeableMemberCard({
    super.key,
    required this.member,
    required this.surfaceCard,
    required this.onSurfaceMuted,
    required this.onOpenProfile,
    required this.onSwipeCommitted,
  });

  final ZoneMemberPreview member;
  final Color surfaceCard;
  final Color onSurfaceMuted;
  final VoidCallback onOpenProfile;
  final Future<void> Function(String swipe) onSwipeCommitted;

  @override
  State<_SwipeableMemberCard> createState() => _SwipeableMemberCardState();
}

class _SwipeableMemberCardState extends State<_SwipeableMemberCard>
    with SingleTickerProviderStateMixin {
  static const double _kCommitThreshold = 56;
  static const double _kVelocity = 650;

  double _dragX = 0;
  late AnimationController _anim;
  Animation<double>? _tween;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _snapBack() async {
    if (_dragX == 0) return;
    final start = _dragX;
    _anim.duration = const Duration(milliseconds: 200);
    _tween = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _animating = true;
    void tick() {
      if (_tween != null) setState(() => _dragX = _tween!.value);
    }

    _tween!.addListener(tick);
    await _anim.forward(from: 0);
    _tween!.removeListener(tick);
    _animating = false;
    if (mounted) setState(() => _dragX = 0);
  }

  Future<void> _flyOffAndCommit(String swipe) async {
    final dir = swipe == 'like' ? 1.0 : -1.0;
    final start = _dragX;
    final end = dir * 420;
    _anim.duration = const Duration(milliseconds: 260);
    _tween = Tween<double>(begin: start, end: end).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeIn),
    );
    _animating = true;
    void tick() {
      if (_tween != null) setState(() => _dragX = _tween!.value);
    }

    _tween!.addListener(tick);
    await _anim.forward(from: 0);
    _tween!.removeListener(tick);
    _animating = false;
    try {
      await widget.onSwipeCommitted(swipe);
    } catch (_) {
      if (mounted) {
        setState(() => _dragX = 0);
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_animating) return;
    final v = details.velocity.pixelsPerSecond.dx;
    if (_dragX > _kCommitThreshold || v > _kVelocity) {
      _flyOffAndCommit('like');
    } else if (_dragX < -_kCommitThreshold || v < -_kVelocity) {
      _flyOffAndCommit('dislike');
    } else {
      _snapBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final likeOpacity = (_dragX > 0 ? (_dragX / 90).clamp(0.0, 1.0) : 0.0);
    final nopeOpacity = (_dragX < 0 ? (-_dragX / 90).clamp(0.0, 1.0) : 0.0);
    final rot = (_dragX * 0.002).clamp(-0.22, 0.22);

    return GestureDetector(
      onTap: _animating ? null : widget.onOpenProfile,
      onHorizontalDragUpdate: _animating
          ? null
          : (d) => setState(() => _dragX += d.delta.dx),
      onHorizontalDragEnd: _animating ? null : _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Transform.rotate(
          angle: rot,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _MemberCard(
                member: widget.member,
                surfaceCard: widget.surfaceCard,
                onSurfaceMuted: widget.onSurfaceMuted,
                onTap: null,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Transform.rotate(
                            angle: -math.pi / 18,
                            child: Opacity(
                              opacity: nopeOpacity,
                              child: _SwipeStamp(
                                label: 'NOPE',
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Transform.rotate(
                            angle: math.pi / 18,
                            child: Opacity(
                              opacity: likeOpacity,
                              child: _SwipeStamp(
                                label: 'LIKE',
                                color: Colors.greenAccent.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

class _LobbyFilterSheet extends StatefulWidget {
  const _LobbyFilterSheet({required this.initial});

  final ZoneLobbyFilters initial;

  @override
  State<_LobbyFilterSheet> createState() => _LobbyFilterSheetState();
}

class _LobbyFilterSheetState extends State<_LobbyFilterSheet> {
  String? _gender;
  bool _useAge = false;
  late RangeValues _ageRange;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _gender = i.gender;
    _useAge = i.minAge != null || i.maxAge != null;
    final lo = (i.minAge ?? 18).clamp(18, 99).toDouble();
    final hi = (i.maxAge ?? 99).clamp(18, 99).toDouble();
    _ageRange = RangeValues(lo <= hi ? lo : hi, lo <= hi ? hi : lo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final minLabel = _ageRange.start.round();
    final maxLabel = _ageRange.end.round();

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.zoneLobbyFilterTitle,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.zoneLobbyFilterGender,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(l10n.zoneLobbyFilterGenderAll),
                    selected: _gender == null,
                    onSelected: (_) => setState(() => _gender = null),
                  ),
                  FilterChip(
                    label: Text(l10n.zoneLobbyFilterGenderFemale),
                    selected: _gender == 'female',
                    onSelected: (_) => setState(() => _gender = 'female'),
                  ),
                  FilterChip(
                    label: Text(l10n.zoneLobbyFilterGenderMale),
                    selected: _gender == 'male',
                    onSelected: (_) => setState(() => _gender = 'male'),
                  ),
                  FilterChip(
                    label: Text(l10n.zoneLobbyFilterGenderOther),
                    selected: _gender == 'other',
                    onSelected: (_) => setState(() => _gender = 'other'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.zoneLobbyFilterAge,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.zoneLobbyFilterAgeToggle),
                value: _useAge,
                onChanged: (v) => setState(() => _useAge = v),
              ),
              if (_useAge) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$minLabel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$maxLabel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 99,
                  divisions: 81,
                  labels: RangeLabels('$minLabel', '$maxLabel'),
                  onChanged: (v) => setState(() => _ageRange = v),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(ZoneLobbyFilters.none);
                      },
                      child: Text(l10n.zoneLobbyFilterClear),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          ZoneLobbyFilters(
                            gender: _gender,
                            minAge: _useAge ? _ageRange.start.round() : null,
                            maxAge: _useAge ? _ageRange.end.round() : null,
                          ),
                        );
                      },
                      child: Text(l10n.zoneLobbyFilterApply),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LikesEmptyState extends StatelessWidget {
  const _LikesEmptyState({required this.onSurfaceMuted});

  final Color onSurfaceMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 56, color: onSurfaceMuted),
            const SizedBox(height: 16),
            Text(
              l10n.likesTabPlaceholder,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: onSurfaceMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState({required this.onSurfaceMuted});

  final Color onSurfaceMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline_rounded, size: 56, color: onSurfaceMuted),
            const SizedBox(height: 16),
            Text(
              l10n.favoritesTabPlaceholder,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: onSurfaceMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SayHiBrowseEmptyState extends StatelessWidget {
  const _SayHiBrowseEmptyState({required this.onSurfaceMuted});

  final Color onSurfaceMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: onSurfaceMuted),
            const SizedBox(height: 16),
            Text(
              l10n.sayHiLobbyBrowseEmpty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: onSurfaceMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({
    required this.onSurfaceMuted,
    required this.onClearFilters,
  });

  final Color onSurfaceMuted;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 88),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_off_rounded, size: 48, color: onSurfaceMuted),
          const SizedBox(height: 16),
          Text(
            l10n.zoneLobbyFilterEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onSurfaceMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: onClearFilters,
            child: Text(l10n.zoneLobbyFilterClear),
          ),
        ],
      ),
    );
  }
}

class _EmptyAfterIcebreaker extends StatelessWidget {
  const _EmptyAfterIcebreaker({required this.onSurfaceMuted});

  final Color onSurfaceMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 88),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 48, color: onSurfaceMuted),
          const SizedBox(height: 16),
          Text(
            l10n.zoneMainEmptyAfterIcebreaker,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onSurfaceMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneErrorState extends StatelessWidget {
  const _ZoneErrorState({
    required this.message,
    required this.onSurfaceMuted,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final Color onSurfaceMuted;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: onSurfaceMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: onSurfaceMuted),
            ),
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(retryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Color zoneMemberBorderColor(ColorScheme colorScheme, String? genderRaw) {
  final g = genderRaw?.trim().toLowerCase();
  if (g == 'female' || g == 'f' || g == 'kadın' || g == 'kadin') {
    return const Color(0xFFFF6B8A);
  }
  if (g == 'male' || g == 'm' || g == 'erkek') {
    return const Color(0xFF42A5F5);
  }
  return colorScheme.outline.withValues(alpha: 0.12);
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.surfaceCard,
    required this.onSurfaceMuted,
    this.onTap,
  });

  final ZoneMemberPreview member;
  final Color surfaceCard;
  final Color onSurfaceMuted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final hasPhoto = member.photoUrl.isNotEmpty;
    final borderColor = zoneMemberBorderColor(colorScheme, member.gender);

    final content = Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasPhoto)
                        Image.network(
                          member.photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: onSurfaceMuted,
                            ),
                          ),
                        )
                      else
                        ColoredBox(
                          color: colorScheme.surfaceContainerHigh,
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: onSurfaceMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              member.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (member.age != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${member.age}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: onSurfaceMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          member.bio.isEmpty ? l10n.zoneMainMemberBioPlaceholder : member.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: onSurfaceMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );

    return Material(
      color: surfaceCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: colorScheme.primary.withValues(alpha: 0.08),
              child: content,
            ),
    );
  }
}
