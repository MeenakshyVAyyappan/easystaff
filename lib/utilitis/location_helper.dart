import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final bool isManual;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    this.isManual = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'isManual': isManual,
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isManual: json['isManual'] ?? false,
    );
  }
}

class LocationHelper {
  static const _storage = FlutterSecureStorage();
  static const String _locationKey = 'user_location_data';

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

  /// Get current GPS position
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get a nice human-readable address from current GPS.
  static Future<String?> getPrettyAddress() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;

    return await getAddressFromCoordinates(pos.latitude, pos.longitude);
  }

  /// Get address from coordinates
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      final street = p.street ?? '';
      final locality = p.locality ?? '';
      final subLocality = p.subLocality ?? '';
      final administrativeArea = p.administrativeArea ?? '';
      final country = p.country ?? '';

      final parts = [
        if (street.isNotEmpty) street,
        if (subLocality.isNotEmpty) subLocality,
        if (locality.isNotEmpty) locality,
        if (administrativeArea.isNotEmpty) administrativeArea,
        if (country.isNotEmpty) country,
      ];

      return parts.join(', ');
    } catch (e) {
      return null;
    }
  }

  /// Get coordinates from address (geocoding)
  static Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;

      final location = locations.first;
      return LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
        timestamp: DateTime.now(),
        isManual: true,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get current location with full data
  static Future<LocationData?> getCurrentLocationData() async {
    final pos = await getCurrentPosition();
    if (pos == null) return null;

    final address = await getAddressFromCoordinates(pos.latitude, pos.longitude);
    if (address == null) return null;

    return LocationData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      address: address,
      timestamp: DateTime.now(),
      isManual: false,
    );
  }

  /// Save location data to secure storage
  static Future<void> saveLocationData(LocationData locationData) async {
    try {
      final jsonString = locationData.toJson();
      await _storage.write(key: _locationKey, value: jsonString.toString());
    } catch (e) {
      // Handle error silently
    }
  }

  /// Load location data from secure storage
  static Future<LocationData?> getStoredLocationData() async {
    try {
      final jsonString = await _storage.read(key: _locationKey);
      if (jsonString == null) return null;

      // Parse the stored JSON string
      final Map<String, dynamic> json = {};
      // Simple parsing for the stored format
      final parts = jsonString.replaceAll('{', '').replaceAll('}', '').split(', ');
      for (final part in parts) {
        final keyValue = part.split(': ');
        if (keyValue.length == 2) {
          json[keyValue[0]] = keyValue[1];
        }
      }

      return LocationData.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Create manual location data
  static LocationData createManualLocation({
    required double latitude,
    required double longitude,
    required String address,
  }) {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      address: address,
      timestamp: DateTime.now(),
      isManual: true,
    );
  }

  /// Calculate distance between two points in meters
  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
