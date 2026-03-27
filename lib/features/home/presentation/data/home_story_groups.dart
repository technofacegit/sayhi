import 'package:qr_dating_app/features/home/presentation/model/story_group.dart';

/// Mock story groups: some have multiple slides, some a single slide.
abstract final class HomeStoryGroups {
  static const List<StoryGroup> all = [
    StoryGroup(
      label: 'Rooftop',
      ringImageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&h=200&fit=crop',
      slideImageUrls: [
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&h=200&fit=crop',
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200&h=200&fit=crop',
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=200&h=200&fit=crop',
      ],
    ),
    StoryGroup(
      label: 'Velvet',
      ringImageUrl:
          'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=200&h=200&fit=crop',
      slideImageUrls: [
        'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=200&h=200&fit=crop',
        'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=200&h=200&fit=crop',
      ],
    ),
    StoryGroup(
      label: 'Sunset',
      ringImageUrl:
          'https://images.unsplash.com/photo-1445118773165-6282be15491f?w=200&h=200&fit=crop',
      slideImageUrls: [
        'https://images.unsplash.com/photo-1445118773165-6282be15491f?w=200&h=200&fit=crop',
      ],
    ),
    StoryGroup(
      label: 'Tonight',
      ringImageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&h=200&fit=crop',
      slideImageUrls: [
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&h=200&fit=crop',
        'https://images.unsplash.com/photo-1429966373912-687092438e68?w=200&h=200&fit=crop',
      ],
    ),
  ];
}
