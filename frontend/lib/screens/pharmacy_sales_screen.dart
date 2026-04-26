import 'package:flutter/material.dart';
import '../services/pharmacy_inventory_service.dart';
import '../services/auth_service.dart';

class PharmacySalesScreen extends StatefulWidget {
  const PharmacySalesScreen({super.key});

  @override
  State<PharmacySalesScreen> createState() => _PharmacySalesScreenState();
}

class _PharmacySalesScreenState extends State<PharmacySalesScreen> {
  final PharmacyInventoryService _inventoryService = PharmacyInventoryService();
  List<Map<String, dynamic>> _sales = [];
  Map<String, dynamic>? _salesStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userData = await AuthService.getUserData();
      if (userData == null || userData['role'] != 'pharmacist') {
        setState(() {
          _error = 'Unauthorized access';
          _isLoading = false;
        });
        return;
      }

      final salesResponse = await _inventoryService.getSalesByPharmacy(userData['user_id']);
      final statsResponse = await _inventoryService.getSalesStats(userData['user_id']);

      setState(() {
        _sales = List<Map<String, dynamic>>.from(salesResponse['sales'] ?? []);
        _salesStats = statsResponse['stats'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load sales: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSales,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildSalesContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSaleDialog,
        tooltip: 'Create New Sale',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSalesContent() {
    return Column(
      children: [
        if (_salesStats != null) _buildStatsCard(),
        Expanded(
          child: _sales.isEmpty
              ? const Center(
                  child: Text('No sales found. Create your first sale!'),
                )
              : ListView.builder(
                  itemCount: _sales.length,
                  itemBuilder: (context, index) {
                    final sale = _sales[index];
                    return _buildSaleCard(sale);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Total Sales', '${_salesStats!['total_sales'] ?? 0}'),
                _buildStatItem('Total Revenue', '₹${_salesStats!['total_revenue'] ?? 0}'),
                _buildStatItem('Today\'s Sales', '${_salesStats!['today_sales'] ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('Sale #${sale['sale_id']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${sale['sale_date']}'),
            Text('Total: ₹${sale['total_amount']}'),
            Text('Items: ${sale['item_count']}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => _showSaleDetails(sale),
        ),
      ),
    );
  }

  void _showCreateSaleDialog() {
    // TODO: Implement create sale dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create sale functionality coming soon!')),
    );
  }

  void _showSaleDetails(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sale #${sale['sale_id']} Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${sale['sale_date']}'),
              Text('Total Amount: ₹${sale['total_amount']}'),
              Text('Payment Method: ${sale['payment_method']}'),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              // TODO: Show sale items when available
              const Text('Sale items details will be shown here'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}