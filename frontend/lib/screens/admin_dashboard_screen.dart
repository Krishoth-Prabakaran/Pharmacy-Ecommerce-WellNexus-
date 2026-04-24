import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _stats;
  List<dynamic> _recentActivities = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  final List<String> _navItems = [
    'Dashboard',
    'Users',
    'Patients',
    'Doctors',
    'Pharmacies',
    'Orders',
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      _slideController.forward();
    });

    _loadDashboardStats();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final result = await _adminService.getDashboardStats();
      setState(() {
        _stats = result['stats'];
        _recentActivities = result['recentActivities'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Side Navigation Bar
          _buildSideNav(),

          // Main Content
          Expanded(
            child: Stack(
              children: [
                // Animated background pattern
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value * 0.05,
                        child: CustomPaint(
                          painter: BackgroundPatternPainter(),
                        ),
                      );
                    },
                  ),
                ),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Enhanced App Bar with animated elements
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E40AF),
                                Color(0xFF7C3AED),
                                Color(0xFFEC4899),
                                Color(0xFFF59E0B),
                              ],
                              stops: [0.0, 0.33, 0.66, 1.0],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E40AF).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _scaleAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _scaleAnimation.value,
                                            child: const Text(
                                              'WellNexus',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.refresh, color: Colors.white),
                                              onPressed: _loadDashboardStats,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.logout, color: Colors.white),
                                              onPressed: () async {
                                                await AuthService.logout();
                                                if (context.mounted) {
                                                  Navigator.pushReplacementNamed(context, '/login');
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  SlideTransition(
                                    position: _slideAnimation,
                                    child: const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Admin Dashboard',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            height: 1.2,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black26,
                                                offset: Offset(0, 2),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Manage your entire platform with complete control',
                                          style: TextStyle(
                                            color: Color(0xFFEDE9FE),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 220,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    _getNavIcon(index),
                    color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                  ),
                  title: Text(
                    _navItems[index],
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF1E40AF).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNavIcon(int index) {
    switch (index) {
      case 0: return Icons.dashboard;
      case 1: return Icons.people;
      case 2: return Icons.local_hospital;
      case 3: return Icons.medical_services;
      case 4: return Icons.store;
      case 5: return Icons.shopping_cart;
      default: return Icons.dashboard;
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
        ),
      );
    }

    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return const UsersManagementView();
      case 2:
        return const PatientsManagementView();
      case 3:
        return const DoctorsManagementView();
      case 4:
        return const PharmaciesManagementView();
      case 5:
        return const OrdersManagementView();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Card
        FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getUserData(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final userData = snapshot.data!;
              final username = userData['username'] ?? 'Admin';
              return SlideTransition(
                position: _slideAnimation,
                child: _buildWelcomeCard(username, userData['email'] ?? ''),
              );
            }
            return _buildLoadingCard();
          },
        ),

        const SizedBox(height: 32),

        // Stats Section
        SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'System Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Live',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Recent Activity
        SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(String username, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E40AF).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $username',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Administrator',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E40AF)),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_stats == null) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          '${_stats!['totalUsers'] ?? 0}',
          'Total Users',
          Icons.people_alt,
          const Color(0xFF6366F1),
        ),
        _buildStatCard(
          '${_stats!['totalPatients'] ?? 0}',
          'Patients',
          Icons.local_hospital,
          const Color(0xFF10B981),
        ),
        _buildStatCard(
          '${_stats!['totalDoctors'] ?? 0}',
          'Doctors',
          Icons.medical_services,
          const Color(0xFF8B5CF6),
        ),
        _buildStatCard(
          '${_stats!['totalPharmacists'] ?? 0}',
          'Pharmacists',
          Icons.store,
          const Color(0xFFF59E0B),
        ),
        _buildStatCard(
          '${_stats!['totalOrders'] ?? 0}',
          'Orders',
          Icons.shopping_cart,
          const Color(0xFFEC4899),
        ),
        _buildStatCard(
          'Rs. ${_stats!['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
          'Total Revenue',
          Icons.attach_money,
          const Color(0xFF22C55E),
        ),
        _buildStatCard(
          '${_recentActivities.length}',
          'Recent Activities',
          Icons.history,
          const Color(0xFF64748B),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No recent activity',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: _recentActivities.take(5).map((activity) {
          final type = activity['type'] ?? 'unknown';
          final description = activity['description'] ?? 'Unknown activity';
          final timestamp = activity['timestamp'] ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getActivityColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getActivityIcon(type),
                    color: _getActivityColor(type),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _formatTimestamp(timestamp),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'order':
        return const Color(0xFF6366F1);
      case 'user':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart;
      case 'user':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return timestamp.toString();
    }
  }
}

// ==================== USERS MANAGEMENT VIEW ====================
class UsersManagementView extends StatefulWidget {
  const UsersManagementView({super.key});

  @override
  State<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<UsersManagementView> {
  final AdminService _adminService = AdminService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminService.getAllUsers(
        page: _currentPage,
        role: _selectedRole,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _users = result['users'] ?? [];
        _totalPages = result['pagination']['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),

        // Search and Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _loadUsers(),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedRole,
              hint: const Text('All Roles'),
              items: ['patient', 'doctor', 'pharmacist', 'admin']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedRole = value);
                _loadUsers();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Users List
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_users.isEmpty)
          const Center(child: Text('No users found'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = _users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(user['role']),
                  child: Text(
                    (user['username'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user['username'] ?? 'Unknown'),
                subtitle: Text(user['email'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(
                        user['role'] ?? 'unknown',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: _getRoleColor(user['role']),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'change_role') {
                          _showRoleChangeDialog(user);
                        } else if (action == 'delete') {
                          _confirmDelete(user);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'change_role',
                          child: Text('Change Role'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete User', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

        // Pagination
        if (!_isLoading && _totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadUsers();
                        }
                      : null,
                ),
                Text('Page $_currentPage of $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _loadUsers();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'doctor':
        return Colors.blue;
      case 'pharmacist':
        return Colors.green;
      case 'patient':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showRoleChangeDialog(dynamic user) {
    String? selectedRole = user['role'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change role for ${user['username']}'),
            const SizedBox(height: 16),
            ...['patient', 'doctor', 'pharmacist', 'admin'].map((role) {
              return RadioListTile<String>(
                title: Text(role),
                value: role,
                groupValue: selectedRole,
                onChanged: (value) {
                  setState(() => selectedRole = value);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.updateUserRole(user['user_id'], selectedRole!);
                _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Role updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['username']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _adminService.deleteUser(user['user_id']);
                _loadUsers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ==================== PATIENTS MANAGEMENT VIEW ====================
class PatientsManagementView extends StatefulWidget {
  const PatientsManagementView({super.key});

  @override
  State<PatientsManagementView> createState() => _PatientsManagementViewState();
}

class _PatientsManagementViewState extends State<PatientsManagementView> {
  final AdminService _adminService = AdminService();
  List<dynamic> _patients = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminService.getAllPatients(
        page: _currentPage,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _patients = result['patients'] ?? [];
        _totalPages = result['pagination']['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Patient Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search patients...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _loadPatients(),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_patients.isEmpty)
          const Center(child: Text('No patients found'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _patients.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final patient = _patients[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                title: Text(
                  '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}',
                ),
                subtitle: Text(patient['phone'] ?? ''),
                trailing: Text(
                  patient['email'] ?? '',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              );
            },
          ),

        if (!_isLoading && _totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadPatients();
                        }
                      : null,
                ),
                Text('Page $_currentPage of $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _loadPatients();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== DOCTORS MANAGEMENT VIEW ====================
class DoctorsManagementView extends StatefulWidget {
  const DoctorsManagementView({super.key});

  @override
  State<DoctorsManagementView> createState() => _DoctorsManagementViewState();
}

class _DoctorsManagementViewState extends State<DoctorsManagementView> {
  final AdminService _adminService = AdminService();
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminService.getAllDoctors(
        page: _currentPage,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _doctors = result['doctors'] ?? [];
        _totalPages = result['pagination']['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doctor Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search doctors...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _loadDoctors(),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_doctors.isEmpty)
          const Center(child: Text('No doctors found'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _doctors.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final doctor = _doctors[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.medical_services, color: Colors.white),
                ),
                title: Text(
                  'Dr. ${doctor['first_name'] ?? ''} ${doctor['last_name'] ?? ''}',
                ),
                subtitle: Text(doctor['specialization'] ?? 'General Practice'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(doctor['phone'] ?? ''),
                    Text(
                      doctor['email'] ?? '',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),

        if (!_isLoading && _totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadDoctors();
                        }
                      : null,
                ),
                Text('Page $_currentPage of $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _loadDoctors();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== PHARMACIES MANAGEMENT VIEW ====================
class PharmaciesManagementView extends StatefulWidget {
  const PharmaciesManagementView({super.key});

  @override
  State<PharmaciesManagementView> createState() => _PharmaciesManagementViewState();
}

class _PharmaciesManagementViewState extends State<PharmaciesManagementView> {
  final AdminService _adminService = AdminService();
  List<dynamic> _pharmacies = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminService.getAllPharmacies(
        page: _currentPage,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _pharmacies = result['pharmacies'] ?? [];
        _totalPages = result['pagination']['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pharmacy Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search pharmacies...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => _loadPharmacies(),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_pharmacies.isEmpty)
          const Center(child: Text('No pharmacies found'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pharmacies.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final pharmacy = _pharmacies[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.store, color: Colors.white),
                ),
                title: Text(pharmacy['name'] ?? 'Unknown'),
                subtitle: Text(pharmacy['location'] ?? ''),
                trailing: Text(
                  pharmacy['phone'] ?? '',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              );
            },
          ),

        if (!_isLoading && _totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadPharmacies();
                        }
                      : null,
                ),
                Text('Page $_currentPage of $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _loadPharmacies();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ==================== ORDERS MANAGEMENT VIEW ====================
class OrdersManagementView extends StatefulWidget {
  const OrdersManagementView({super.key});

  @override
  State<OrdersManagementView> createState() => _OrdersManagementViewState();
}

class _OrdersManagementViewState extends State<OrdersManagementView> {
  final AdminService _adminService = AdminService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final result = await _adminService.getAllOrders(page: _currentPage);
      setState(() {
        _orders = result['orders'] ?? [];
        _totalPages = result['pagination']['totalPages'] ?? 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Orders Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_orders.isEmpty)
          const Center(child: Text('No orders found'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final order = _orders[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.shopping_cart, color: Colors.white),
                ),
                title: Text(
                  'Order #${order['order_id']} - ${order['pharmacy_name'] ?? ''}',
                ),
                subtitle: Text(
                  '${order['patient_first_name'] ?? ''} ${order['patient_last_name'] ?? ''} - Rs. ${order['total_amount'] ?? '0'}',
                ),
                trailing: Chip(
                  label: Text(
                    order['status'] ?? 'pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(order['status']),
                ),
              );
            },
          ),

        if (!_isLoading && _totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() => _currentPage--);
                          _loadOrders();
                        }
                      : null,
                ),
                Text('Page $_currentPage of $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages
                      ? () {
                          setState(() => _currentPage++);
                          _loadOrders();
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ==================== BACKGROUND PATTERN PAINTER ====================
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E40AF).withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (var i = 0; i < size.width / spacing; i++) {
      for (var j = 0; j < size.height / spacing; j++) {
        canvas.drawCircle(
          Offset(i * spacing, j * spacing),
          2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}