import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/home/data/story_repository.dart';
import 'package:qr_dating_app/features/home/presentation/model/story_group.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/home_story_strip.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/recent_zones_card.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/zone_preview_card.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';

class HomeScreen extends StatefulWidget {
  final String? activeZoneName;
  final int? activeUserCount;
  final String? activeZoneImageUrl;

  const HomeScreen({
    super.key,
    this.activeZoneName,
    this.activeUserCount,
    this.activeZoneImageUrl,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ZoneRepository _zoneRepository = ZoneRepository();
  final StoryRepository _storyRepository = StoryRepository();

  late Future<List<StoryGroup>> _storyFuture;
  late Future<Map<String, dynamic>?> _activeZoneFuture;
  late Future<List<Map<String, dynamic>>> _recentZonesFuture;

  @override
  void initState() {
    super.initState();
    _storyFuture = _storyRepository.fetchStoryGroups();
    _activeZoneFuture = _zoneRepository.fetchCurrentActiveZone();
    _recentZonesFuture = _zoneRepository.fetchRecentZones(limit: 6);
  }

  void _reloadStoriesOnly() {
    setState(() {
      _storyFuture = _storyRepository.fetchStoryGroups();
    });
  }

  Future<void> _onRefresh() async {
    final story = _storyRepository.fetchStoryGroups();
    final active = _zoneRepository.fetchCurrentActiveZone();
    final recent = _zoneRepository.fetchRecentZones(limit: 6);
    setState(() {
      _storyFuture = story;
      _activeZoneFuture = active;
      _recentZonesFuture = recent;
    });
    await Future.wait<Object?>([story, active, recent]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Say Hi',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                HomeStoryStrip(
                  groupsFuture: _storyFuture,
                  onStoriesChanged: _reloadStoriesOnly,
                ),
                const SizedBox(height: 20),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _activeZoneFuture,
                  builder: (context, snapshot) {
                    final zone = snapshot.data;
                    final fallbackName = widget.activeZoneName;
                    final hasZone =
                        (zone?['name'] as String?)?.isNotEmpty == true ||
                        (fallbackName?.isNotEmpty == true);
                    return ZonePreviewCard(
                      activeZoneName: (zone?['name'] as String?) ?? fallbackName,
                      activeUserCount:
                          (zone?['activeCount'] as int?) ?? widget.activeUserCount,
                      venueImageUrl:
                          (zone?['imageUrl'] as String?) ?? widget.activeZoneImageUrl,
                      activeUntil: zone?['activeUntil'] as String?,
                      isActiveNow: zone?['isActiveNow'] as bool?,
                      onTap: hasZone
                          ? () => context.push(AppRouter.zoneMainPath)
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _recentZonesFuture,
                  builder: (context, snapshot) {
                    final zones = snapshot.data ?? const <Map<String, dynamic>>[];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (zones.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return RecentZonesCard(zones: zones);
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
