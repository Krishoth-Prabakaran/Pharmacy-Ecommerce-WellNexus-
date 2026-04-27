// map_location_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng selectedLocation;
  final ValueChanged<LatLng> onLocationSelected;
  final double? height;

  const MapLocationPicker({
    Key? key,
    required this.selectedLocation,
    required this.onLocationSelected,
    this.height,
  }) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _currentLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.selectedLocation;
  }

  @override
  void didUpdateWidget(covariant MapLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation) {
      setState(() {
        _currentLocation = widget.selectedLocation;
      });
      _mapController.move(_currentLocation, 13);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate available height based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = widget.height ?? (screenHeight * 0.3); // Default to 30% of screen height
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min, // Important: Prevents infinite height
      children: [
        SizedBox(
          height: mapHeight.clamp(150, 300), // Min 150, Max 300 pixels
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 13,
                onTap: (tapPosition, point) {
                  setState(() {
                    _currentLocation = point;
                  });
                  widget.onLocationSelected(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.wellnexus',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 48,
                      height: 48,
                      point: _currentLocation,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap anywhere on the map to select the pharmacy location.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Selected: ${_currentLocation.latitude.toStringAsFixed(6)}, ${_currentLocation.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 9, color: Colors.black45),
        ),
      ],
    );
  }
}