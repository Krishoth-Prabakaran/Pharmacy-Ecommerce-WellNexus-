import 'package:flutter/material.dart';
import '../services/pharmacy_inventory_service.dart';

class LowStockNotificationScreen extends StatefulWidget {
  const LowStockNotificationScreen({
    super.key,
    required this.pharmacyId,
    this.pharmacyName,
  });

  final int pharmacyId;
  final String? pharmacyName;

  @override
  State<LowStockNotificationScreen> createState() => _LowStockNotificationScreenState();
}

class _LowStockNotificationScreenState extends State<LowStockNotificationScreen> {
  final PharmacyInventoryService _inventoryService = PharmacyInventoryService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _lowStockItems = [];
  int _threshold = 10;

  @override
  void initState() {
    super.initState();
    _loadLowStockItems();
  }

  Future<void> _loadLowStockItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _inventoryService.getLowStock(widget.pharmacyId, threshold: _threshold);
      if (result['success'] == true) {
        setState(() {
          _lowStockItems = List<Map<String, dynamic>>.from(result['stock'] ?? []);
        });
      } else {
        _showSnackBar(result['message'] ?? 'Failed to load low stock items', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  Color _getSeverityColor(int quantity) {
    if (quantity == 0) return Colors.red;
    if (quantity <= 5) return Colors.orange;
    return Colors.amber;
  }

  String _getSeverityLabel(int quantity) {
    if (quantity == 0) return 'OUT OF STOCK';
    if (quantity <= 5) return 'CRITICAL';
    if (quantity <= 10) return 'LOW';
    return 'OK';
  }

  IconData _getSeverityIcon(int quantity) {
    if (quantity == 0) return Icons.error;
    if (quantity <= 5) return Icons.warning;
    return Icons.info;
  }

  @override
  Widget build(BuildContext context) {
    final outOfStockCount = _lowStockItems.where((item) => (item['quantity'] as int? ?? 0) == 0).length;
    final criticalCount = _lowStockItems.where((item) {
      final qty = item['quantity'] as int? ?? 0;
      return qty > 0 && qty <= 5;
    }).length;
    final lowCount = _lowStockItems.where((item) {
      final qty = item['quantity'] as int? ?? 0;
      return qty > 5 && qty <= 10;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Low Stock Alerts',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLowStockItems,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF9FAFB),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadLowStockItems,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Card
                    _buildHeaderCard(outOfStockCount, criticalCount, lowCount),

                    // Threshold Selector
                    _buildThresholdCard(),

                    // Low Stock Items List
                    if (_lowStockItems.isEmpty)
                      _buildEmptyState()
                    else
                      _buildStockList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard(int outOfStockCount, int criticalCount, int lowCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notification_important, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pharmacyName ?? 'Your Pharmacy',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        'Stock Alert Summary',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryChip('Out of Stock', outOfStockCount, Colors.red),
                const SizedBox(width: 8),
                _buildSummaryChip('Critical', criticalCount, Colors.orange),
                const SizedBox(width: 8),
                _buildSummaryChip('Low', lowCount, Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alert Threshold',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Show items with quantity <= $_threshold',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _threshold.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              label: '$_threshold',
              activeColor: const Color(0xFF6366F1),
              onChanged: (value) {
                setState(() {
                  _threshold = value.toInt();
                });
              },
              onChangeEnd: (value) {
                _loadLowStockItems();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: Colors.green.shade200),
          const SizedBox(height: 16),
          const Text(
            'All Stock Levels Good!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No items are below the threshold of $_threshold units.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '${_lowStockItems.length} item(s) need attention',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
        ),
        ..._lowStockItems.map((item) => _buildStockCard(item)),
      ],
    );
  }

  Widget _buildSummaryChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> item) {
    final quantity = item['quantity'] as int? ?? 0;
    final severityColor = _getSeverityColor(quantity);
    final severityLabel = _getSeverityLabel(quantity);
    final severityIcon = _getSeverityIcon(quantity);
    final medicineName = item['medicine_name'] ?? 'Unknown Medicine';
    final variantInfo = [
      if (item['strength'] != null) item['strength'],
      if (item['form'] != null) item['form'],
    ].join(' - ');
    final dealerName = item['dealer_name'] ?? 'No dealer assigned';
    final dealerPhone = item['dealer_phone'] ?? '';
    final dealerEmail = item['dealer_email'] ?? '';
    final expiryDate = item['expiry_date'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: severityColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with severity
            _buildCardHeader(severityColor, severityIcon, medicineName, variantInfo, severityLabel),
            // Details
            _buildCardDetails(severityColor, quantity, dealerName, dealerPhone, dealerEmail, expiryDate),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Color severityColor, IconData severityIcon, String medicineName, String variantInfo, String severityLabel) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(severityIcon, color: severityColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (variantInfo.isNotEmpty)
                  Text(
                    variantInfo,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              severityLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails(Color severityColor, int quantity, String dealerName, String dealerPhone, String dealerEmail, String? expiryDate) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Quantity: ',
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
              ),
              Text(
                '$quantity units',
                style: TextStyle(
                  color: severityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Dealer Info
          _buildDealerInfoCard(dealerName, dealerPhone, dealerEmail),
          // Expiry Date
          if (expiryDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Expiry: $expiryDate',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
          // Contact Dealer Button
          if (dealerPhone.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _showSnackBar('Contact dealer: $dealerPhone', Colors.blue);
                },
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Contact Dealer'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDealerInfoCard(String dealerName, String dealerPhone, String dealerEmail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Dealer Information',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dealerName,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          if (dealerPhone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(dealerPhone, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
          ],
          if (dealerEmail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.email, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(dealerEmail, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}