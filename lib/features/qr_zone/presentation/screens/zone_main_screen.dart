import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Zone hub: pick Warm Up, Who is Game, or Lobby (profiles).
class ZoneMainScreen extends StatefulWidget {
  const ZoneMainScreen({super.key});

  @override
  State<ZoneMainScreen> createState() => _ZoneMainScreenState();
}

class _ZoneMainScreenState extends State<ZoneMainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ZoneRepository _repo = ZoneRepository();
  int? _liveActiveCount;
  bool _loadingCount = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadHeaderCount();
  }

  Future<void> _loadHeaderCount() async {
    final zoneId = ActiveZoneSession.current?['id'] as String?;
    if (zoneId == null || zoneId.isEmpty) return;
    setState(() => _loadingCount = true);
    try {
      final r = await _repo.fetchZoneMemberPreviews(zoneId);
      if (!mounted) return;
      setState(() {
        _liveActiveCount = r.activeCount;
        _loadingCount = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCount = false);
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final zone = ActiveZoneSession.current!;
    final venueName = zone['name'] as String? ?? l10n.defaultVenueName;
    final zoneId = (zone['id'] as String?)?.trim();
    final onSurfaceMuted = colorScheme.onSurface.withValues(alpha: 0.62);
    final activeCount = _liveActiveCount ?? (zone['activeCount'] as int? ?? 0);

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
        child: zoneId == null || zoneId.isEmpty
            ? Center(child: Text(l10n.zoneMainMissingZoneId))
            : RefreshIndicator(
                onRefresh: _loadHeaderCount,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
                      sliver: SliverToBoxAdapter(
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
                                foregroundColor:
                                    colorScheme.onSurface.withValues(alpha: 0.85),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.zoneHubHeadline,
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
                                          opacity: Tween<double>(begin: 0.45, end: 1)
                                              .animate(
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
                                                  color: Colors.greenAccent
                                                      .withValues(alpha: 0.45),
                                                  blurRadius: 6,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (_loadingCount && _liveActiveCount == null)
                                          SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: onSurfaceMuted,
                                            ),
                                          )
                                        else
                                          Text(
                                            l10n.zoneMainActiveNow(activeCount),
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
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _ZoneModeCard(
                            icon: Icons.local_fire_department_rounded,
                            title: l10n.zoneModeWarmUp,
                            subtitle: l10n.zoneModeWarmUpSubtitle,
                            accent: colorScheme.primary,
                            onTap: () => context.push(AppRouter.zoneWarmUpPath),
                          ),
                          const SizedBox(height: 12),
                          _ZoneModeCard(
                            icon: Icons.help_outline_rounded,
                            title: l10n.zoneModeWhoIs,
                            subtitle: l10n.zoneModeWhoIsSubtitle,
                            accent: colorScheme.tertiary,
                            onTap: () => context.push(AppRouter.zoneWhoIsPath),
                          ),
                          const SizedBox(height: 12),
                          _ZoneModeCard(
                            icon: Icons.groups_rounded,
                            title: l10n.zoneModeLobby,
                            subtitle: l10n.zoneModeLobbySubtitle,
                            accent: colorScheme.secondary,
                            onTap: () => context.push(AppRouter.zoneLobbyPath),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ZoneModeCard extends StatelessWidget {
  const _ZoneModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurfaceMuted = colorScheme.onSurface.withValues(alpha: 0.65);

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onSurfaceMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
