import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_dating_app/features/home/data/discovery_country_repository.dart';
import 'package:qr_dating_app/features/home/data/discovery_repository.dart';

/// Writes [profiles.lat], [profiles.lng], [profiles.country], [profiles.location_updated_at]
/// from GPS + reverse geocode. [country] uses [DiscoveryCountryRepository.countryNameForIsoCode]
/// when possible so discovery filters (country names) match.
class ProfileLocationSync {
  ProfileLocationSync({
    DiscoveryRepository? discoveryRepository,
    DiscoveryCountryRepository? countryRepository,
  })  : _discovery = discoveryRepository ?? DiscoveryRepository(),
        _countries = countryRepository ?? DiscoveryCountryRepository();

  final DiscoveryRepository _discovery;
  final DiscoveryCountryRepository _countries;

  /// Returns true if coordinates were written; false if services off, permission denied, or error.
  Future<bool> syncFromDevice() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      String? countryName;
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final pm = placemarks.first;
          final iso = pm.isoCountryCode?.trim();
          if (iso != null && iso.isNotEmpty) {
            countryName = await _countries.countryNameForIsoCode(iso);
          }
          countryName ??= pm.country?.trim();
          if (countryName != null && countryName.isEmpty) countryName = null;
        }
      } catch (_) {
        // Reverse geocode can fail; still persist coordinates for distance discovery.
      }
      await _discovery.updateMyLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        country: countryName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
