import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/model/zone_member_profile_detail.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Full-screen profile opened from the zone lobby grid.
class ZoneMemberProfileScreen extends StatefulWidget {
  const ZoneMemberProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<ZoneMemberProfileScreen> createState() => _ZoneMemberProfileScreenState();
}

class _ZoneMemberProfileScreenState extends State<ZoneMemberProfileScreen> {
  final ZoneRepository _repo = ZoneRepository();
  final PageController _pageController = PageController();

  ZoneMemberProfileDetail? _detail;
  Object? _error;
  bool _loading = true;
  int _photoIndex = 0;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final zoneId = ActiveZoneSession.current?['id'] as String?;
    if (zoneId == null || zoneId.isEmpty) {
      setState(() {
        _loading = false;
        _error = Exception('no zone');
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _repo.fetchZoneMemberProfileDetail(
        zoneId: zoneId,
        targetUserId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _persist(ZoneMemberProfileDetail next, {bool popOnSuccess = false}) async {
    setState(() {
      _detail = next;
      _saving = true;
    });
    try {
      await _repo.upsertProfileInteraction(
        targetUserId: widget.userId,
        swipe: next.swipe,
        isFavorite: next.isFavorite,
      );
      if (popOnSuccess && mounted) {
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.zoneMemberProfileSaveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onLike() {
    final d = _detail;
    if (d == null) return;
    final nextSwipe = d.swipe == 'like' ? null : 'like';
    _persist(ZoneMemberProfileDetail(
      userId: d.userId,
      name: d.name,
      bio: d.bio,
      age: d.age,
      gender: d.gender,
      country: d.country,
      avatarUrl: d.avatarUrl,
      galleryUrls: d.galleryUrls,
      swipe: nextSwipe,
      isFavorite: d.isFavorite,
    ), popOnSuccess: true);
  }

  void _onDislike() {
    final d = _detail;
    if (d == null) return;
    final nextSwipe = d.swipe == 'dislike' ? null : 'dislike';
    _persist(ZoneMemberProfileDetail(
      userId: d.userId,
      name: d.name,
      bio: d.bio,
      age: d.age,
      gender: d.gender,
      country: d.country,
      avatarUrl: d.avatarUrl,
      galleryUrls: d.galleryUrls,
      swipe: nextSwipe,
      isFavorite: d.isFavorite,
    ), popOnSuccess: true);
  }

  void _onFavorite() {
    final d = _detail;
    if (d == null) return;
    _persist(ZoneMemberProfileDetail(
      userId: d.userId,
      name: d.name,
      bio: d.bio,
      age: d.age,
      gender: d.gender,
      country: d.country,
      avatarUrl: d.avatarUrl,
      galleryUrls: d.galleryUrls,
      swipe: d.swipe,
      isFavorite: !d.isFavorite,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final onMuted = colorScheme.onSurface.withValues(alpha: 0.62);

    if (_loading) {
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

    if (_error != null || _detail == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 48, color: onMuted),
                const SizedBox(height: 16),
                Text(
                  l10n.zoneMemberProfileLoadError,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: onMuted),
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: _load,
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = _detail!;
    var photos = List<String>.from(d.allPhotoUrls);
    if (photos.isEmpty) photos = [''];
    final title = d.age != null ? '${d.name}, ${d.age}' : d.name;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: l10n.zoneMemberProfileFavoriteTooltip,
            onPressed: _saving ? null : _onFavorite,
            icon: Icon(
              d.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 26,
              color: d.isFavorite
                  ? const Color(0xFF29B6F6)
                  : colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 360,
                child: photos.length == 1
                    ? _ProfilePhotoTile(url: photos.first, borderColor: _borderColorForGender(colorScheme, d.gender))
                    : PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) => setState(() => _photoIndex = i),
                        itemCount: photos.length,
                        itemBuilder: (context, i) {
                          return _ProfilePhotoTile(
                            url: photos[i],
                            borderColor: _borderColorForGender(colorScheme, d.gender),
                          );
                        },
                      ),
              ),
            ),
            if (photos.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (i) {
                  final active = i == _photoIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: active
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.35),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 24),
            if (d.country != null && d.country!.trim().isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    d.country!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Text(
              l10n.zoneMemberProfileAbout,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              d.bio.isEmpty ? l10n.zoneMainMemberBioPlaceholder : d.bio,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.45,
                color: colorScheme.onSurface.withValues(alpha: 0.88),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _saving ? null : _onLike,
                    icon: Icon(
                      Icons.favorite_rounded,
                      size: 22,
                      color: d.swipe == 'like'
                          ? const Color(0xFFE91E63)
                          : colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    label: Text(l10n.zoneMemberProfileLike),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: d.swipe == 'like'
                          ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _saving ? null : _onDislike,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 24,
                      color: d.swipe == 'dislike'
                          ? colorScheme.error
                          : colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    label: Text(l10n.zoneMemberProfileDislike),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: d.swipe == 'dislike'
                          ? colorScheme.errorContainer.withValues(alpha: 0.45)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.zoneMemberProfileMessageSoon)),
                );
                context.go(AppRouter.chatsPath);
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(l10n.zoneMemberProfileSendMessage),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _borderColorForGender(ColorScheme colorScheme, String? genderRaw) {
  final g = genderRaw?.trim().toLowerCase();
  if (g == 'female' || g == 'f' || g == 'kadın' || g == 'kadin') {
    return const Color(0xFFFF6B8A);
  }
  if (g == 'male' || g == 'm' || g == 'erkek') {
    return const Color(0xFF42A5F5);
  }
  return colorScheme.outline.withValues(alpha: 0.12);
}

class _ProfilePhotoTile extends StatelessWidget {
  const _ProfilePhotoTile({
    required this.url,
    required this.borderColor,
  });

  final String url;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final has = url.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
      ),
      child: has
          ? Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.person_rounded, size: 64, color: colorScheme.outline),
              ),
            )
          : ColoredBox(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(Icons.person_rounded, size: 64, color: colorScheme.outline),
            ),
    );
  }
}
