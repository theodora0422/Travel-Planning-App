import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_colors.dart';

class MapPickerScreen extends StatefulWidget {
  final Map<String, dynamic> selectedCity;
  final List<Map<String, dynamic>> activities;
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({
    super.key,
    required this.selectedCity,
    required this.activities,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;

  LatLng get _initialPosition {
    final lat = widget.initialLatitude ??
        (widget.selectedCity['latitude'] as num?)?.toDouble() ??
        48.8566;
    final lng = widget.initialLongitude ??
        (widget.selectedCity['longitude'] as num?)?.toDouble() ??
        2.3522;

    return LatLng(lat, lng);
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (int i = 0; i < widget.activities.length; i++) {
      final activity = widget.activities[i];
      final lat = (activity['latitude'] as num?)?.toDouble();
      final lng = (activity['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) continue;

      markers.add(
        Marker(
          markerId: MarkerId('activity_$i'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: activity['title']?.toString(),
            snippet: activity['comments']?.toString(),
          ),
        ),
      );
    }

    if (_pickedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('picked_location'),
          position: _pickedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRose,
          ),
          infoWindow: const InfoWindow(title: 'Selected location'),
        ),
      );
    }

    return markers;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  void _confirmLocation() {
    if (_pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap on the map to choose a location.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'latitude': _pickedLocation!.latitude,
      'longitude': _pickedLocation!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location on map'),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: const Text('Use this'),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 12,
        ),
        markers: _buildMarkers(),
        onTap: _onMapTap,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.white,
        child: ElevatedButton.icon(
          onPressed: _confirmLocation,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Confirm selected coordinates'),
        ),
      ),
    );
  }
}