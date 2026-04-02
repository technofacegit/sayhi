import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/model/who_is_game_round.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Who Is: RPC round with 3 synthetic profiles; pick the one that matches the clue.
String _whoIsErrorDetail(Object? e) {
  if (e == null) return '';
  var s = e.toString();
  const p = 'Exception: ';
  if (s.startsWith(p)) {
    s = s.substring(p.length);
  }
  return s.trim();
}

class ZoneWhoIsGameScreen extends StatefulWidget {
  const ZoneWhoIsGameScreen({super.key});

  @override
  State<ZoneWhoIsGameScreen> createState() => _ZoneWhoIsGameScreenState();
}

class _ZoneWhoIsGameScreenState extends State<ZoneWhoIsGameScreen> {
  final ZoneRepository _repo = ZoneRepository();
  WhoIsGameRound? _round;
  bool _loading = true;
  Object? _error;
  int? _selectedIndex;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _loadRound();
  }

  Future<void> _loadRound() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedIndex = null;
      _revealed = false;
      _round = null;
    });
    try {
      final r = await _repo.fetchWhoIsGameRound();
      if (!mounted) return;
      if (r.profiles.length != 3) {
        setState(() {
          _loading = false;
          _error = Exception('Invalid round');
        });
        return;
      }
      setState(() {
        _round = r;
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

  void _onPick(int index) {
    if (_revealed || _round == null) return;
    setState(() {
      _selectedIndex = index;
      _revealed = true;
    });
  }

  bool get _isWin =>
      _revealed &&
      _selectedIndex != null &&
      _round != null &&
      _selectedIndex == _round!.correctIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final zone = ActiveZoneSession.current;
    final venueName =
        (zone?['name'] as String?)?.trim().isNotEmpty == true
            ? zone!['name'] as String
            : l10n.defaultVenueName;
    final onSurfaceMuted = colorScheme.onSurface.withValues(alpha: 0.62);

    const correctGreen = Color(0xFF2E7D32);
    const wrongRed = Color(0xFFC62828);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
              child: Row(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.zoneWhoIsTitle,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          venueName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(
                context,
                theme: theme,
                colorScheme: colorScheme,
                onSurfaceMuted: onSurfaceMuted,
                correctGreen: correctGreen,
                wrongRed: wrongRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Color onSurfaceMuted,
    required Color correctGreen,
    required Color wrongRed,
  }) {
    final l10n = context.l10n;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      final detail = _whoIsErrorDetail(_error);
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.whoIsLoadError,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: onSurfaceMuted),
              ),
              if (detail.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurfaceMuted.withValues(alpha: 0.9),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadRound,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }
    final round = _round!;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.whoIsChooseHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurfaceMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    round.question,
                    style: theme.textTheme.titleSmall?.copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_revealed) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: _isWin
                        ? correctGreen.withValues(alpha: 0.12)
                        : wrongRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            _isWin ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                            color: _isWin ? correctGreen : wrongRed,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _isWin ? l10n.whoIsCorrect : l10n.whoIsWrongFeedback,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ...List.generate(3, (i) {
                  final p = round.profiles[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WhoIsProfileTile(
                      profile: p,
                      onTap: () => _onPick(i),
                      revealed: _revealed,
                      selectedIndex: _selectedIndex,
                      index: i,
                      correctIndex: round.correctIndex,
                      correctGreen: correctGreen,
                      wrongRed: wrongRed,
                    ),
                  );
                }),
                if (_revealed && _isWin) ...[
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loadRound,
                    child: Text(l10n.whoIsNextRound),
                  ),
                ],
                if (_revealed && !_isWin) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _loadRound,
                    child: Text(l10n.whoIsNextRound),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WhoIsProfileTile extends StatelessWidget {
  const _WhoIsProfileTile({
    required this.profile,
    required this.onTap,
    required this.revealed,
    required this.selectedIndex,
    required this.index,
    required this.correctIndex,
    required this.correctGreen,
    required this.wrongRed,
  });

  final WhoIsSyntheticProfile profile;
  final VoidCallback onTap;
  final bool revealed;
  final int? selectedIndex;
  final int index;
  final int correctIndex;
  final Color correctGreen;
  final Color wrongRed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasAvatar = profile.avatarUrl.isNotEmpty;

    Color borderColor = colorScheme.outline.withValues(alpha: 0.2);
    double width = 1.5;
    if (revealed) {
      if (index == correctIndex) {
        borderColor = correctGreen;
        width = 3;
      } else if (selectedIndex == index && index != correctIndex) {
        borderColor = wrongRed;
        width = 3;
      }
    }

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: revealed ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: width),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: hasAvatar
                      ? Image.network(
                          profile.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.person_rounded,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHigh,
                          child: Icon(
                            Icons.person_rounded,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (revealed) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          height: 1.35,
                        ),
                      ),
                    ],
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
