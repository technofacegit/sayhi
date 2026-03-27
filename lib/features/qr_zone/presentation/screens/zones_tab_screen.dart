import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/mock_venues.dart';

class ZonesTabScreen extends StatefulWidget {
  const ZonesTabScreen({super.key});

  @override
  State<ZonesTabScreen> createState() => _ZonesTabScreenState();
}

class _ZonesTabScreenState extends State<ZonesTabScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _mapView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      return List<Map<String, dynamic>>.from(MockVenues.all);
    }
    return MockVenues.all
        .where((z) => (z['name'] as String).toLowerCase().contains(q))
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static final LatLng _mapCenter = LatLng(41.034, 28.978);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final venues = _filtered;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Mekan ara',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Harita'),
                    icon: Icon(Icons.map_outlined),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Grid'),
                    icon: Icon(Icons.grid_view_rounded),
                  ),
                ],
                selected: {_mapView},
                onSelectionChanged: (Set<bool> next) {
                  setState(() => _mapView = next.first);
                },
                showSelectedIcon: false,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: venues.isEmpty
                  ? Center(
                      child: Text(
                        'Sonuç yok',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : _mapView
                      ? _ZonesMap(
                          center: _mapCenter,
                          venues: venues,
                        )
                      : _ZonesGrid(venues: venues),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonesMap extends StatefulWidget {
  final LatLng center;
  final List<Map<String, dynamic>> venues;

  const _ZonesMap({
    required this.center,
    required this.venues,
  });

  @override
  State<_ZonesMap> createState() => _ZonesMapState();
}

class _ZonesMapState extends State<_ZonesMap> {
  final MapController _mapController = MapController();
  LatLng? _userPoint;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _recenterOnMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Konum servisleri kapalı.')),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Konum izni gerekli.')),
      );
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() => _userPoint = here);
      _mapController.move(here, 15);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Konum alınamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final venueMarkers = <Marker>[
      for (final z in widget.venues)
        Marker(
          point: LatLng(
            (z['lat'] as num).toDouble(),
            (z['lng'] as num).toDouble(),
          ),
          width: 44,
          height: 44,
          alignment: Alignment.bottomCenter,
          child: Tooltip(
            message:
                '${z['name'] as String? ?? ''}\n${z['activeCount'] as int? ?? 0} active',
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.place_rounded,
                  size: 40,
                  color: colorScheme.primary,
                  shadows: const [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
                Positioned(
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26.withValues(alpha: 0.18),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      '${z['activeCount'] as int? ?? 0}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];

    if (_userPoint != null) {
      venueMarkers.add(
        Marker(
          point: _userPoint!,
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Tooltip(
            message: 'Konumun',
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: 13.2,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'qr_dating_app',
              ),
              MarkerLayer(markers: venueMarkers),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: colorScheme.surface,
              elevation: 3,
              shadowColor: Colors.black26,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: 'Konumumu merkeze al',
                onPressed: _recenterOnMyLocation,
                icon: const Icon(Icons.my_location_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZonesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> venues;

  const _ZonesGrid({required this.venues});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: venues.length,
      itemBuilder: (context, index) {
        final z = venues[index];
        final name = z['name'] as String? ?? '';
        final imageUrl = z['imageUrl'] as String?;
        final count = z['activeCount'] as int? ?? 0;

        return Material(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHigh,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHigh,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count aktif',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
