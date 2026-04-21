import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/pharmacy_service.dart';
import '../services/pharmacy_inventory_service.dart';
import 'low_stock_notification_screen.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key, this.pharmacy});

  final Map<String, dynamic>? pharmacy;

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> with SingleTickerProviderStateMixin {
  final PharmacyInventoryService _inventoryService = PharmacyInventoryService();
  final PharmacyService _pharmacyService = PharmacyService();
  bool _isLoading = true;
  bool _isBusy = false;
  Map<String, dynamic>? _pharmacy;
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _dealers = [];
  List<Map<String, dynamic>> _stock = [];
  final Map<int, List<Map<String, dynamic>>> _variantsByMedicine = {};
  String _medicineSearchQuery = '';
  String _dealerSearchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final userData = await AuthService.getUserData();
    if (userData == null) {
      _showSnackBar('Login required to view pharmacy dashboard', Colors.red);
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final pharmacyResult = widget.pharmacy != null
        ? {'success': true, 'pharmacy': widget.pharmacy}
        : await _pharmacyService.getPharmacyByEmail(userData['email']);

    if (pharmacyResult['success'] != true || pharmacyResult['pharmacy'] == null) {
      _showSnackBar('No pharmacy record found. Please register your pharmacy details.', Colors.red);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _pharmacy = Map<String, dynamic>.from(pharmacyResult['pharmacy']);
    await _loadInventory();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadInventory() async {
    if (_pharmacy == null) return;

    final medicinesResult = await _inventoryService.getMedicines();
    final dealersResult = await _inventoryService.getDealers();
    final stockResult = await _inventoryService.getStock(_pharmacy!['pharmacy_id']);

    final medicines = medicinesResult['success'] == true
        ? (medicinesResult['medicines'] as List<dynamic>? ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>))
            .toList()
        : <Map<String, dynamic>>[];

    final variantResults = await Future.wait(medicines.map((medicine) async {
      final result = await _inventoryService.getVariants(medicine['medicine_id']);
      return {
        'medicineId': medicine['medicine_id'],
        'variants': result['success'] == true ? List<Map<String, dynamic>>.from(result['variants'] ?? []) : [],
      };
    }));

    final variantsByMedicine = <int, List<Map<String, dynamic>>>{};
    for (final entry in variantResults) {
      variantsByMedicine[entry['medicineId'] as int] = entry['variants'] as List<Map<String, dynamic>>;
    }

    setState(() {
      _medicines = medicines;
      _dealers = dealersResult['success'] == true
          ? List<Map<String, dynamic>>.from(dealersResult['dealers'] ?? [])
          : [];
      _stock = stockResult['success'] == true
          ? List<Map<String, dynamic>>.from(stockResult['stock'] ?? [])
          : [];
      _variantsByMedicine.clear();
      _variantsByMedicine.addAll(variantsByMedicine);
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (shouldLogout == true) {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar({required String hint, required ValueChanged<String> onChanged}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildOverviewContent() {
    final totalVariants = _variantsByMedicine.values.fold<int>(0, (sum, list) => sum + list.length);
    final totalStock = _stock.fold<int>(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
    final totalMedicines = _medicines.length;
    final totalDealers = _dealers.length;

    return RefreshIndicator(
      onRefresh: _loadInventory,
      color: const Color(0xFF6366F1),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Welcome back, Pharmacist!',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _pharmacy?['pharmacy_name'] ?? 'Your Pharmacy',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pharmacy?['address'] ?? 'No address provided yet',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(Icons.access_time, 'Open: ${_pharmacy?['open_time'] ?? 'N/A'}'),
                        _buildInfoChip(Icons.access_time_filled, 'Close: ${_pharmacy?['close_time'] ?? 'N/A'}'),
                        _buildInfoChip(Icons.phone, _pharmacy?['phone'] ?? 'No phone'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats Row 1
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard('Medicines', '$totalMedicines', Icons.medical_services, const Color(0xFF6366F1)),
                  const SizedBox(width: 12),
                  _buildStatCard('Variants', '$totalVariants', Icons.category, const Color(0xFF8B5CF6)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Stats Row 2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard('Dealers', '$totalDealers', Icons.business, const Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  _buildStatCard('Stock Qty', '$totalStock', Icons.inventory_2, const Color(0xFFF59E0B)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.add_box,
                          label: 'Add Medicine',
                          color: const Color(0xFF6366F1),
                          onPressed: () => _openMedicineDialog(),
                        ),
                        _buildQuickActionButton(
                          icon: Icons.add_shopping_cart,
                          label: 'Add Stock',
                          color: const Color(0xFF10B981),
                          onPressed: _openStockDialog,
                        ),
                        _buildQuickActionButton(
                          icon: Icons.person_add,
                          label: 'Add Dealer',
                          color: const Color(0xFF8B5CF6),
                          onPressed: () => _openDealerDialog(),
                        ),
                        _buildQuickActionButton(
                          icon: Icons.notifications_active,
                          label: 'Low Stock',
                          color: const Color(0xFFEF4444),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LowStockNotificationScreen(
                                  pharmacyId: _pharmacy!['pharmacy_id'],
                                  pharmacyName: _pharmacy?['pharmacy_name'],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Future<void> _openMedicineDialog({Map<String, dynamic>? medicine}) async {
    final nameController = TextEditingController(text: medicine?['name'] ?? '');
    final manufacturerController = TextEditingController(text: medicine?['manufacturer'] ?? '');
    final brandController = TextEditingController(text: medicine?['brand'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine == null ? 'Add New Medicine' : 'Edit Medicine',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.medical_services),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: manufacturerController,
                  decoration: InputDecoration(
                    labelText: 'Manufacturer (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.factory),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandController,
                  decoration: InputDecoration(
                    labelText: 'Brand',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.branding_watermark),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final payload = {
      'name': nameController.text.trim(),
      'manufacturer': manufacturerController.text.trim(),
      'brand': brandController.text.trim(),
    };

    setState(() {
      _isBusy = true;
    });

    try {
      if (medicine == null) {
        final response = await _inventoryService.createMedicine(payload);
        if (response['success'] == true) {
          _showSnackBar('Medicine added successfully', Colors.green);
        } else {
          _showSnackBar(response['message'] ?? 'Failed to add medicine', Colors.red);
        }
      } else {
        final response = await _inventoryService.updateMedicine(medicine['medicine_id'], payload);
        if (response['success'] == true) {
          _showSnackBar('Medicine updated successfully', Colors.green);
        } else {
          _showSnackBar(response['message'] ?? 'Failed to update medicine', Colors.red);
        }
      }
      await _loadInventory();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _deleteMedicine(int medicineId) async {
    final confirm = await _showDeleteConfirmation('medicine');
    if (!confirm) return;

    setState(() {
      _isBusy = true;
    });
    try {
      final response = await _inventoryService.deleteMedicine(medicineId);
      if (response['success'] == true) {
        _showSnackBar('Medicine deleted', Colors.green);
        await _loadInventory();
      } else {
        _showSnackBar(response['message'] ?? 'Failed to delete medicine', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<bool> _showDeleteConfirmation(String itemName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this $itemName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _openVariantDialog(Map<String, dynamic> medicine, {Map<String, dynamic>? variant}) async {
    final strengthController = TextEditingController(text: variant?['strength'] ?? '');
    final formController = TextEditingController(text: variant?['form'] ?? '');
    final priceController = TextEditingController(text: variant?['price']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant == null ? 'Add New Variant' : 'Edit Variant',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('for ${medicine['name']}', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(
                  controller: strengthController,
                  decoration: InputDecoration(
                    labelText: 'Strength (e.g., 500mg)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: formController,
                  decoration: InputDecoration(
                    labelText: 'Form (e.g., Tablet)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Price',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final payload = {
      'medicine_id': medicine['medicine_id'],
      'strength': strengthController.text.trim(),
      'form': formController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0.0,
    };

    setState(() {
      _isBusy = true;
    });
    try {
      if (variant == null) {
        final response = await _inventoryService.createVariant(payload);
        if (response['success'] == true) {
          _showSnackBar('Variant added', Colors.green);
        } else {
          _showSnackBar(response['message'] ?? 'Failed to add variant', Colors.red);
        }
      } else {
        final response = await _inventoryService.updateVariant(variant['variant_id'], payload);
        if (response['success'] == true) {
          _showSnackBar('Variant updated', Colors.green);
        } else {
          _showSnackBar(response['message'] ?? 'Failed to update variant', Colors.red);
        }
      }
      await _loadInventory();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _deleteVariant(int variantId) async {
    final confirm = await _showDeleteConfirmation('variant');
    if (!confirm) return;

    setState(() {
      _isBusy = true;
    });
    try {
      final response = await _inventoryService.deleteVariant(variantId);
      if (response['success'] == true) {
        _showSnackBar('Variant deleted', Colors.green);
        await _loadInventory();
      } else {
        _showSnackBar(response['message'] ?? 'Failed to delete variant', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _openDealerDialog({Map<String, dynamic>? dealer}) async {
    final nameController = TextEditingController(text: dealer?['dealer_name'] ?? '');
    final emailController = TextEditingController(text: dealer?['email'] ?? '');
    final phoneController = TextEditingController(text: dealer?['phone'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dealer == null ? 'Add New Dealer' : 'Edit Dealer',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Dealer Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final payload = {
      'dealer_name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
    };

    setState(() {
      _isBusy = true;
    });

    try {
      if (dealer == null) {
        final response = await _inventoryService.createDealer(payload);
        if (response['success'] == true) {
          _showSnackBar('Dealer added', Colors.green);
        } else {
          _showSnackBar(response['message'] ?? 'Failed to add dealer', Colors.red);
        }
      } else {
        final response = await _inventoryService.updateDealer(dealer['dealer_id'], payload);
        if (response['success'] == true) {
          _showSnackBar('Dealer updated', Colors.green);
        } else {
          _showSnackBar(response['message'] ?? 'Failed to update dealer', Colors.red);
        }
      }
      await _loadInventory();
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _deleteDealer(int dealerId) async {
    final confirm = await _showDeleteConfirmation('dealer');
    if (!confirm) return;

    setState(() {
      _isBusy = true;
    });
    try {
      final response = await _inventoryService.deleteDealer(dealerId);
      if (response['success'] == true) {
        _showSnackBar('Dealer deleted', Colors.green);
        await _loadInventory();
      } else {
        _showSnackBar(response['message'] ?? 'Failed to delete dealer', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _openStockDialog() async {
    if (_pharmacy == null) return;

    final quantityController = TextEditingController();
    final stockingDateController = TextEditingController();
    final expiryDateController = TextEditingController();
    Map<String, dynamic>? selectedVariant;
    Map<String, dynamic>? selectedDealer;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Stock',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: InputDecoration(
                      labelText: 'Select Variant',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _medicines.expand((medicine) {
                      final variants = _variantsByMedicine[medicine['medicine_id']] ?? [];
                      return variants.map((variant) => DropdownMenuItem<Map<String, dynamic>>(
                            value: variant,
                            child: Text('${medicine['name']} - ${variant['strength'] ?? ''} ${variant['form'] ?? ''}'),
                          ));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedVariant = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: InputDecoration(
                      labelText: 'Select Dealer',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _dealers.map((dealer) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: dealer,
                        child: Text(dealer['dealer_name'] ?? dealer['email'] ?? 'Dealer'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDealer = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockingDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Stocking Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        stockingDateController.text = date.toIso8601String().split('T').first;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expiryDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        expiryDateController.text = date.toIso8601String().split('T').first;
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Add Stock'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    if (result != true) return;
    if (selectedVariant == null) {
      _showSnackBar('Please select a variant', Colors.red);
      return;
    }

    final payload = {
      'pharmacy_id': _pharmacy!['pharmacy_id'],
      'variant_id': selectedVariant!['variant_id'],
      'quantity': int.tryParse(quantityController.text.trim()) ?? 0,
      'stocking_date': stockingDateController.text.trim().isNotEmpty ? stockingDateController.text.trim() : null,
      'expiry_date': expiryDateController.text.trim().isNotEmpty ? expiryDateController.text.trim() : null,
      'dealer_id': selectedDealer?['dealer_id'],
    };

    setState(() {
      _isBusy = true;
    });

    try {
      final response = await _inventoryService.createStock(payload);
      if (response['success'] == true) {
        _showSnackBar('Stock added', Colors.green);
        await _loadInventory();
      } else {
        _showSnackBar(response['message'] ?? 'Failed to add stock', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Widget _buildInventoryTab() {
    final filteredMedicines = _medicines.where((medicine) {
      final query = _medicineSearchQuery.toLowerCase();
      final name = medicine['name']?.toString().toLowerCase() ?? '';
      final brand = medicine['brand']?.toString().toLowerCase() ?? '';
      final manufacturer = medicine['manufacturer']?.toString().toLowerCase() ?? '';
      return name.contains(query) || brand.contains(query) || manufacturer.contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadInventory,
      color: const Color(0xFF6366F1),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Medicines', subtitle: 'Manage your medicine catalog and variants.'),
          _buildSearchBar(
            hint: 'Search medicines by name, brand, or manufacturer',
            onChanged: (value) => setState(() => _medicineSearchQuery = value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredMedicines.length} medicines',
                    style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openMedicineDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Medicine'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...filteredMedicines.map((medicine) {
            final variants = _variantsByMedicine[medicine['medicine_id']] ?? [];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.medication, color: Color(0xFF6366F1), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medicine['name'] ?? 'Unnamed medicine',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${medicine['brand'] ?? 'Unknown brand'} • ${medicine['manufacturer'] ?? 'Unknown manufacturer'}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Text('Edit Medicine'),
                                  onTap: () => _openMedicineDialog(medicine: medicine),
                                ),
                                PopupMenuItem(
                                  child: const Text('Delete Medicine'),
                                  onTap: () => _deleteMedicine(medicine['medicine_id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (variants.isNotEmpty) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Variants',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 12),
                          ...variants.map((variant) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${variant['strength'] ?? ''} ${variant['form'] ?? ''}',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '\$${variant['price']?.toString() ?? 'N/A'}',
                                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF6366F1)),
                                        onPressed: () => _openVariantDialog(medicine, variant: variant),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        onPressed: () => _deleteVariant(variant['variant_id']),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openVariantDialog(medicine),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add Variant'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (filteredMedicines.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.medical_information, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No medicines found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 8),
                  const Text('Try a different search term or add a new medicine.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStockTab() {
    return RefreshIndicator(
      onRefresh: _loadInventory,
      color: const Color(0xFF6366F1),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Stock & Dealers', subtitle: 'Track inventory quantities and dealer contacts.'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stock Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_stock.length} records',
                          style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openStockDialog,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Add Stock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._stock.map((item) {
            final isExpiringSoon = item['expiry_date'] != null && DateTime.parse(item['expiry_date']).difference(DateTime.now()).inDays < 30;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.inventory, color: Color(0xFF6366F1), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['medicine_name'] ?? 'Unknown medicine',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Variant: ${item['strength'] ?? ''} ${item['form'] ?? ''}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Qty: ${item['quantity'] ?? 0}',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (item['dealer_name'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.business, size: 16, color: Color(0xFF6B7280)),
                          const SizedBox(width: 8),
                          Text(item['dealer_name'], style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (item['expiry_date'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.event, size: 16, color: isExpiringSoon ? Colors.red : const Color(0xFF6B7280)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Expires: ${item['expiry_date']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isExpiringSoon ? Colors.red : const Color(0xFF6B7280),
                                fontWeight: isExpiringSoon ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        onPressed: () async {
                          final confirm = await _showDeleteConfirmation('stock');
                          if (confirm) {
                            setState(() {
                              _isBusy = true;
                            });
                            final response = await _inventoryService.deleteStock(item['stock_id']);
                            if (response['success'] == true) {
                              _showSnackBar('Stock deleted', Colors.green);
                              await _loadInventory();
                            } else {
                              _showSnackBar(response['message'] ?? 'Unable to delete stock', Colors.red);
                            }
                            setState(() {
                              _isBusy = false;
                            });
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          if (_stock.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.inventory_2, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No stock records yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 8),
                  const Text('Start by adding stock from suppliers and dealers.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
          const SizedBox(height: 28),
          _buildSectionTitle('Dealers', subtitle: 'Contact details for your supplier network.'),
          _buildSearchBar(
            hint: 'Search dealers by name, email, or phone',
            onChanged: (value) => setState(() => _dealerSearchQuery = value),
          ),
          const SizedBox(height: 16),
          ..._dealers.where((dealer) {
            final query = _dealerSearchQuery.toLowerCase();
            final name = dealer['dealer_name']?.toString().toLowerCase() ?? '';
            final email = dealer['email']?.toString().toLowerCase() ?? '';
            final phone = dealer['phone']?.toString().toLowerCase() ?? '';
            return name.contains(query) || email.contains(query) || phone.contains(query);
          }).map((dealer) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business, color: Color(0xFF8B5CF6), size: 20),
                ),
                title: Text(
                  dealer['dealer_name'] ?? dealer['email'] ?? 'Dealer',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (dealer['email'] != null) Text('📧 ${dealer['email']}', style: const TextStyle(fontSize: 13)),
                    if (dealer['phone'] != null) Text('📱 ${dealer['phone']}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                isThreeLine: true,
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit Dealer'),
                      onTap: () => _openDealerDialog(dealer: dealer),
                    ),
                    PopupMenuItem(
                      child: const Text('Delete Dealer'),
                      onTap: () => _deleteDealer(dealer['dealer_id']),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          if (_dealers.where((dealer) {
                final query = _dealerSearchQuery.toLowerCase();
                final name = dealer['dealer_name']?.toString().toLowerCase() ?? '';
                final email = dealer['email']?.toString().toLowerCase() ?? '';
                final phone = dealer['phone']?.toString().toLowerCase() ?? '';
                return name.contains(query) || email.contains(query) || phone.contains(query);
              }).isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No dealers found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 8),
                  const Text('Search with a different name, email, or phone number.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pharmacy Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Medicines', icon: Icon(Icons.medical_services)),
            Tab(text: 'Stock', icon: Icon(Icons.inventory_2)),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              )
            : _pharmacy == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Pharmacy not found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please complete your pharmacy registration',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewContent(),
                      _buildInventoryTab(),
                      _buildStockTab(),
                    ],
                  ),
      ),
    );
  }
}