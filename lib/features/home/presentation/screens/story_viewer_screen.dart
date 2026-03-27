import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/home/presentation/model/story_group.dart';

/// Full-screen viewer: tap left/right. Progress bars fill over 5s per slide (Instagram-style).
class StoryViewerScreen extends StatefulWidget {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _autoAdvanceDuration = Duration(seconds: 5);

  late int _groupIndex;
  late int _slideIndex;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex.clamp(0, widget.groups.length - 1);
    _slideIndex = 0;

    _progressController = AnimationController(
      vsync: this,
      duration: _autoAdvanceDuration,
    )..addStatusListener(_onProgressStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _progressController.forward(from: 0);
      }
    });
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }
    if (_advanceNext()) {
      return;
    }
    if (mounted) {
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _restartProgress() {
    _progressController
      ..stop()
      ..forward(from: 0);
  }

  StoryGroup get _group => widget.groups[_groupIndex];

  String _fullBleedUrl(String url) {
    if (url.contains('w=200')) {
      return url.replaceAll('w=200&h=200', 'w=1080&h=1920');
    }
    return url;
  }

  /// Returns `true` if the route was popped.
  bool _advanceNext() {
    final g = _group;
    if (_slideIndex < g.slideCount - 1) {
      setState(() => _slideIndex++);
      return false;
    }
    if (_groupIndex < widget.groups.length - 1) {
      setState(() {
        _groupIndex++;
        _slideIndex = 0;
      });
      return false;
    }
    Navigator.of(context).pop();
    return true;
  }

  void _onTapNext() {
    if (_advanceNext()) {
      return;
    }
    if (mounted) {
      _restartProgress();
    }
  }

  /// Returns `true` if the route was popped.
  bool _advancePrev() {
    if (_slideIndex > 0) {
      setState(() => _slideIndex--);
      return false;
    }
    if (_groupIndex > 0) {
      setState(() {
        _groupIndex--;
        _slideIndex = widget.groups[_groupIndex].slideCount - 1;
      });
      return false;
    }
    Navigator.of(context).pop();
    return true;
  }

  void _onTapPrev() {
    if (_advancePrev()) {
      return;
    }
    if (mounted) {
      _restartProgress();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final g = _group;
    final url = g.slideImageUrls[_slideIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Image.network(
              _fullBleedUrl(url),
              key: ValueKey<String>('$_groupIndex-$_slideIndex-$url'),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
              child: Text(
                g.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          Positioned(
            top: topInset + 52,
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onTapPrev,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onTapNext,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(g.slideCount, (i) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _SegmentBar(
                            isDone: i < _slideIndex,
                            isCurrent: i == _slideIndex,
                            progress: _progressController,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () {
                        _progressController.stop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;
  final Animation<double> progress;

  const _SegmentBar({
    required this.isDone,
    required this.isCurrent,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white24),
            if (isDone)
              const ColoredBox(color: Colors.white)
            else if (isCurrent)
              AnimatedBuilder(
                animation: progress,
                builder: (context, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress.value.clamp(0.0, 1.0),
                      heightFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: const ColoredBox(color: Colors.white),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
