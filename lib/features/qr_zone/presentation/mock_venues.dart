import 'dart:math';

/// Shared mock data for QR zone flows (no backend).
abstract final class MockVenues {
  static final _random = Random();

  static final List<Map<String, dynamic>> all = [
    {
      'name': 'The Rooftop',
      'imageUrl':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
      'activeCount': 37,
      'lat': 41.0369,
      'lng': 28.9851,
    },
    {
      'name': 'Velvet Lounge',
      'imageUrl':
          'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=1200&q=80',
      'activeCount': 22,
      'lat': 41.0256,
      'lng': 28.9744,
    },
    {
      'name': 'Sunset Bar',
      'imageUrl':
          'https://images.unsplash.com/photo-1445118773165-6282be15491f?auto=format&fit=crop&w=1200&q=80',
      'activeCount': 54,
      'lat': 41.0422,
      'lng': 28.9598,
    },
  ];

  static Map<String, dynamic> randomScan() {
    return Map<String, dynamic>.from(all[_random.nextInt(all.length)]);
  }
}
