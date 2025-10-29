import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:eazystaff/utilitis/location_helper.dart';
import 'package:eazystaff/services/auth_service.dart';

class LocationManagementPage extends StatefulWidget {
  const LocationManagementPage({super.key});

  @override
  State<LocationManagementPage> createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  LocationData? _selectedLocation;
  bool _isLoading = false;
  bool _isLocationEnabled = false;
  Set<Marker> _markers = {};

  // Manual address entry
  final TextEditingController _addressController = TextEditingController();
  bool _showAddressInput = false;

  // Default location (India center)
  static const LatLng _defaultLocation = LatLng(20.5937, 78.9629);

  @override
  void initState() {
    super.initState();
    _loadStoredLocation();
  }

  Future<void> _loadStoredLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final storedLocation = await LocationHelper.getStoredLocationData();
      if (storedLocation != null) {
        setState(() {
          _currentLocation = storedLocation;
          _selectedLocation = storedLocation;
          _isLocationEnabled = true;
        });
        _updateMarker(storedLocation);
      }
    } catch (e) {
      debugPrint('Error loading stored location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final hasPermission = await LocationHelper.ensurePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final locationData = await LocationHelper.getCurrentLocationData();
      if (locationData != null) {
        setState(() {
          _currentLocation = locationData;
          _selectedLocation = locationData;
          _isLocationEnabled = true;
        });
        
        _updateMarker(locationData);
        _animateToLocation(locationData);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location updated: ${locationData.address}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateMarker(LocationData location) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title: location.isManual ? 'Manual Location' : 'Current Location',
            snippet: location.address,
          ),
          icon: location.isManual 
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      };
    });
  }

  void _animateToLocation(LocationData location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        16.0,
      ),
    );
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() => _isLoading = true);
    
    try {
      final address = await LocationHelper.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (address != null) {
        final manualLocation = LocationHelper.createManualLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
        );
        
        setState(() {
          _selectedLocation = manualLocation;
        });
        
        _updateMarker(manualLocation);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: $address'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final coordinates = await LocationHelper.getCoordinatesFromAddress(address);
      if (coordinates != null) {
        final manualLocation = LocationHelper.createManualLocation(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          address: address,
        );

        setState(() {
          _selectedLocation = manualLocation;
          _showAddressInput = false;
        });

        _updateMarker(manualLocation);
        _animateToLocation(manualLocation);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Address found: $address'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address not found. Please try a different address.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleAddressInput() {
    setState(() {
      _showAddressInput = !_showAddressInput;
      if (!_showAddressInput) {
        _addressController.clear();
      }
    });
  }

  Future<void> _saveLocation() async {
    if (_selectedLocation == null) return;

    setState(() => _isLoading = true);

    try {
      await LocationHelper.saveLocationData(_selectedLocation!);
      await AuthService.saveLocation(_selectedLocation!.address);

      setState(() {
        _currentLocation = _selectedLocation;
        _isLocationEnabled = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate location was updated
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Management'),
        backgroundColor: Colors.orange.shade400,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _toggleAddressInput,
            icon: Icon(_showAddressInput ? Icons.close : Icons.search),
            tooltip: _showAddressInput ? 'Close Search' : 'Search Address',
          ),
          if (_selectedLocation != null)
            IconButton(
              onPressed: _isLoading ? null : _saveLocation,
              icon: const Icon(Icons.save),
              tooltip: 'Save Location',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _animateToLocation(_currentLocation!);
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation != null
                ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
                : _defaultLocation,
              zoom: _currentLocation != null ? 16.0 : 5.0,
            ),
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll use our custom button
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Address search input
          if (_showAddressInput)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildAddressSearchCard(),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Bottom info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _getCurrentLocation,
        backgroundColor: Colors.orange.shade400,
        tooltip: 'Get Current Location',
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  Widget _buildAddressSearchCard() {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Search Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Enter address (e.g., "123 Main St, City, State")',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onSubmitted: (_) => _searchAddress(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _searchAddress,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade400,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _addressController.clear();
                    _toggleAddressInput();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isLocationEnabled ? Icons.location_on : Icons.location_off,
                color: _isLocationEnabled ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _isLocationEnabled ? 'Location Enabled' : 'Location Disabled',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _isLocationEnabled ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),

          if (_selectedLocation != null) ...[
            const SizedBox(height: 12),
            Text(
              _selectedLocation!.isManual ? 'Selected Location:' : 'Current Location:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedLocation!.address,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            _showAddressInput
              ? 'Enter an address above or tap on the map to set a location.'
              : 'Tap the search icon to enter an address, tap on the map to set a manual location, or use the location button to get your current position.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
