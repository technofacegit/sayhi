import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/features/home/presentation/model/swipe_profile.dart';
import 'package:qr_dating_app/features/home/presentation/widgets/discovery_action_circle.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Full-screen profile opened from the home discovery card (photo tap).
class DiscoveryProfileScreen extends StatefulWidget {
  const DiscoveryProfileScreen({super.key, required this.profile});

  final SwipeProfile profile;

  @override
  State<DiscoveryProfileScreen> createState() => _DiscoveryProfileScreenState();
}

class _DiscoveryProfileScreenState extends State<DiscoveryProfileScreen> {
  final ZoneRepository _repo = ZoneRepository();
  final PageController _pageController = PageController();

  int _photoIndex = 0;
  String? _swipe;
  bool _isFavorite = false;
  bool _saving = false;
  bool _loadingInteraction = true;

  @override
  void initState() {
    super.initState();
    _loadInteraction();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInteraction() async {
    setState(() => _loadingInteraction = true);
    try {
      final row = await _repo.fetchProfileInteractionForTarget(widget.profile.id);
      if (!mounted) return;
      setState(() {
        if (row != null) {
          _swipe = row.swipe;
          _isFavorite = row.isFavorite;
        } else {
          _swipe = null;
          _isFavorite = false;
        }
        _loadingInteraction = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _swipe = null;
        _isFavorite = false;
        _loadingInteraction = false;
      });
    }
  }

  Future<void> _persist({required String? swipe, required bool isFavorite}) async {
    setState(() {
      _swipe = swipe;
      _isFavorite = isFavorite;
      _saving = true;
    });
    try {
      await _repo.upsertProfileInteraction(
        targetUserId: widget.profile.id,
        swipe: swipe,
        isFavorite: isFavorite,
      );
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
    if (_saving || _loadingInteraction) return;
    final nextSwipe = _swipe == 'like' ? null : 'like';
    _persist(swipe: nextSwipe, isFavorite: _isFavorite);
  }

  void _onDislike() {
    if (_saving || _loadingInteraction) return;
    final nextSwipe = _swipe == 'dislike' ? null : 'dislike';
    _persist(swipe: nextSwipe, isFavorite: _isFavorite);
  }

  void _onFavorite() {
    if (_saving || _loadingInteraction) return;
    _persist(swipe: _swipe, isFavorite: !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final p = widget.profile;
    var photos = List<String>.from(p.imageUrls);
    if (photos.length == 1 && photos.first.isEmpty) {
      photos = [''];
    }
    final title = p.age != null ? '${p.name}, ${p.age}' : p.name;
    final busy = _saving || _loadingInteraction;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _saving ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 360,
                      child: photos.length == 1
                          ? _DiscoveryPhotoTile(
                              url: photos.first,
                              borderColor: _borderColorForGender(colorScheme, p.gender),
                            )
                          : PageView.builder(
                              controller: _pageController,
                              onPageChanged: (i) => setState(() => _photoIndex = i),
                              itemCount: photos.length,
                              itemBuilder: (context, i) {
                                return _DiscoveryPhotoTile(
                                  url: photos[i],
                                  borderColor: _borderColorForGender(colorScheme, p.gender),
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
                  const SizedBox(height: 20),
                  Material(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.discoveryProfileDescription,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.bio.isEmpty ? l10n.zoneMainMemberBioPlaceholder : p.bio,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.45,
                              color: colorScheme.onSurface.withValues(alpha: 0.88),
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
          Material(
            elevation: 6,
            shadowColor: Colors.black26,
            color: colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Tooltip(
                      message: l10n.zoneMemberProfileDislike,
                      child: DiscoveryActionCircle(
                        color: colorScheme.error,
                        icon: Icons.close_rounded,
                        onTap: busy ? null : _onDislike,
                        emphasized: _swipe == 'dislike',
                      ),
                    ),
                    Tooltip(
                      message: l10n.zoneMemberProfileLike,
                      child: DiscoveryActionCircle(
                        color: Colors.greenAccent.shade700,
                        icon: Icons.favorite_rounded,
                        onTap: busy ? null : _onLike,
                        emphasized: _swipe == 'like',
                      ),
                    ),
                    Tooltip(
                      message: l10n.zoneMemberProfileFavoriteTooltip,
                      child: DiscoveryActionCircle(
                        color: const Color(0xFF29B6F6),
                        icon: _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        onTap: busy ? null : _onFavorite,
                        emphasized: _isFavorite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

class _DiscoveryPhotoTile extends StatelessWidget {
  const _DiscoveryPhotoTile({
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
