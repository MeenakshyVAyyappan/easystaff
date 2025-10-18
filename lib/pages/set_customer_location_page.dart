import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eazystaff/models/customer.dart';
import 'package:eazystaff/services/customer_service.dart';
import 'package:eazystaff/utilitis/location_helper.dart';

class SetCustomerLocationPage extends StatefulWidget {
  final Customer customer;
  final Function(Customer)? onLocationSaved;

  const SetCustomerLocationPage({
    super.key,
    required this.customer,
    this.onLocationSaved,
  });

  @override
  State<SetCustomerLocationPage> createState() => _SetCustomerLocationPageState();
}

class _SetCustomerLocationPageState extends State<SetCustomerLocationPage> {
  late GoogleMapController mapController;
  LatLng? selectedLocation;
  Set<Marker> markers = {};
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Try to get current location as initial position
      final hasPermission = await LocationHelper.ensurePermission();
      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        setState(() {
          selectedLocation = LatLng(position.latitude, position.longitude);
          _updateMarker();
        });
      }
    } catch (e) {
      // If can't get current location, use default coordinates (India center)
      setState(() {
        selectedLocation = const LatLng(20.5937, 78.9629);
        _updateMarker();
      });
    }
  }

  void _updateMarker() {
    if (selectedLocation != null) {
      markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: selectedLocation!,
          infoWindow: const InfoWindow(
            title: 'Selected Location',
            snippet: 'Tap to confirm this location',
          ),
        ),
      };
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      selectedLocation = location;
      _updateMarker();
    });
  }

  Future<void> _saveLocation() async {
    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final success = await CustomerService.updateCustomerLocation(
        widget.customer.id,
        selectedLocation!.latitude,
        selectedLocation!.longitude,
      );

      if (success) {
        // Update customer object
        final updatedCustomer = widget.customer.copyWith(
          latitude: selectedLocation!.latitude,
          longitude: selectedLocation!.longitude,
          locationSet: true,
        );

        // Call callback if provided
        if (widget.onLocationSaved != null) {
          widget.onLocationSaved!(updatedCustomer);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location saved for ${widget.customer.name}'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedCustomer);
        }
      } else {
        setState(() {
          errorMessage = 'Failed to save location. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Location for ${widget.customer.name}'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: selectedLocation ?? const LatLng(20.5937, 78.9629),
              zoom: 15,
            ),
            markers: markers,
            onTap: _onMapTapped,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
          ),
          // Center marker indicator
          Center(
            child: Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
          // Bottom sheet with location info and save button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Selected Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Coordinates
                    if (selectedLocation != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Latitude:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedLocation!.latitude.toString(),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Longitude:',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    selectedLocation!.longitude.toString(),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Error message
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Save Location',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

