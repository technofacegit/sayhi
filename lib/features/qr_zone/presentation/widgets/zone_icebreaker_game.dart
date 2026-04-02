import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/model/icebreaker_question.dart';

/// Mini icebreaker when the zone grid is empty: questions from Supabase, answers persisted via RPC.
class ZoneIcebreakerGame extends StatefulWidget {
  const ZoneIcebreakerGame({
    super.key,
    required this.zoneId,
    this.repository,
  });

  final String zoneId;
  final ZoneRepository? repository;

  @override
  State<ZoneIcebreakerGame> createState() => _ZoneIcebreakerGameState();
}

class _ZoneIcebreakerGameState extends State<ZoneIcebreakerGame> {
  late final ZoneRepository _repo = widget.repository ?? ZoneRepository();

  bool _loading = true;
  bool _loadError = false;
  List<IcebreakerQuestion> _questions = const [];
  int _stepIndex = 0;
  bool _submitting = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      final list = await _repo.fetchIcebreakerQuestions(limit: 3);
      if (!mounted) return;
      setState(() {
        _questions = list;
        _loading = false;
        _stepIndex = 0;
        _finished = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _onPick(IcebreakerQuestion q, int optionIndex) async {
    if (_submitting || _finished) return;
    setState(() => _submitting = true);
    try {
      await _repo.submitIcebreakerAnswer(
        zoneId: widget.zoneId,
        questionId: q.id,
        optionIndex: optionIndex,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save answer. Try again.')),
      );
      setState(() => _submitting = false);
      return;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (_stepIndex + 1 >= _questions.length) {
        _finished = true;
      } else {
        _stepIndex++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_loadError || _questions.isEmpty) {
      return _LoadError(onRetry: _loadQuestions);
    }
    if (_finished) {
      return _CompletionCard(total: _questions.length);
    }

    final q = _questions[_stepIndex];
    final total = _questions.length;
    final current = _stepIndex + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You\'re early',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kick things off with a quick icebreaker.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 22),
          _IcebreakerCard(
            stepLabel: '$current / $total',
            progress: current / total,
            question: q,
            submitting: _submitting,
            onOption: (i) => _onPick(q, i),
          ),
        ],
      ),
    );
  }
}

class _IcebreakerCard extends StatelessWidget {
  const _IcebreakerCard({
    required this.stepLabel,
    required this.progress,
    required this.question,
    required this.submitting,
    required this.onOption,
  });

  final String stepLabel;
  final double progress;
  final IcebreakerQuestion question;
  final bool submitting;
  final ValueChanged<int> onOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Material(
        key: ValueKey(question.id),
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer.withValues(alpha: 0.55),
                cs.tertiaryContainer.withValues(alpha: 0.45),
              ],
            ),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 22,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Icebreaker',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surface.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        stepLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: cs.surface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  question.prompt,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < question.options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _OptionButton(
                    label: question.options[i],
                    index: i,
                    enabled: !submitting,
                    onPressed: () => onOption(i),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.index,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final int index;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton.tonal(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: cs.surface.withValues(alpha: 0.92),
        foregroundColor: cs.onSurface,
      ),
      child: Row(
        children: [
          Text(
            String.fromCharCode(65 + index),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              cs.secondaryContainer.withValues(alpha: 0.7),
              cs.primaryContainer.withValues(alpha: 0.5),
            ],
          ),
          border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              '🎉',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re warmed up!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nice work on all $total questions. When someone joins the zone, they\'ll show up here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.72),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 40, color: cs.outline),
          const SizedBox(height: 12),
          Text(
            'Couldn\'t load icebreaker questions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => onRetry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
