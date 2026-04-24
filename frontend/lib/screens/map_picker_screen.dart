// screens/map_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng location, String address) onLocationSelected;

  const MapPickerScreen({
    Key? key,
    required this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController(
      text: widget.initialLocation?.latitude.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.initialLocation?.longitude.toString() ?? '',
    );
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _confirmLocation() {
    try {
      final lat = double.parse(_latitudeController.text);
      final lng = double.parse(_longitudeController.text);
      final location = LatLng(lat, lng);
      final address = _addressController.text.isNotEmpty
          ? _addressController.text
          : 'Lat: $lat, Lng: $lng';

      widget.onLocationSelected(location, address);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid coordinates'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Location Coordinates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _latitudeController,
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 40.7128',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _longitudeController,
              decoration: InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., -74.0060',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address (Optional)',
                hintText: 'e.g., 123 Main St, City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.home),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
