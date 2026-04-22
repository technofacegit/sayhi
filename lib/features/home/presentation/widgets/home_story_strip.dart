import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/home/data/story_repository.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';
import 'package:qr_dating_app/features/home/presentation/model/story_group.dart';
import 'package:qr_dating_app/features/home/presentation/screens/story_viewer_screen.dart';

/// Horizontal story groups from Supabase only. [groupsFuture] is owned by the parent
/// (e.g. for pull-to-refresh). [onStoriesChanged] refetches after a story is viewed.
class HomeStoryStrip extends StatelessWidget {
  const HomeStoryStrip({
    super.key,
    required this.groupsFuture,
    required this.onStoriesChanged,
    this.leftPadding = 16,
    this.rightPadding = 72,
  });

  final Future<List<StoryGroup>> groupsFuture;
  final VoidCallback onStoriesChanged;
  final double leftPadding;
  final double rightPadding;

  Future<void> _openViewer(
    BuildContext context,
    List<StoryGroup> groups,
    int groupIndex,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final group = groups[groupIndex];
    if (group.id != null) {
      await StoryRepository().markStoryGroupViewed(group.id!);
    }
    await navigator.push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: StoryViewerScreen(
              groups: groups,
              initialGroupIndex: groupIndex,
            ),
          );
        },
      ),
    );
    onStoriesChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return FutureBuilder<List<StoryGroup>>(
      future: groupsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return SizedBox(
            height: 104,
            child: Padding(
              padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.commonLoading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _StoryStripPlaceholder(
            message: l10n.storyLoadError,
            theme: theme,
            colorScheme: colorScheme,
          );
        }

        final groups = snapshot.data!;
        if (groups.isEmpty) {
          return _StoryStripPlaceholder(
            message: l10n.storyEmpty,
            theme: theme,
            colorScheme: colorScheme,
          );
        }

        return _StoryStripContent(
          groups: groups,
          theme: theme,
          colorScheme: colorScheme,
          onOpen: _openViewer,
          leftPadding: leftPadding,
          rightPadding: rightPadding,
        );
      },
    );
  }
}

class _StoryStripPlaceholder extends StatelessWidget {
  const _StoryStripPlaceholder({
    required this.message,
    required this.theme,
    required this.colorScheme,
  });

  final String message;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryStripContent extends StatelessWidget {
  const _StoryStripContent({
    required this.groups,
    required this.theme,
    required this.colorScheme,
    required this.onOpen,
    required this.leftPadding,
    required this.rightPadding,
  });

  final List<StoryGroup> groups;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final Future<void> Function(
    BuildContext context,
    List<StoryGroup> groups,
    int groupIndex,
  ) onOpen;
  final double leftPadding;
  final double rightPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: leftPadding, right: rightPadding),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final group = groups[index];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async => onOpen(context, groups, index),
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    _StoryAvatar(
                      imageUrl: group.ringImageUrl,
                      colorScheme: colorScheme,
                      slideCount: group.slideCount,
                      isUnseen: group.isUnseen,
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
  final bool isUnseen;

  const _StoryAvatar({
    required this.imageUrl,
    required this.colorScheme,
    required this.slideCount,
    required this.isUnseen,
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
            gradient: isUnseen
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  )
                : null,
            color: isUnseen
                ? null
                : colorScheme.surfaceContainerHigh,
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
