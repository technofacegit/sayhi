import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/home/presentation/data/home_story_groups.dart';
import 'package:qr_dating_app/features/home/presentation/screens/story_viewer_screen.dart';

/// Horizontal story groups (each ring may open multiple sub-stories).
class HomeStoryStrip extends StatelessWidget {
  const HomeStoryStrip({super.key});

  void _openViewer(BuildContext context, int groupIndex) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: StoryViewerScreen(
              groups: HomeStoryGroups.all,
              initialGroupIndex: groupIndex,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groups = HomeStoryGroups.all;

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final group = groups[index];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openViewer(context, index),
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    _StoryAvatar(
                      imageUrl: group.ringImageUrl,
                      colorScheme: colorScheme,
                      slideCount: group.slideCount,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      group.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final String? imageUrl;
  final ColorScheme colorScheme;
  final int slideCount;

  const _StoryAvatar({
    required this.imageUrl,
    required this.colorScheme,
    required this.slideCount,
  });

  @override
  Widget build(BuildContext context) {
    const ringWidth = 2.5;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(ringWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.secondary,
              ],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: colorScheme.surfaceContainerHigh,
                          child: Icon(
                            Icons.nightlife_rounded,
                            color: colorScheme.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                      )
                    : ColoredBox(
                        color: colorScheme.surfaceContainerHigh,
                      ),
              ),
            ),
          ),
        ),
        if (slideCount > 1)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '$slideCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}
