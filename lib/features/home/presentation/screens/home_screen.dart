import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/home/data/discovery_filters_storage.dart';
import 'package:qr_dating_app/features/home/data/discovery_repository.dart';
import 'package:qr_dating_app/features/home/data/story_repository.dart';
import 'package:qr_dating_app/features/home/presentation/model/story_group.dart';
import 'package:qr_dating_app/features/home/presentation/model/swipe_profile.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/discovery_filter_sheet.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/discovery_swipe_deck.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/home_story_strip.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StoryRepository _storyRepository = StoryRepository();
  final DiscoveryRepository _discoveryRepository = DiscoveryRepository();
  final DiscoveryFiltersStorage _discoveryFiltersStorage = DiscoveryFiltersStorage();
  final ZoneRepository _zoneRepository = ZoneRepository();

  late Future<List<StoryGroup>> _storyFuture;

  List<SwipeProfile> _deck = [];
  bool _loadingDeck = true;
  Object? _deckError;
  ZoneLobbyFilters _discoveryFilters = ZoneLobbyFilters.none;

  @override
  void initState() {
    super.initState();
    _storyFuture = _storyRepository.fetchStoryGroups();
    _initDiscovery();
  }

  Future<void> _initDiscovery() async {
    final stored = await _discoveryFiltersStorage.load();
    if (!mounted) return;
    setState(() => _discoveryFilters = stored);
    await _loadDeck();
  }

  void _reloadStoriesOnly() {
    setState(() {
      _storyFuture = _storyRepository.fetchStoryGroups();
    });
  }

  Future<void> _loadDeck() async {
    setState(() {
      _loadingDeck = true;
      _deckError = null;
    });
    try {
      final list = await _discoveryRepository.fetchProfiles(
        limit: 30,
        filters: _discoveryFilters,
      );
      if (!mounted) return;
      setState(() {
        _deck = list;
        _loadingDeck = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _deckError = e;
        _loadingDeck = false;
      });
    }
  }

  Future<void> _prefetchMore() async {
    try {
      final more = await _discoveryRepository.fetchProfiles(
        limit: 24,
        filters: _discoveryFilters,
      );
      if (!mounted) return;
      final ids = _deck.map((e) => e.id).toSet();
      setState(() {
        for (final p in more) {
          if (!ids.contains(p.id)) {
            _deck.add(p);
            ids.add(p.id);
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _onSwiped(String swipe) async {
    if (_deck.isEmpty) return;
    try {
      final swiped = _deck.first;
      await _zoneRepository.setProfileSwipe(
        targetUserId: swiped.id,
        swipe: swipe,
      );
      if (!mounted) return;
      setState(() {
        _deck.removeAt(0);
        // Avoid a blank gap when the user swipes faster than fetch latency.
        if (_deck.isEmpty) _loadingDeck = true;
      });

      if (_deck.isEmpty) {
        await _loadDeck();
        return;
      }

      if (_deck.length < 8) {
        // Don't block the UI; queue up more cards in the background.
        // ignore: unawaited_futures
        _prefetchMore();
      }
    } catch (e, st) {
      debugPrint(
        '[HomeScreen._onSwiped] error (may be setState/_loadDeck/prefetch, not RPC): $e',
      );
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.zoneMemberProfileSaveError)),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    final story = _storyRepository.fetchStoryGroups();
    // Block body: arrow + assignment returns the Future from `=`, which breaks setState.
    setState(() {
      _storyFuture = story;
    });
    await Future.wait<void>([
      story.then((_) {}),
      _loadDeck(),
    ]);
  }

  Future<void> _openDiscoveryFilters() async {
    final result = await showModalBottomSheet<ZoneLobbyFilters>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DiscoveryFilterSheet(initial: _discoveryFilters),
    );
    if (!mounted || result == null) return;
    setState(() => _discoveryFilters = result);
    await _discoveryFiltersStorage.save(result);
    await _loadDeck();
  }

  Future<void> _openCurrentProfileDetail() async {
    if (_deck.isEmpty) return;
    final opened = _deck.first;
    final openedId = opened.id;
    await context.push(AppRouter.discoveryProfilePath, extra: opened);
    if (!mounted || _deck.isEmpty) return;
    if (_deck.first.id != openedId) return;

    try {
      final interaction = await _zoneRepository.fetchProfileInteractionForTarget(openedId);
      if (!mounted || _deck.isEmpty) return;
      if (_deck.first.id != openedId) return;
      if (interaction?.swipe != null) {
        setState(() {
          _deck.removeAt(0);
          if (_deck.isEmpty) _loadingDeck = true;
        });
        if (_deck.isEmpty) {
          await _loadDeck();
          return;
        }
        if (_deck.length < 8) {
          // ignore: unawaited_futures
          _prefetchMore();
        }
      }
    } catch (_) {
      // If we can't read interaction, keep current card unchanged.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final muted = colorScheme.onSurface.withValues(alpha: 0.62);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          l10n.homeTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Badge(
                          isLabelVisible: _discoveryFilters.hasAny,
                          smallSize: 8,
                          child: IconButton(
                            tooltip: l10n.zoneLobbyFilterTooltip,
                            onPressed: _openDiscoveryFilters,
                            icon: const Icon(Icons.tune_rounded, size: 22),
                            style: IconButton.styleFrom(
                              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HomeStoryStrip(
                    groupsFuture: _storyFuture,
                    onStoriesChanged: _reloadStoriesOnly,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // ScrollView gives the child unbounded max height; [minHeight] alone leaves max
                    // infinite so [DiscoverySwipeDeck]'s Column+Expanded gets zero flex space → empty card.
                    final h = constraints.maxHeight;
                    final deckHeight = h.isFinite && h > 0 ? h : 400.0;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: deckHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildDeckBody(theme, muted),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckBody(ThemeData theme, Color muted) {
    final l10n = context.l10n;
    if (_loadingDeck) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_deckError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: muted),
              const SizedBox(height: 12),
              Text(
                l10n.homeDiscoveryLoadError,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: muted),
              ),
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: _loadDeck,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (_deck.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 52, color: muted),
              const SizedBox(height: 16),
              Text(
                l10n.homeDiscoveryEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: muted, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return DiscoverySwipeDeck(
      key: ValueKey(_deck.first.id),
      profile: _deck.first,
      onSwiped: _onSwiped,
      onPhotoTap: _openCurrentProfileDetail,
    );
  }
}
