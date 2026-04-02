import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/model/zone_member_preview.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/widgets/zone_icebreaker_game.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Zone home: venue header, member grid (Supabase), leave FAB.
class ZoneMainScreen extends StatefulWidget {
  const ZoneMainScreen({super.key});

  @override
  State<ZoneMainScreen> createState() => _ZoneMainScreenState();
}

class _ZoneMainScreenState extends State<ZoneMainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ZoneRepository _repo = ZoneRepository();
  Future<ZoneMemberPreviewsResult>? _membersFuture;
  RealtimeChannel? _realtimeChannel;
  bool _fetchingProfilesAfterIcebreaker = false;
  bool _icebreakerSessionComplete = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    final zoneId = ActiveZoneSession.current?['id'] as String?;
    if (zoneId != null && zoneId.isNotEmpty) {
      _membersFuture = _repo.fetchZoneMemberPreviews(zoneId);
      _attachRealtime(zoneId);
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
            setState(() {
              _membersFuture = _repo.fetchZoneMemberPreviews(zoneId);
            });
          },
        )
      ..subscribe();
  }

  @override
  void dispose() {
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

  Future<void> _onRefresh(String zoneId) async {
    setState(() {
      _fetchingProfilesAfterIcebreaker = false;
      _membersFuture = _repo.fetchZoneMemberPreviews(zoneId);
    });
    await _membersFuture;
  }

  void _onIcebreakerComplete(String zoneId) {
    setState(() {
      _icebreakerSessionComplete = true;
      _fetchingProfilesAfterIcebreaker = true;
      _membersFuture = _repo.fetchZoneMemberPreviews(zoneId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final zone = ActiveZoneSession.current!;
    final venueName = zone['name'] as String? ?? l10n.defaultVenueName;
    final zoneId = (zone['id'] as String?)?.trim();

    final onSurfaceMuted = colorScheme.onSurface.withValues(alpha: 0.62);
    final surfaceCard = colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);

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
                        context.go(AppRouter.homePath);
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
                              FutureBuilder<ZoneMemberPreviewsResult>(
                                future: _membersFuture,
                                builder: (context, snapshot) {
                                  final count = snapshot.hasData
                                      ? snapshot.data!.activeCount
                                      : ((zone['activeCount'] as int?) ?? 0);
                                  return Text(
                                    l10n.zoneMainActiveNow(count),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: onSurfaceMuted,
                                      letterSpacing: 0.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
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
                  : FutureBuilder<ZoneMemberPreviewsResult>(
                      future: _membersFuture,
                      builder: (context, snapshot) {
                        if (_fetchingProfilesAfterIcebreaker &&
                            snapshot.connectionState == ConnectionState.done) {
                          Future.microtask(() {
                            if (mounted && _fetchingProfilesAfterIcebreaker) {
                              setState(() => _fetchingProfilesAfterIcebreaker = false);
                            }
                          });
                        }
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            !snapshot.hasData) {
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
                        if (snapshot.hasError) {
                          final msg = snapshot.error.toString();
                          final notInZone =
                              msg.contains('NOT_IN_ZONE') || msg.contains('not in zone');
                          if (notInZone) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ActiveZoneSession.clear();
                              if (context.mounted) context.go(AppRouter.homePath);
                            });
                            return const SizedBox.shrink();
                          }
                          return _ZoneErrorState(
                            message: l10n.zoneMainLoadError,
                            retryLabel: l10n.commonRetry,
                            onSurfaceMuted: onSurfaceMuted,
                            onRetry: () {
                              setState(() {
                                _membersFuture = _repo.fetchZoneMemberPreviews(zoneId);
                              });
                            },
                          );
                        }
                        final data = snapshot.data!;
                        final members = data.members;
                        return RefreshIndicator(
                          onRefresh: () => _onRefresh(zoneId),
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              if (members.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: true,
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: _icebreakerSessionComplete
                                        ? _EmptyAfterIcebreaker(
                                            onSurfaceMuted: onSurfaceMuted,
                                          )
                                        : ZoneIcebreakerGame(
                                            zoneId: zoneId,
                                            repository: _repo,
                                            onIcebreakerComplete: () =>
                                                _onIcebreakerComplete(zoneId),
                                          ),
                                  ),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 14,
                                      crossAxisSpacing: 14,
                                      childAspectRatio: 0.68,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final m = members[index];
                                        return _MemberCard(
                                          member: m,
                                          surfaceCard: surfaceCard,
                                          onSurfaceMuted: onSurfaceMuted,
                                        );
                                      },
                                      childCount: members.length,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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

Color _zoneMemberBorderColor(ColorScheme colorScheme, String? genderRaw) {
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
  });

  final ZoneMemberPreview member;
  final Color surfaceCard;
  final Color onSurfaceMuted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final hasPhoto = member.photoUrl.isNotEmpty;
    final borderColor = _zoneMemberBorderColor(colorScheme, member.gender);

    return Material(
      color: surfaceCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        splashColor: colorScheme.primary.withValues(alpha: 0.08),
        child: Ink(
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
        ),
      ),
    );
  }
}
