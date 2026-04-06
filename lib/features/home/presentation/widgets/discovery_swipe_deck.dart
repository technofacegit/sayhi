import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/home/presentation/model/swipe_profile.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Full-width card with horizontal swipe (like / pass) and optional action buttons.
class DiscoverySwipeDeck extends StatefulWidget {
  const DiscoverySwipeDeck({
    super.key,
    required this.profile,
    required this.onSwiped,
  });

  final SwipeProfile profile;
  final Future<void> Function(String swipe) onSwiped;

  @override
  State<DiscoverySwipeDeck> createState() => _DiscoverySwipeDeckState();
}

class _DiscoverySwipeDeckState extends State<DiscoverySwipeDeck>
    with SingleTickerProviderStateMixin {
  static const double _kCommitThreshold = 72;
  static const double _kVelocity = 600;

  double _dragX = 0;
  late AnimationController _anim;
  Animation<double>? _tween;
  bool _animating = false;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void didUpdateWidget(DiscoverySwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id) {
      _photoIndex = 0;
      _dragX = 0;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _stepPhoto(int delta, int urlCount) {
    if (urlCount <= 1 || _animating) return;
    setState(() {
      _photoIndex = (_photoIndex + delta) % urlCount;
      if (_photoIndex < 0) {
        _photoIndex += urlCount;
      }
    });
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
    final swipedProfileId = widget.profile.id;
    final dir = swipe == 'like' ? 1.0 : -1.0;
    final start = _dragX;
    final end = dir * 520;
    _anim.duration = const Duration(milliseconds: 280);
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
      await widget.onSwiped(swipe);
      if (!mounted) return;
      // If parent couldn't persist swipe, it keeps the same profile.
      // Bring the card back to center so it doesn't stay off-screen.
      if (widget.profile.id == swipedProfileId) {
        setState(() => _dragX = 0);
      }
    } catch (_) {
      if (mounted) setState(() => _dragX = 0);
    }
  }

  Future<void> _commitFromButton(String swipe) async {
    if (_animating) return;
    try {
      await widget.onSwiped(swipe);
    } catch (_) {
      // Parent shows snackbar
    }
  }

  /// Release after dragging: right → like (Tinder-style), left → dislike.
  void _onDragEnd(DragEndDetails details) {
    if (_animating) return;
    final v = details.velocity.pixelsPerSecond.dx;
    // Positive dx / velocity: finger moved right → like.
    if (_dragX > _kCommitThreshold || v > _kVelocity) {
      _flyOffAndCommit('like');
    } else if (_dragX < -_kCommitThreshold || v < -_kVelocity) {
      _flyOffAndCommit('dislike');
    } else {
      _snapBack();
    }
  }

  Color _borderForGender(ColorScheme cs, String? g) {
    final x = g?.trim().toLowerCase();
    if (x == 'female' || x == 'f' || x == 'kadın' || x == 'kadin') {
      return const Color(0xFFFF6B8A);
    }
    if (x == 'male' || x == 'm' || x == 'erkek') {
      return const Color(0xFF42A5F5);
    }
    return cs.outline.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final p = widget.profile;
    final urls = p.imageUrls;
    final urlCount = urls.length;
    final photoI = urlCount == 0 ? 0 : _photoIndex.clamp(0, urlCount - 1);
    final likeOpacity = (_dragX > 0 ? (_dragX / 100).clamp(0.0, 1.0) : 0.0);
    final nopeOpacity = (_dragX < 0 ? (-_dragX / 100).clamp(0.0, 1.0) : 0.0);
    final rot = (_dragX * 0.0012).clamp(-0.2, 0.2);
    final borderColor = _borderForGender(colorScheme, p.gender);
    final title = p.age != null ? '${p.name}, ${p.age}' : p.name;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
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
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // No [PageView]: it steals horizontal drags from the card swipe.
                            Builder(
                              builder: (context) {
                                final url = urls[photoI];
                                if (url.isEmpty) {
                                  return ColoredBox(
                                    color: colorScheme.surfaceContainerHigh,
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 80,
                                      color: colorScheme.outline,
                                    ),
                                  );
                                }
                                return Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) => ColoredBox(
                                    color: colorScheme.surfaceContainerHigh,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (urlCount > 1) ...[
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 100,
                                width: 52,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => _stepPhoto(-1, urlCount),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 100,
                                width: 52,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: () => _stepPhoto(1, urlCount),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ],
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.75),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      p.bio.isEmpty
                                          ? l10n.zoneMainMemberBioPlaceholder
                                          : p.bio,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.92),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (urlCount > 1)
                              Positioned(
                                top: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(urlCount, (i) {
                                    final active = i == photoI;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: active ? 20 : 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: active
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.4),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            IgnorePointer(
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Transform.rotate(
                                        angle: -math.pi / 20,
                                        child: Opacity(
                                          opacity: nopeOpacity,
                                          child: _Stamp(
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
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Transform.rotate(
                                        angle: math.pi / 20,
                                        child: Opacity(
                                          opacity: likeOpacity,
                                          child: _Stamp(
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Left button = pass, right = like (matches swipe directions).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionCircle(
              color: colorScheme.error,
              icon: Icons.close_rounded,
              onTap: _animating ? null : () => _commitFromButton('dislike'),
            ),
            _ActionCircle(
              color: Colors.greenAccent.shade700,
              icon: Icons.favorite_rounded,
              onTap: _animating ? null : () => _commitFromButton('like'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}
