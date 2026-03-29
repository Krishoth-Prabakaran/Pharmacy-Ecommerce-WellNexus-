import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/pharmacy_service.dart';
import '../services/pharmacy_inventory_service.dart';

class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key, this.pharmacy});

  final Map<String, dynamic>? pharmacy;

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  final PharmacyInventoryService _inventoryService = PharmacyInventoryService();
  final PharmacyService _pharmacyService = PharmacyService();
  bool _isLoading = true;
  bool _isBusy = false;
  Map<String, dynamic>? _pharmacy;
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _dealers = [];
  List<Map<String, dynamic>> _stock = [];
  final Map<int, List<Map<String, dynamic>>> _variantsByMedicine = {};

  @override
  void initState() {
    super.initState();
    _loadData();
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
    await AuthService.logout();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ]
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ],
          ),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back, Pharmacist!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(
                      _pharmacy?['pharmacy_name'] ?? 'Your Pharmacy',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pharmacy?['address'] ?? 'No address provided yet',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.timer, color: Colors.white70, size: 18),
                          backgroundColor: Colors.white24,
                          label: Text('Open: ${_pharmacy?['open_time'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
                        ),
                        Chip(
                          avatar: const Icon(Icons.timer_off, color: Colors.white70, size: 18),
                          backgroundColor: Colors.white24,
                          label: Text('Close: ${_pharmacy?['close_time'] ?? 'N/A'}', style: const TextStyle(color: Colors.white)),
                        ),
                        Chip(
                          avatar: const Icon(Icons.phone, color: Colors.white70, size: 18),
                          backgroundColor: Colors.white24,
                          label: Text(_pharmacy?['phone'] ?? 'No phone', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard('Medicines', '$totalMedicines', Icons.medical_services, Colors.indigo),
                  const SizedBox(width: 12),
                  _buildStatCard('Variants', '$totalVariants', Icons.category, Colors.deepPurple),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard('Dealers', '$totalDealers', Icons.handshake, Colors.teal),
                  const SizedBox(width: 12),
                  _buildStatCard('Stock Qty', '$totalStock', Icons.inventory_2, Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                            icon: const Icon(Icons.add_box),
                            label: const Text('Add Medicine'),
                            onPressed: () => _openMedicineDialog(),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                            icon: const Icon(Icons.add_task),
                            label: const Text('Add Stock'),
                            onPressed: _openStockDialog,
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Dealer'),
                            onPressed: () => _openDealerDialog(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
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
        return AlertDialog(
          title: Text(medicine == null ? 'Add Medicine' : 'Edit Medicine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: manufacturerController, decoration: const InputDecoration(labelText: 'Manufacturer (optional)')),
              TextField(controller: brandController, decoration: const InputDecoration(labelText: 'Brand')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
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
          _showSnackBar('Medicine added', Colors.green);
        } else {
          _showSnackBar(response['message'] ?? 'Failed to add medicine', Colors.red);
        }
      } else {
        final response = await _inventoryService.updateMedicine(medicine['medicine_id'], payload);
        if (response['success'] == true) {
          _showSnackBar('Medicine updated', Colors.green);
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

  Future<void> _openVariantDialog(Map<String, dynamic> medicine, {Map<String, dynamic>? variant}) async {
    final strengthController = TextEditingController(text: variant?['strength'] ?? '');
    final formController = TextEditingController(text: variant?['form'] ?? '');
    final priceController = TextEditingController(text: variant?['price']?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(variant == null ? 'Add Variant' : 'Edit Variant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: strengthController, decoration: const InputDecoration(labelText: 'Strength')),
              TextField(controller: formController, decoration: const InputDecoration(labelText: 'Form')),
              TextField(controller: priceController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
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
        return AlertDialog(
          title: Text(dealer == null ? 'Add Dealer' : 'Edit Dealer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Dealer Name')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
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
          return AlertDialog(
            title: const Text('Add Stock'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(labelText: 'Variant'),
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
                    value: selectedVariant,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    decoration: const InputDecoration(labelText: 'Dealer'),
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
                    value: selectedDealer,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: stockingDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Stocking Date'),
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
                  const SizedBox(height: 10),
                  TextField(
                    controller: expiryDateController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Expiry Date'),
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
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
            ],
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
    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Medicines', subtitle: 'Manage your medicine catalog and variants.'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${_medicines.length}', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              ElevatedButton.icon(
                onPressed: () => _openMedicineDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Medicine'),
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._medicines.map((medicine) {
            final variants = _variantsByMedicine[medicine['medicine_id']] ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            medicine['name'] ?? 'Unnamed medicine',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(onPressed: () => _openMedicineDialog(medicine: medicine), icon: const Icon(Icons.edit)),
                        IconButton(onPressed: () => _deleteMedicine(medicine['medicine_id']), icon: const Icon(Icons.delete_forever, color: Colors.redAccent)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${medicine['brand'] ?? 'Unknown brand'} • ${medicine['manufacturer'] ?? 'Unknown manufacturer'}', style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: variants.isEmpty
                          ? [
                              Chip(
                                label: const Text('No variants created yet'),
                                backgroundColor: Colors.grey.shade100,
                              ),
                            ]
                          : variants.map((variant) {
                              return Chip(
                                label: Text('${variant['strength'] ?? ''} ${variant['form'] ?? ''}'),
                                avatar: const Icon(Icons.medication, size: 18),
                                onDeleted: () => _deleteVariant(variant['variant_id']),
                                deleteIconColor: Colors.redAccent,
                              );
                            }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openVariantDialog(medicine),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Variant'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          if (_medicines.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  Icon(Icons.medical_information, size: 72, color: Colors.blue.shade200),
                  const SizedBox(height: 16),
                  const Text('No medicines yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add your first medicine to begin building inventory.', textAlign: TextAlign.center),
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Stock & Dealers', subtitle: 'Track inventory quantities and dealer contacts.'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stock Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('${_stock.length} records', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openStockDialog,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add Stock'),
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ..._stock.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['medicine_name'] ?? 'Unknown medicine', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Variant: ${item['strength'] ?? ''} ${item['form'] ?? ''}')),
                        Chip(label: Text('Qty: ${item['quantity'] ?? 0}')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Dealer: ${item['dealer_name'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[800])),
                    if (item['expiry_date'] != null) ...[
                      const SizedBox(height: 6),
                      Text('Expiry: ${item['expiry_date']}', style: TextStyle(color: Colors.grey[800])),
                    ],
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
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
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          if (_stock.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  Icon(Icons.inventory_2, size: 72, color: Colors.green.shade200),
                  const SizedBox(height: 16),
                  const Text('No stock records yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Start by adding stock from suppliers and dealers.', textAlign: TextAlign.center),
                ],
              ),
            ),
          const SizedBox(height: 28),
          _buildSectionTitle('Dealers', subtitle: 'Contact details for your supplier network.'),
          ..._dealers.map((dealer) {
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: ListTile(
                title: Text(dealer['dealer_name'] ?? dealer['email'] ?? 'Dealer'),
                subtitle: Text('Email: ${dealer['email'] ?? 'N/A'}\nPhone: ${dealer['phone'] ?? 'N/A'}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _openDealerDialog(dealer: dealer)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteDealer(dealer['dealer_id'])),
                  ],
                ),
              ),
            );
          }).toList(),
          if (_dealers.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 72, color: Colors.teal.shade200),
                  const SizedBox(height: 16),
                  const Text('No dealers yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add dealer contacts so you can manage stock sourcing easily.', textAlign: TextAlign.center),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pharmacy Dashboard'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Medicines'),
              Tab(text: 'Stock'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pharmacy == null
                ? const Center(child: Text('Pharmacy not found'))
                : TabBarView(
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
