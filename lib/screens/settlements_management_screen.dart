import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// صفحة إدارة التحاسبات - للمدير فقط
class SettlementsManagementScreen extends StatefulWidget {
  const SettlementsManagementScreen({super.key});

  @override
  State<SettlementsManagementScreen> createState() => _SettlementsManagementScreenState();
}

class _SettlementsManagementScreenState extends State<SettlementsManagementScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingSettlements = [];
  List<Map<String, dynamic>> _allSettlements = [];
  late TabController _tabController;
  
  // نظام التحديد المتعدد
  bool _isSelectionMode = false;
  Set<int> _selectedSettlements = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final pendingResult = await ApiService.getPendingSettlements();
    final allResult = await ApiService.getAllSettlements();
    
    if (mounted) {
      setState(() {
        if (pendingResult['success'] == true) {
          _pendingSettlements = List<Map<String, dynamic>>.from(pendingResult['settlements'] ?? []);
        }
        
        if (allResult['success'] == true) {
          _allSettlements = List<Map<String, dynamic>>.from(allResult['settlements'] ?? []);
        }
        
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF0F0C29),
                Color(0xFF302B63),
                Color(0xFF24243E),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPendingTab(),
                            _buildAllSettlementsTab(),
                            _buildAnalyticsTab(),
                            _buildCommissionsTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // زر الرجوع
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 16),
            // العنوان
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إدارة التحاسبات',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إدارة طلبات التحاسب والعمولات',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            // زر التحديث
            IconButton(
              onPressed: _loadData,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primaryGold,
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryGold.withOpacity(0.2),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 8),
            // عداد الطلبات المعلقة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.primaryGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_pendingSettlements.length}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabBar() {
    return FadeIn(
      duration: const Duration(milliseconds: 700),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGold, Color(0xFFD4AF37)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          padding: const EdgeInsets.all(4),
          tabs: const [
            Tab(text: 'معلقة'),
            Tab(text: 'الكل'),
            Tab(text: 'تحليل'),
            Tab(text: 'العمولات'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPendingTab() {
    if (_pendingSettlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد طلبات معلقة',
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryGold,
      backgroundColor: const Color(0xFF1E1E2E),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _pendingSettlements.length,
        itemBuilder: (context, index) {
          final settlement = _pendingSettlements[index];
          return _buildPendingSettlementCard(settlement, index);
        },
      ),
    );
  }
  
  Widget _buildPendingSettlementCard(Map<String, dynamic> settlement, int index) {
    final employeeName = settlement['employeeName'] ?? 'غير محدد';
    final username = settlement['username'] ?? '';
    final totalOrders = (settlement['totalOrders'] as num?)?.toInt() ?? 0;
    final totalSales = (settlement['totalSales'] as num?)?.toDouble() ?? 0.0;
    final commissionRate = (settlement['commissionRate'] as num?)?.toDouble() ?? 0.0;
    final commissionAmount = (settlement['commissionAmount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = settlement['createdAt'] as String?;
    
    return FadeInUp(
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A2A3E).withOpacity(0.9),
              const Color(0xFF1E1E2E).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warning.withOpacity(0.3),
                        AppColors.warning.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.warning,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'معلق',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // تفاصيل التحاسب
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow2('عدد الطلبات', '$totalOrders طلب', Icons.shopping_cart_rounded),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow2('إجمالي المبيعات', '${totalSales.toStringAsFixed(0)} دينار', Icons.monetization_on_rounded),
                  const Divider(color: Colors.white10, height: 24),
                  _buildDetailRow2('عمولة كل طلب', '${commissionRate.toStringAsFixed(0)} دينار', Icons.attach_money_rounded),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGold.withOpacity(0.2),
                          AppColors.primaryGold.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المبلغ المستحق',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${commissionAmount.toStringAsFixed(0)} دينار',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            if (createdAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.white60,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 20),
            
            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(settlement),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    label: const Text('رفض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _approveSettlement(settlement),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text('موافقة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAllSettlementsTabOld() {
    if (_allSettlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد تحاسبات',
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryGold,
      backgroundColor: const Color(0xFF1E1E2E),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _allSettlements.length,
        itemBuilder: (context, index) {
          final settlement = _allSettlements[index];
          return _buildSettlementHistoryCard(settlement, index);
        },
      ),
    );
  }
  
  Widget _buildSettlementHistoryCard(Map<String, dynamic> settlement, int index) {
    final status = settlement['status'] as String;
    final employeeName = settlement['employeeName'] ?? 'غير محدد';
    final commissionAmount = (settlement['commissionAmount'] as num?)?.toDouble() ?? 0.0;
    final totalOrders = (settlement['totalOrders'] as num?)?.toInt() ?? 0;
    final createdAt = settlement['createdAt'] as String?;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'موافق عليه';
        break;
      case 'rejected':
        statusColor = AppColors.danger;
        statusIcon = Icons.cancel_rounded;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.pending_rounded;
        statusText = 'معلق';
    }
    
    return FadeInUp(
      duration: Duration(milliseconds: 200 + (index * 50)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A2A3E).withOpacity(0.6),
              const Color(0xFF1E1E2E).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employeeName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalOrders طلب • $statusText',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.white40,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${commissionAmount.toStringAsFixed(0)} دينار',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommissionsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!['success'] != true) {
          return Center(
            child: Text(
              'خطأ في تحميل الموظفين',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60),
            ),
          );
        }
        
        final users = (snapshot.data!['users'] as List)
            .where((user) => user['role'] != 'admin')
            .toList();
        
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline_rounded,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا يوجد موظفين',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildEmployeeCommissionCard(user, index);
          },
        );
      },
    );
  }
  
  Widget _buildEmployeeCommissionCard(Map<String, dynamic> user, int index) {
    final userId = user['id'] as int;
    final name = user['name'] ?? user['username'] ?? 'غير محدد';
    final username = user['username'] ?? '';
    
    return FadeInUp(
      duration: Duration(milliseconds: 200 + (index * 50)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A2A3E).withOpacity(0.6),
              const Color(0xFF1E1E2E).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGold.withOpacity(0.3),
                    AppColors.primaryGold.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.primaryGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@$username',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: ApiService.getEmployeeCommission(userId),
              builder: (context, snapshot) {
                final commissionRate = snapshot.hasData && snapshot.data!['success'] == true
                    ? snapshot.data!['commissionRate'] as double
                    : 5.0;
                
                return InkWell(
                  onTap: () => _showEditCommissionDialog(userId, name, commissionRate),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$commissionRate%',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_rounded,
                          color: AppColors.primaryGold,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow2(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Future<void> _approveSettlement(Map<String, dynamic> settlement) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.success.withOpacity(0.3),
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'تأكيد الموافقة',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من الموافقة على طلب التحاسب؟\nسيتم أرشفة جميع الطلبات المرتبطة.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white60,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'موافقة',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    if (confirm != true) return;
    
    final result = await ApiService.approveSettlement(settlement['id'] as int);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'تمت العملية'),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.danger,
        ),
      );
      
      if (result['success'] == true) {
        _loadData();
      }
    }
  }
  
  void _showRejectDialog(Map<String, dynamic> settlement) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.danger.withOpacity(0.3),
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.cancel_rounded,
                color: AppColors.danger,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'رفض التحاسب',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'يرجى كتابة سبب الرفض:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'مثال: بيانات غير صحيحة...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white40,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white60,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى كتابة سبب الرفض'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                final result = await ApiService.rejectSettlement(
                  settlement['id'] as int,
                  reason,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'تمت العملية'),
                      backgroundColor: result['success'] == true ? AppColors.success : AppColors.danger,
                    ),
                  );
                  
                  if (result['success'] == true) {
                    _loadData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'رفض',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showEditCommissionDialog(int userId, String employeeName, double currentRate) {
    final controller = TextEditingController(text: currentRate.toString());
    
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.primaryGold.withOpacity(0.3),
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.edit_rounded,
                color: AppColors.primaryGold,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تعديل العمولة',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employeeName,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'مبلؾ العمولة لكل طلب (دينار):',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '500',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white40,
                  ),
                  suffixText: 'دينار',
                  suffixStyle: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryGold,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إلغاء',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white60,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final rateStr = controller.text.trim();
                final rate = double.tryParse(rateStr);
                
                if (rate == null || rate <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('يرجى إدخال مبلغ صحيح أكبر من صفر'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                final result = await ApiService.updateEmployeeCommission(userId, rate);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'تمت العملية'),
                      backgroundColor: result['success'] == true ? AppColors.success : AppColors.danger,
                    ),
                  );
                  
                  if (result['success'] == true) {
                    setState(() {}); // لتحديث واجهة العمولات
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'حفظ',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        return 'اليوم ${DateFormat('HH:mm').format(date)}';
      } else if (diff.inDays == 1) {
        return 'أمس ${DateFormat('HH:mm').format(date)}';
      } else {
        return DateFormat('yyyy-MM-dd').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }
  
  // =============== تبويب "الكل" مع نظام التحديد المتعدد ===============
  
  Widget _buildAllSettlementsTab() {
    if (_allSettlements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد تحاسبات',
              style: AppTextStyles.headlineMedium.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        if (_isSelectionMode)
          _buildSelectionToolbar(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _allSettlements.length,
            itemBuilder: (context, index) {
              return _buildAllSettlementCard(_allSettlements[index], index);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSelectionToolbar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGold.withOpacity(0.9),
              AppColors.primaryGold.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              '${_selectedSettlements.length} محدد',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _selectAll,
              icon: const Icon(Icons.select_all, color: Colors.white),
              label: Text(
                'تحديد الكل',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.close, color: Colors.white),
              label: Text(
                'إلغاء',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selectedSettlements.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAllSettlementCard(Map<String, dynamic> settlement, int index) {
    final id = settlement['id'] as int;
    final isSelected = _selectedSettlements.contains(id);
    final status = settlement['status'] as String? ?? 'pending';
    
    Color statusColor;
    String statusText;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'مقبول';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'معلق';
    }
    
    return FadeInUp(
      duration: Duration(milliseconds: 300 + (index * 50)),
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedSettlements.add(id);
          });
        },
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedSettlements.remove(id);
                if (_selectedSettlements.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedSettlements.add(id);
              }
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [
                      AppColors.primaryGold.withOpacity(0.3),
                      AppColors.primaryGold.withOpacity(0.1),
                    ]
                  : [
                      const Color(0xFF2A2A3E).withOpacity(0.9),
                      const Color(0xFF1E1E2E).withOpacity(0.9),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGold
                  : statusColor.withOpacity(0.3),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppColors.primaryGold : Colors.white60,
                    size: 28,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            settlement['employeeName'] ?? 'موظف',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${settlement['totalOrders']} طلب • ${NumberFormat('#,##0').format(settlement['commissionAmount'])} دينار',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _selectAll() {
    setState(() {
      _selectedSettlements = _allSettlements.map((s) => s['id'] as int).toSet();
    });
  }
  
  void _clearSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedSettlements.clear();
    });
  }
  
  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'تأكيد الحذف',
          style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
        ),
        content: Text(
          'هل أنت متأكد من حذف ${_selectedSettlements.length} تحاسب؟',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'حذف',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      // حذف التحاسبات من الخادم (بما فيها الموافق عليها والمرفوضة)
      int deletedCount = 0;
      int failedCount = 0;
      
      for (final settlementId in _selectedSettlements) {
        try {
          final result = await ApiService.deleteSettlement(settlementId);
          if (result['success'] == true) {
            deletedCount++;
          } else {
            failedCount++;
            print('فشل حذف التحاسب $settlementId: ${result['message']}');
          }
        } catch (e) {
          failedCount++;
          print('خطأ في حذف التحاسب $settlementId: $e');
        }
      }
      
      // إعادة تحميل البيانات من الخادم لعرض التحديثات
      await _loadData();
      _clearSelection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failedCount > 0 
                ? 'تم حذف $deletedCount تحاسب، فشل $failedCount'
                : 'تم حذف $deletedCount تحاسب بنجاح'
            ),
            backgroundColor: failedCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // =============== تبويب التحليل مع الرسوم البيانية ===============
  
  Widget _buildAnalyticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadEmployeesAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'لا توجد بيانات للتحليل',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white60),
            ),
          );
        }
        
        final employeesData = snapshot.data!;
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: employeesData.length,
          itemBuilder: (context, index) {
            final employeeName = employeesData.keys.elementAt(index);
            final employeeData = employeesData[employeeName];
            return _buildEmployeeChart(employeeName, employeeData, index);
          },
        );
      },
    );
  }
  
  Future<Map<String, dynamic>> _loadEmployeesAnalytics() async {
    try {
      // جلب قائمة الموظفين الحقيقيين
      final usersResult = await ApiService.getUsers();
      
      if (usersResult['success'] != true) {
        return {};
      }
      
      final users = (usersResult['users'] as List)
          .where((user) => user['role'] != 'admin')
          .toList();
      
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      
      final Map<String, dynamic> employeesData = {};
      
      // جلب بيانات كل موظف
      for (final user in users) {
        final username = user['username'] as String;
        final employeeName = user['name'] as String;
        
        // جلب إحصائيات الموظف والتحاسبات
        final dailyOrders = await _getEmployeeDailyOrders(username, firstDay, lastDay);
        final settlementDays = await _getEmployeeSettlementDays(username, firstDay, lastDay);
        
        final totalOrders = dailyOrders.values.fold<int>(0, (sum, count) => sum + count);
        
        employeesData[employeeName] = {
          'dailyOrders': dailyOrders,
          'settlements': settlementDays,
          'totalOrders': totalOrders,
        };
      }
      
      return employeesData;
    } catch (e) {
      print('Error loading analytics: $e');
      return {};
    }
  }
  
  Future<Map<int, int>> _getEmployeeDailyOrders(String username, DateTime firstDay, DateTime lastDay) async {
    try {
      // جلب جميع الطلبات (المؤرشفة وغير المؤرشفة) من إدارة الطلبات
      final ordersResult = await ApiService.getOrders();
      final archivedResult = await ApiService.getArchivedOrders();
      
      if (ordersResult['success'] != true) {
        return {};
      }
      
      // دمج الطلبات المؤرشفة وغير المؤرشفة
      final allOrders = List<Map<String, dynamic>>.from(ordersResult['orders'] ?? []);
      if (archivedResult['success'] == true) {
        allOrders.addAll(List<Map<String, dynamic>>.from(archivedResult['orders'] ?? []));
      }
      
      print('📦 Total orders loaded: ${allOrders.length}');
      
      // فلترة الطلبات حسب الموظف والشهر الحالي
      final employeeOrders = allOrders.where((order) {
        final orderUsername = order['employee_username'] as String?;
        if (orderUsername != username) return false;
        
        try {
          final createdAt = DateTime.parse(order['created_at'] as String);
          return createdAt.year == firstDay.year && 
                 createdAt.month == firstDay.month;
        } catch (e) {
          return false;
        }
      }).toList();
      
      print('📊 Orders for $username in ${firstDay.month}/${firstDay.year}: ${employeeOrders.length}');
      
      // تجميع الطلبات حسب اليوم (عدد يومي فقط)
      final Map<int, int> dailyOrders = {};
      final now = DateTime.now();
      
      // تجميع الطلبات حسب اليوم
      for (int day = 1; day <= lastDay.day; day++) {
        // الأيام المستقبلية = 0
        final dayDate = DateTime(firstDay.year, firstDay.month, day);
        if (dayDate.isAfter(now)) {
          dailyOrders[day] = 0;
          continue;
        }
        
        dailyOrders[day] = 0;
      }
      
      for (final order in employeeOrders) {
        try {
          final createdAt = DateTime.parse(order['created_at'] as String);
          final day = createdAt.day;
          dailyOrders[day] = (dailyOrders[day] ?? 0) + 1;
        } catch (e) {
          print('⚠️ Error parsing order date: $e');
        }
      }
      
      // طباعة الأيام التي فيها طلبات
      dailyOrders.forEach((day, count) {
        if (count > 0) {
          print('📈 Day $day: $count orders');
        }
      });
      
      return dailyOrders;
    } catch (e) {
      print('❌ Error loading daily orders: $e');
      return {};
    }
  }
  
  Future<Map<String, dynamic>> _getEmployeeSettlementDays(String username, DateTime firstDay, DateTime lastDay) async {
    // جلب جميع التحاسبات للموظف مع بياناتها الكاملة
    final settlements = _allSettlements.where((s) => 
      s['username'] == username
    ).toList();
    
    // كل تحاسب يحفظ ببياناته الكاملة: ID, day, totalOrders, status
    final Map<String, dynamic> settlementData = {
      'approved': <Map<String, dynamic>>[],    // قائمة التحاسبات الموافق عليها
      'rejected': <Map<String, dynamic>>[],    // قائمة التحاسبات المرفوضة
      'pending': <Map<String, dynamic>>[],     // قائمة التحاسبات قيد المراجعة
    };
    
    print('🔍 Settlements for $username: ${settlements.length}');
    
    for (final settlement in settlements) {
      try {
        final createdAt = DateTime.parse(settlement['createdAt'] as String);
        final status = settlement['status'] as String;
        
        if (createdAt.month == firstDay.month && createdAt.year == firstDay.year) {
          final day = createdAt.day;
          final settlementId = settlement['id'] as int;
          final totalOrders = (settlement['totalOrders'] as num?)?.toInt() ?? 0;
          
          // حفظ بيانات التحاسب الكاملة
          final settlementInfo = {
            'id': settlementId,
            'day': day,
            'totalOrders': totalOrders,
            'createdAt': createdAt.toIso8601String(),
          };
          
          if (status == 'approved') {
            (settlementData['approved'] as List<Map<String, dynamic>>).add(settlementInfo);
            print('✅ Approved settlement #$settlementId on day $day with $totalOrders orders');
          } else if (status == 'rejected') {
            (settlementData['rejected'] as List<Map<String, dynamic>>).add(settlementInfo);
            print('❌ Rejected settlement #$settlementId on day $day with $totalOrders orders');
          } else if (status == 'pending') {
            (settlementData['pending'] as List<Map<String, dynamic>>).add(settlementInfo);
            print('⏳ Pending settlement #$settlementId on day $day with $totalOrders orders');
          }
        }
      } catch (e) {
        print('⚠️ Error parsing settlement: $e');
      }
    }
    
    print('📊 Final counts - Approved: ${settlementData['approved'].length}, Rejected: ${settlementData['rejected'].length}, Pending: ${settlementData['pending'].length}');
    
    return settlementData;
  }
  
  Map<int, int> _generateMockData(DateTime firstDay, DateTime lastDay) {
    final data = <int, int>{};
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    
    for (int day = 1; day <= lastDay.day; day++) {
      data[day] = (day + random) % 7 + random % 5;
    }
    
    return data;
  }
  
  Widget _buildEmployeeChart(String employeeName, Map<String, dynamic> data, int index) {
    final dailyOrders = data['dailyOrders'] as Map<int, int>;
    final settlementData = data['settlements'] as Map<String, dynamic>;
        // حساب إجمالي الطلبات من مجموع الطلبات اليومية
        final totalOrders = dailyOrders.values.fold<int>(0, (sum, count) => sum + count);    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    // حساب عدد التحاسبات حسب الحالة
    final approvedCount = (settlementData['approved'] as List).length;
    final rejectedCount = (settlementData['rejected'] as List).length;
    final pendingCount = (settlementData['pending'] as List).length;
    final totalSettlements = approvedCount + rejectedCount + pendingCount;
    
    return FadeInUp(
      duration: Duration(milliseconds: 400 + (index * 100)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A2A3E).withOpacity(0.9),
              const Color(0xFF1E1E2E).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryGold.withOpacity(0.3),
                        AppColors.primaryGold.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primaryGold,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'إجمالي الطلبات: $totalOrders',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$totalSettlements تحاسب',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // الرسم البياني (مع خاصية التكبير والتحريك)
            Listener(
              onPointerSignal: (pointerSignal) {
                // امتصاص حدث السكرول داخل الرسم البياني لمنع انتقاله للصفحة
              },
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    constrained: false,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 56,
                      height: 250,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                      child: _buildAnimatedChart(dailyOrders, settlementData, daysInMonth, employeeName),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // الأسطورة مع الألوان المختلفة (ترتيب أفقي)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('الطلبات', Colors.blue),
                  const SizedBox(width: 16),
                  if (approvedCount > 0) ...[
                    _buildLegendItem('موافق ($approvedCount)', Colors.green),
                    const SizedBox(width: 16),
                  ],
                  if (rejectedCount > 0) ...[
                    _buildLegendItem('مرفوض ($rejectedCount)', Colors.red),
                    const SizedBox(width: 16),
                  ],
                  if (pendingCount > 0)
                    _buildLegendItem('قيد المراجعة ($pendingCount)', Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedChart(Map<int, int> dailyOrders, Map<String, dynamic> settlementData, int daysInMonth, String employeeName) {
    // حساب الحد الأقصى للطلبات اليومية
    final maxDailyOrders = dailyOrders.values.isEmpty 
        ? 0.0 
        : dailyOrders.values.reduce((a, b) => a > b ? a : b).toDouble();
    
    // حساب الحد الأقصى للتحاسبات
    double maxSettlementOrders = 0.0;
    
    for (final settlement in (settlementData['approved'] as List<Map<String, dynamic>>)) {
      final orders = (settlement['totalOrders'] as int).toDouble();
      if (orders > maxSettlementOrders) maxSettlementOrders = orders;
    }
    for (final settlement in (settlementData['rejected'] as List<Map<String, dynamic>>)) {
      final orders = (settlement['totalOrders'] as int).toDouble();
      if (orders > maxSettlementOrders) maxSettlementOrders = orders;
    }
    for (final settlement in (settlementData['pending'] as List<Map<String, dynamic>>)) {
      final orders = (settlement['totalOrders'] as int).toDouble();
      if (orders > maxSettlementOrders) maxSettlementOrders = orders;
    }
    
    // الحد الأقصى النهائي (أعلى قيمة بين الطلبات والتحاسبات)
    final maxOrdersValue = [maxDailyOrders, maxSettlementOrders].reduce((a, b) => a > b ? a : b);
    
    // حساب الحد الأقصى الديناميكي (50 كحد أدنى)
    final maxOrders = maxOrdersValue <= 50 
        ? 50.0 
        : ((maxOrdersValue / 50).ceil() * 50).toDouble();
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return MouseRegion(
          child: CustomPaint(
            painter: _ChartPainter(
              dailyOrders: dailyOrders,
              approvedSettlements: List<Map<String, dynamic>>.from(settlementData['approved'] ?? []),
              rejectedSettlements: List<Map<String, dynamic>>.from(settlementData['rejected'] ?? []),
              pendingSettlements: List<Map<String, dynamic>>.from(settlementData['pending'] ?? []),
              daysInMonth: daysInMonth,
              maxOrders: maxOrders,
              animationValue: value,
              employeeName: employeeName,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============== رسام الرسم البياني المخصص ===============

class _ChartPainter extends CustomPainter {
  final Map<int, int> dailyOrders;
  final List<Map<String, dynamic>> approvedSettlements;
  final List<Map<String, dynamic>> rejectedSettlements;
  final List<Map<String, dynamic>> pendingSettlements;
  final int daysInMonth;
  final double maxOrders;
  final double animationValue;
  final String employeeName;
  
  _ChartPainter({
    required this.dailyOrders,
    required this.approvedSettlements,
    required this.rejectedSettlements,
    required this.pendingSettlements,
    required this.daysInMonth,
    required this.maxOrders,
    required this.animationValue,
    required this.employeeName,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // منطقة الرسم الفعلية (نترك مساحة للأرقام)
    const bottomPadding = 35.0; // مساحة لأرقام الأيام
    const topPadding = 15.0;
    const leftPadding = 45.0; // مساحة لأرقام محور Y
    const rightPadding = 15.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width - leftPadding - rightPadding;
    
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.withOpacity(0.4),
          Colors.blue.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight));
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    final path = Path();
    final fillPath = Path();
    
    // حساب العرض لكل يوم - استخدام كامل العرض
    final dayWidth = chartWidth / (daysInMonth - 1).clamp(1, double.infinity);
    final startX = leftPadding;
    
    // رسم الخط والمنطقة المملوءة
    bool firstPoint = true;
    for (int day = 1; day <= daysInMonth; day++) {
      final orders = (dailyOrders[day] ?? 0).toDouble();
      final x = startX + ((day - 1) * dayWidth);
      final y = topPadding + chartHeight - (orders / maxOrders * chartHeight) * animationValue;
      
      if (firstPoint) {
        path.moveTo(x, y);
        fillPath.moveTo(x, topPadding + chartHeight);
        fillPath.lineTo(x, y);
        firstPoint = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(startX + ((daysInMonth - 1) * dayWidth), topPadding + chartHeight);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
    
    // رسم محور Y (الأرقام على اليسار من 0 إلى maxOrders)
    for (int i = 0; i <= 5; i++) {
      final value = (maxOrders / 5 * i).round();
      final y = topPadding + chartHeight - (i / 5 * chartHeight);
      
      // رسم الأرقام على اليسار
      textPainter.text = TextSpan(
        text: '$value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height / 2),
      );
      
      // رسم خط أفقي خفيف
      if (i > 0) {
        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(leftPadding, y),
          Offset(leftPadding + chartWidth, y),
          linePaint,
        );
      }
    }
    
    // رسم جميع أرقام الأيام لدقة أكبر
    for (int day = 1; day <= daysInMonth; day++) {
      final x = startX + ((day - 1) * dayWidth);
      
      // رسم الأرقام كل 5 أيام + اليوم الأول والأخير
      if (day == 1 || day == daysInMonth || day % 5 == 0) {
        textPainter.text = TextSpan(
          text: '$day',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - 22),
        );
        
        // خط رأسي قوي للفواصل الرئيسية
        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, topPadding),
          Offset(x, topPadding + chartHeight),
          linePaint,
        );
      } else {
        // خط رأسي خفيف جداً لباقي الأيام
        final linePaint = Paint()
          ..color = Colors.white.withOpacity(0.03)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x, topPadding),
          Offset(x, topPadding + chartHeight),
          linePaint,
        );
      }
    }
    
    // رسم نقاط التحاسب بألوان مختلفة - كل تحاسب نقطة مستقلة
    
    // رسم جميع التحاسبات الموافق عليها (أخضر)
    for (final settlement in approvedSettlements) {
      _drawSettlementPointWithOrders(
        canvas, 
        settlement, 
        Colors.green, 
        startX, 
        dayWidth, 
        topPadding, 
        chartHeight, 
        maxOrders, 
        animationValue,
      );
    }
    
    // رسم جميع التحاسبات المرفوضة (أحمر)
    for (final settlement in rejectedSettlements) {
      _drawSettlementPointWithOrders(
        canvas, 
        settlement, 
        Colors.red, 
        startX, 
        dayWidth, 
        topPadding, 
        chartHeight, 
        maxOrders, 
        animationValue,
      );
    }
    
    // رسم جميع التحاسبات قيد المراجعة (برتقالي)
    for (final settlement in pendingSettlements) {
      _drawSettlementPointWithOrders(
        canvas, 
        settlement, 
        Colors.orange, 
        startX, 
        dayWidth, 
        topPadding, 
        chartHeight, 
        maxOrders, 
        animationValue,
      );
    }
  }
  
  void _drawSettlementPointWithOrders(
    Canvas canvas, 
    Map<String, dynamic> settlement, 
    Color color,
    double startX,
    double dayWidth,
    double topPadding,
    double chartHeight,
    double maxOrders,
    double animationValue,
  ) {
    final day = settlement['day'] as int;
    final totalOrders = (settlement['totalOrders'] as int).toDouble();
    final settlementId = settlement['id'] as int;
    
    if (day > 0 && day <= daysInMonth) {
      // حساب موقع X الأساسي
      final baseX = startX + ((day - 1) * dayWidth);
      
      // إضافة إزاحة بسيطة بناءً على ID لتجنب تداخل النقاط
      final offsetMultiplier = (settlementId % 5) - 2; // -2 إلى +2
      final x = baseX + (offsetMultiplier * 3.0); // إزاحة 3 بكسل
      
      // حساب الارتفاع بناءً على عدد الطلبات في هذا التحاسب
      final y = topPadding + chartHeight - (totalOrders / maxOrders * chartHeight) * animationValue;
      
      // دائرة خارجية مع توهج
      canvas.drawCircle(
        Offset(x, y),
        12 * animationValue,
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.fill,
      );
      
      // دائرة متوسطة
      canvas.drawCircle(
        Offset(x, y),
        8 * animationValue,
        Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.fill,
      );
      
      // دائرة داخلية بيضاء
      canvas.drawCircle(
        Offset(x, y),
        5 * animationValue,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      
      // نقطة ملونة في المركز
      canvas.drawCircle(
        Offset(x, y),
        2.5 * animationValue,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      
      // رسم معلومات التحاسب على النقطة (عدد الطلبات)
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${totalOrders.toInt()}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - 20),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
