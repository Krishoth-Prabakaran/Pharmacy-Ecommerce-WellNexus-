import 'package:flutter/material.dart';
import '../services/pharmacy_service.dart';
import '../services/auth_service.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PharmacyDashboardScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  final PharmacyService _pharmacyService = PharmacyService();

  List<dynamic> _medicines = [];
  List<dynamic> _dealers = [];
  List<dynamic> _stock = [];
  List<dynamic> _sales = [];

  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _medicineManufacturerController = TextEditingController();
  final TextEditingController _medicineBrandController = TextEditingController();

  final TextEditingController _dealerNameController = TextEditingController();
  final TextEditingController _dealerPhoneController = TextEditingController();
  final TextEditingController _dealerEmailController = TextEditingController();

  int _currentTabIndex = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    final medicines = await _pharmacyService.getMedicines();
    final dealers = await _pharmacyService.getDealers();

    final pharmacyId = widget.userData['pharmacy_id'] ?? widget.userData['user_id'];
    final stock = await _pharmacyService.getStockByPharmacy(pharmacyId as int);
    final sales = await _pharmacyService.getSalesByPharmacy(pharmacyId as int);

    setState(() {
      _medicines = medicines;
      _dealers = dealers;
      _stock = stock;
      _sales = sales;
      _isLoading = false;
    });
  }

  Future<void> _addMedicine() async {
    final name = _medicineNameController.text.trim();
    if (name.isEmpty) return;

    final res = await _pharmacyService.createMedicine(
      name,
      manufacturer: _medicineManufacturerController.text.trim().isEmpty
          ? null
          : _medicineManufacturerController.text.trim(),
      brand: _medicineBrandController.text.trim().isEmpty
          ? null
          : _medicineBrandController.text.trim(),
    );

    if (res['success'] == true) {
      _medicineNameController.clear();
      _medicineManufacturerController.clear();
      _medicineBrandController.clear();
      await _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine added successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to add medicine')));
    }
  }

  Future<void> _addDealer() async {
    final dealerName = _dealerNameController.text.trim();
    if (dealerName.isEmpty) return;

    final res = await _pharmacyService.createDealer(
      dealerName,
      phone: _dealerPhoneController.text.trim().isEmpty ? null : _dealerPhoneController.text.trim(),
      email: _dealerEmailController.text.trim().isEmpty ? null : _dealerEmailController.text.trim(),
    );

    if (res['success'] == true) {
      _dealerNameController.clear();
      _dealerPhoneController.clear();
      _dealerEmailController.clear();
      await _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dealer added successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to add dealer')));
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _medicineManufacturerController.dispose();
    _medicineBrandController.dispose();
    _dealerNameController.dispose();
    _dealerPhoneController.dispose();
    _dealerEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Dashboard'),
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TabBar(
                  onTap: (index) => setState(() => _currentTabIndex = index),
                  tabs: const [
                    Tab(text: 'Medicines'),
                    Tab(text: 'Dealers'),
                    Tab(text: 'Stock'),
                    Tab(text: 'Sales'),
                  ],
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  controller: DefaultTabController.of(context) ?? DefaultTabController(length: 4, child: Container()).controller,
                ),
                Expanded(child: _buildTabContent()),
              ],
            ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildMedicinesTab();
      case 1:
        return _buildDealersTab();
      case 2:
        return _buildStockTab();
      case 3:
        return _buildSalesTab();
      default:
        return _buildMedicinesTab();
    }
  }

  Widget _buildMedicinesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(controller: _medicineNameController, decoration: const InputDecoration(labelText: 'Medicine Name')),
          TextField(controller: _medicineManufacturerController, decoration: const InputDecoration(labelText: 'Manufacturer (optional)')),
          TextField(controller: _medicineBrandController, decoration: const InputDecoration(labelText: 'Brand (optional)')),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _addMedicine, child: const Text('Add Medicine')),
          const SizedBox(height: 16),
          Expanded(
            child: _medicines.isEmpty
                ? const Center(child: Text('No medicines available'))
                : ListView.builder(
                    itemCount: _medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = _medicines[index];
                      return ListTile(
                        title: Text(medicine['name'] ?? ''),
                        subtitle: Text('Manufacturer: ${medicine['manufacturer'] ?? 'N/A'} | Brand: ${medicine['brand'] ?? 'N/A'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final result = await _pharmacyService.deleteMedicine(medicine['medicine_id']);
                            if (result['success'] == true) {
                              await _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine deleted')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to delete')));
                            }
                          },
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildDealersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(controller: _dealerNameController, decoration: const InputDecoration(labelText: 'Dealer Name')),
          TextField(controller: _dealerPhoneController, decoration: const InputDecoration(labelText: 'Phone (optional)')),
          TextField(controller: _dealerEmailController, decoration: const InputDecoration(labelText: 'Email (optional)')),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _addDealer, child: const Text('Add Dealer')),
          const SizedBox(height: 16),
          Expanded(
            child: _dealers.isEmpty
                ? const Center(child: Text('No dealers available'))
                : ListView.builder(
                    itemCount: _dealers.length,
                    itemBuilder: (context, index) {
                      final dealer = _dealers[index];
                      return ListTile(
                        title: Text(dealer['dealer_name'] ?? 'Unnamed'),
                        subtitle: Text('Phone: ${dealer['phone'] ?? 'N/A'} | Email: ${dealer['email'] ?? 'N/A'}'),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildStockTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _stock.isEmpty
          ? const Center(child: Text('No stock records found'))
          : ListView.builder(
              itemCount: _stock.length,
              itemBuilder: (context, index) {
                final item = _stock[index];
                return ListTile(
                  title: Text('${item['medicine_name'] ?? 'N/A'} (${item['strength'] ?? ''} ${item['form'] ?? ''})'),
                  subtitle: Text('Qty: ${item['quantity'] ?? 0}, Dealer: ${item['dealer_name'] ?? 'N/A'}, Expiry: ${item['expiry_date'] ?? 'N/A'}'),
                );
              },
            ),
    );
  }

  Widget _buildSalesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _sales.isEmpty
          ? const Center(child: Text('No sales/prescriptions found'))
          : ListView.builder(
              itemCount: _sales.length,
              itemBuilder: (context, index) {
                final sale = _sales[index];
                return ListTile(
                  title: Text('Prescription: ${sale['prescription_id'] ?? 'N/A'}'),
                  subtitle: Text('Patient: ${sale['patient_id'] ?? 'N/A'} | Date: ${sale['sale_date'] ?? 'N/A'}'),
                );
              },
            ),
    );
  }
}
