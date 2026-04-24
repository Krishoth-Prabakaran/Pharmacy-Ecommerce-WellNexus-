import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapLocationPicker extends StatefulWidget {
  final LatLng selectedLocation;
  final ValueChanged<LatLng> onLocationSelected;

  const MapLocationPicker({
    Key? key,
    required this.selectedLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  late LatLng _currentLocation;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.selectedLocation;
  }

  @override
  void didUpdateWidget(covariant MapLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLocation != widget.selectedLocation) {
      _currentLocation = widget.selectedLocation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
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
        const SizedBox(height: 12),
        Text(
          'Tap anywhere on the map to select the pharmacy location.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${_currentLocation.latitude.toStringAsFixed(6)}, ${_currentLocation.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
