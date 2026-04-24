import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/patient_service.dart';

class PharmacyFinderScreen extends StatefulWidget {
  const PharmacyFinderScreen({Key? key}) : super(key: key);

  @override
  State<PharmacyFinderScreen> createState() => _PharmacyFinderScreenState();
}

class _PharmacyFinderScreenState extends State<PharmacyFinderScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _loadNearbyPharmacies();
  }

  Future<void> _loadNearbyPharmacies() async {
    try {
      final position = await LocationService.getCurrentLocation();
      final result = await PatientService().getNearbyPharmacies(
        position.latitude,
        position.longitude,
      );

      if (result['success'] == true) {
        setState(() {
          _pharmacies = List<Map<String, dynamic>>.from(result['pharmacies'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Unable to find nearby pharmacies';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Pharmacies'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _pharmacies.isEmpty
                    ? const Center(child: Text('No nearby pharmacies found.'))
                    : ListView.separated(
                        itemCount: _pharmacies.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final pharmacy = _pharmacies[index];
                          final distance = pharmacy['distance_km']?.toStringAsFixed(2) ?? 'N/A';
                          return ListTile(
                            leading: const Icon(Icons.local_pharmacy),
                            title: Text(pharmacy['pharmacy_name'] ?? 'Unknown Pharmacy'),
                            subtitle: Text('${pharmacy['address'] ?? ''}\nDistance: $distance km'),
                            isThreeLine: true,
                          );
                        },
                      ),
      ),
    );
  }
}
