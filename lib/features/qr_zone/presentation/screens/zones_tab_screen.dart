import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as am;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/qr_zone/data/zone_repository.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/mock_venues.dart';

class ZonesTabScreen extends StatefulWidget {
  const ZonesTabScreen({super.key});

  @override
  State<ZonesTabScreen> createState() => _ZonesTabScreenState();
}

class _ZonesTabScreenState extends State<ZonesTabScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _mapView = true;

  List<Map<String, dynamic>> _zones = List<Map<String, dynamic>>.from(
    MockVenues.all,
  );
  bool _loading = true;
  bool _loadTried = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final data = await ZoneRepository().fetchZones();
      if (mounted && data.isNotEmpty) {
        setState(() {
          _zones = data;
          _loading = false;
          _loadTried = true;
        });
        return;
      }
    } catch (_) {
      // Silent; fallback to mock
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _loadTried = true;
      });
    }
  }

  void _openZone(Map<String, dynamic> zone) {
    context.push(
      AppRouter.activeZonePath,
      extra: Map<String, dynamic>.from(zone),
    );
  }

  Future<void> _showZoneEntrySheet(Map<String, dynamic> zone) async {
    final theme = Theme.of(context);
    final name = zone['name'] as String? ?? 'Zone';
    final city = zone['city'] as String?;
    final count = zone['activeCount'] as int? ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  city != null && city.isNotEmpty
                      ? '$city • $count aktif üye'
                      : '$count aktif üye',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _openZone(zone);
                  },
                  child: const Text('Zone giriş ekranına git'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      return List<Map<String, dynamic>>.from(_zones);
    }
    return _zones
        .where((z) => (z['name'] as String).toLowerCase().contains(q))
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static const _mapCenterLat = 41.034;
  static const _mapCenterLng = 28.978;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final venues = _filtered;
    final mappableVenues = venues
        .where(
          (z) => z['lat'] is num && z['lng'] is num,
        )
        .toList(growable: false);

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
              child: _loading && !_loadTried
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : venues.isEmpty
                      ? Center(
                          child: Text(
                            'Sonuç yok',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        )
                      : _mapView
                          ? _ZonesMap(
                              centerLat: _mapCenterLat,
                              centerLng: _mapCenterLng,
                              venues: mappableVenues,
                              onVenueTap: _showZoneEntrySheet,
                            )
                          : _ZonesGrid(
                              venues: venues,
                              onVenueTap: _showZoneEntrySheet,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonesMap extends StatefulWidget {
  final double centerLat;
  final double centerLng;
  final List<Map<String, dynamic>> venues;
  final void Function(Map<String, dynamic> venue) onVenueTap;

  const _ZonesMap({
    required this.centerLat,
    required this.centerLng,
    required this.venues,
    required this.onVenueTap,
  });

  @override
  State<_ZonesMap> createState() => _ZonesMapState();
}

class _ZonesMapState extends State<_ZonesMap> {
  double? _userLat;
  double? _userLng;

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
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Konum alınamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _AppleZonesMap(
        centerLat: widget.centerLat,
        centerLng: widget.centerLng,
        venues: widget.venues,
        userLat: _userLat,
        userLng: _userLng,
        onMyLocationTap: _recenterOnMyLocation,
        onVenueTap: widget.onVenueTap,
      );
    }
    if (Platform.isAndroid) {
      return _GoogleZonesMap(
        centerLat: widget.centerLat,
        centerLng: widget.centerLng,
        venues: widget.venues,
        userLat: _userLat,
        userLng: _userLng,
        onMyLocationTap: _recenterOnMyLocation,
        onVenueTap: widget.onVenueTap,
      );
    }

    return const Center(child: Text('Platform map is not supported.'));
  }
}

class _GoogleZonesMap extends StatefulWidget {
  final double centerLat;
  final double centerLng;
  final List<Map<String, dynamic>> venues;
  final double? userLat;
  final double? userLng;
  final Future<void> Function() onMyLocationTap;
  final void Function(Map<String, dynamic> venue) onVenueTap;

  const _GoogleZonesMap({
    required this.centerLat,
    required this.centerLng,
    required this.venues,
    required this.userLat,
    required this.userLng,
    required this.onMyLocationTap,
    required this.onVenueTap,
  });

  @override
  State<_GoogleZonesMap> createState() => _GoogleZonesMapState();
}

class _GoogleZonesMapState extends State<_GoogleZonesMap> {
  gm.GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant _GoogleZonesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLat != null &&
        widget.userLng != null &&
        (widget.userLat != oldWidget.userLat ||
            widget.userLng != oldWidget.userLng)) {
      _controller?.animateCamera(
        gm.CameraUpdate.newLatLngZoom(
          gm.LatLng(widget.userLat!, widget.userLng!),
          15,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final venueMarkers = <gm.Marker>{
      for (final z in widget.venues)
        gm.Marker(
          markerId: gm.MarkerId('venue-${z['name']}'),
          position: gm.LatLng(
            (z['lat'] as num).toDouble(),
            (z['lng'] as num).toDouble(),
          ),
          infoWindow: gm.InfoWindow(
            title: z['name'] as String? ?? '',
            snippet: (z['city'] as String?) ?? '${z['activeCount'] as int? ?? 0} active',
          ),
          onTap: () => widget.onVenueTap(z),
        ),
    };

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          gm.GoogleMap(
            initialCameraPosition: gm.CameraPosition(
              target: gm.LatLng(widget.centerLat, widget.centerLng),
              zoom: 13.2,
            ),
            myLocationEnabled: widget.userLat != null && widget.userLng != null,
            myLocationButtonEnabled: false,
            markers: venueMarkers,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _controller = controller,
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
                onPressed: widget.onMyLocationTap,
                icon: const Icon(Icons.my_location_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleZonesMap extends StatefulWidget {
  final double centerLat;
  final double centerLng;
  final List<Map<String, dynamic>> venues;
  final double? userLat;
  final double? userLng;
  final Future<void> Function() onMyLocationTap;
  final void Function(Map<String, dynamic> venue) onVenueTap;

  const _AppleZonesMap({
    required this.centerLat,
    required this.centerLng,
    required this.venues,
    required this.userLat,
    required this.userLng,
    required this.onMyLocationTap,
    required this.onVenueTap,
  });

  @override
  State<_AppleZonesMap> createState() => _AppleZonesMapState();
}

class _AppleZonesMapState extends State<_AppleZonesMap> {
  am.AppleMapController? _controller;
  final Map<int, am.BitmapDescriptor> _markerIconsByCount = {};

  @override
  void initState() {
    super.initState();
    _prepareMarkerIcons();
  }

  @override
  void didUpdateWidget(covariant _AppleZonesMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _prepareMarkerIcons();
    if (widget.userLat != null &&
        widget.userLng != null &&
        (widget.userLat != oldWidget.userLat ||
            widget.userLng != oldWidget.userLng)) {
      _controller?.moveCamera(
        am.CameraUpdate.newCameraPosition(
          am.CameraPosition(
            target: am.LatLng(widget.userLat!, widget.userLng!),
            zoom: 15,
          ),
        ),
      );
    }
  }

  Future<void> _prepareMarkerIcons() async {
    final counts = widget.venues
        .map((z) => z['activeCount'] as int? ?? 0)
        .toSet()
        .where((c) => !_markerIconsByCount.containsKey(c));
    if (counts.isEmpty) return;

    for (final count in counts) {
      final bytes = await _buildAppleMarkerBytes('$count');
      _markerIconsByCount[count] = am.BitmapDescriptor.fromBytes(bytes);
    }
    if (mounted) setState(() {});
  }

  Future<Uint8List> _buildAppleMarkerBytes(String text) async {
    const width = 86.0;
    const height = 44.0;
    const radius = 22.0;
    const notchHeight = 8.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bubbleRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height - notchHeight),
      const Radius.circular(radius),
    );
    final bubblePaint = Paint()..color = const Color(0xFF7C4DFF);
    canvas.drawRRect(bubbleRect, bubblePaint);

    final notchPath = Path()
      ..moveTo(width / 2 - 7, height - notchHeight)
      ..lineTo(width / 2 + 7, height - notchHeight)
      ..lineTo(width / 2, height)
      ..close();
    canvas.drawPath(notchPath, bubblePaint);

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    tp.paint(canvas, Offset((width - tp.width) / 2, (height - notchHeight - tp.height) / 2));

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final venueAnnotations = <am.Annotation>{
      for (final z in widget.venues)
        am.Annotation(
          annotationId: am.AnnotationId('venue-${z['name']}'),
          position: am.LatLng(
            (z['lat'] as num).toDouble(),
            (z['lng'] as num).toDouble(),
          ),
          icon: _markerIconsByCount[z['activeCount'] as int? ?? 0] ??
              am.BitmapDescriptor.markerAnnotationWithHue(
                am.BitmapDescriptor.hueViolet,
              ),
          infoWindow: am.InfoWindow(
            title: z['name'] as String? ?? '',
            snippet: (z['city'] as String?) ?? '${z['activeCount'] as int? ?? 0} active',
            onTap: () => widget.onVenueTap(z),
          ),
          onTap: () => widget.onVenueTap(z),
        ),
      if (widget.userLat != null && widget.userLng != null)
        am.Annotation(
          annotationId: am.AnnotationId('my-location'),
          position: am.LatLng(widget.userLat!, widget.userLng!),
          infoWindow: const am.InfoWindow(title: 'Konumun'),
        ),
    };

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          am.AppleMap(
            initialCameraPosition: am.CameraPosition(
              target: am.LatLng(widget.centerLat, widget.centerLng),
              zoom: 13.2,
            ),
            myLocationEnabled: widget.userLat != null && widget.userLng != null,
            myLocationButtonEnabled: false,
            annotations: venueAnnotations,
            onMapCreated: (controller) => _controller = controller,
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
                onPressed: widget.onMyLocationTap,
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
  final void Function(Map<String, dynamic> venue) onVenueTap;

  const _ZonesGrid({
    required this.venues,
    required this.onVenueTap,
  });

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
            onTap: () => onVenueTap(z),
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
