import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  /// Ask for location permission (and check services). Returns true if usable.
  static Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  /// Get a nice human-readable address from current GPS.
  static Future<String?> getPrettyAddress() async {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    final placemarks = await placemarkFromCoordinates(
      pos.latitude, pos.longitude,
    );
    if (placemarks.isEmpty) return null;

    final p = placemarks.first;
    final city = [p.locality, p.subAdministrativeArea]
        .where((e) => (e ?? '').isNotEmpty)
        .join(', ');
    final state = (p.administrativeArea ?? '').trim();
    final country = (p.country ?? '').trim();

    final parts = [city, state, country].where((e) => e.isNotEmpty).toList();
    return parts.join(', ');
  }
}
