import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// صفحة التحاسب للموظف
class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _settlementHistory = [];
  bool _hasPendingSettlement = false;
  int _pendingOrdersCount = 0; // عدد الطلبات في التحاسب المعلق
  String _selectedTab = 'pending'; // pending, approved, rejected
  
  AnimationController? _animationController;
  
  int _currentProgress = 0;
  double _commissionRate = 5.0; // المبلغ لكل طلب بالدينار
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _animationController!.forward();
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final statsResult = await ApiService.getEmployeeSettlementStats();
      final historyResult = await ApiService.getEmployeeSettlementHistory();
      
      print('📊 Stats Result: $statsResult');
      
      if (mounted) {
        if (statsResult['success'] == true) {
          final stats = statsResult['stats'] ?? {};
          print('📊 Stats Object: $stats');
          
          final ordersCount = (stats['ordersCount'] ?? 0) as int;
          final totalSales = ((stats['totalSales'] ?? 0) as num).toDouble();
          final totalProfit = ((stats['totalProfit'] ?? 0) as num).toDouble();
          final commissionRate = ((stats['commissionRate'] ?? 5.0) as num).toDouble();
          final estimatedCommission = ((stats['estimatedCommission'] ?? 0) as num).toDouble();
          
          print('📊 Orders Count: $ordersCount');
          print('📊 Total Sales: $totalSales');
          print('📊 Commission Rate: $commissionRate');
          
          setState(() {
            _stats = {
              'ordersCount': ordersCount,
              'totalSales': totalSales,
              'totalProfit': totalProfit,
              'commissionRate': commissionRate,
              'estimatedCommission': estimatedCommission,
            };
            _currentProgress = ordersCount;
            _commissionRate = commissionRate;
          });
        } else {
          print('❌ Stats request failed: ${statsResult['message']}');
        }
        
        if (historyResult['success'] == true) {
          final history = List<Map<String, dynamic>>.from(
            historyResult['history'] ?? []
          );
          
          // التحقق من وجود طلب معلق وحساب عدد الطلبات المعلقة
          final hasPending = history.any((s) => s['status'] == 'pending');
          final pendingSettlement = history.firstWhere(
            (s) => s['status'] == 'pending',
            orElse: () => {},
          );
          // استخدام totalOrders بدلاً من ordersCount
          final pendingCount = pendingSettlement.isNotEmpty 
              ? ((pendingSettlement['totalOrders'] ?? pendingSettlement['ordersCount'] ?? 0) as num).toInt()
              : 0;
          
          print('🔍 Pending settlement: $pendingSettlement');
          print('🔍 Pending count: $pendingCount');
          
          setState(() {
            _settlementHistory = history;
            _hasPendingSettlement = hasPending;
            _pendingOrdersCount = pendingCount;
          });
        }
        
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading settlement data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        drawer: _buildDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: AppColors.primaryGold),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            'التحاسب',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textGold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primaryGold),
              onPressed: _loadData,
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGold,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildProgressCard(),
                        const SizedBox(height: 24),
                        _buildSettlementButton(),
                        const SizedBox(height: 24),
                        _buildSettlementHistory(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A4D68).withOpacity(0.3),
              Color(0xFF05668D).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFF00A8E8).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💰', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(
                  'إدارة أرباحك وعمولاتك',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Color(0xFF00D9FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'تابع تقدمك نحو الهدف واحصل على عمولتك',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Color(0xFF7DD3FC),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressCard() {
    final commissionPerOrder = _commissionRate;
    final estimatedCommission = (_stats['estimatedCommission'] as num?)?.toDouble() ?? 0.0;
    final ordersCount = (_stats['ordersCount'] as int?) ?? 0;
    final totalProfit = (_stats['totalProfit'] as num?)?.toDouble() ?? 0.0;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A4D68).withOpacity(0.4),
              Color(0xFF05668D).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF00D9FF).withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // عداد الطلبات المنجزة مع الشارة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$ordersCount',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Color(0xFF00D9FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 42,
                      ),
                    ),
                    Text(
                      'طلب منجز',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Color(0xFF7DD3FC),
                      ),
                    ),
                  ],
                ),
                if (_pendingOrdersCount > 0) ...[
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade600,
                          Colors.orange.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_pendingOrdersCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'قيد التحاسب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // معلومات العمولة
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00D9FF).withOpacity(0.15),
                    Color(0xFF00A8E8).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Color(0xFF00D9FF).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  // إجمالي الأرباح
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: Color(0xFF00FF88), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'إجمالي الأرباح',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Color(0xFF7DD3FC),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${NumberFormat('#,##0').format(totalProfit)} د.ع',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Color(0xFF00D9FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Color(0xFF00A8E8).withOpacity(0.3), height: 1),
                  const SizedBox(height: 10),
                  // عمولة لكل طلب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Color(0xFF00FF88), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'عمولة لكل طلب',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Color(0xFF7DD3FC),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${NumberFormat('#,##0').format(commissionPerOrder)} د.ع',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Color(0xFF00FF88),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Color(0xFF00A8E8).withOpacity(0.3), height: 1),
                  const SizedBox(height: 10),
                  // العمولة المستحقة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Color(0xFF00FF88), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'العمولة المستحقة',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Color(0xFF7DD3FC),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${NumberFormat('#,##0').format(estimatedCommission)} د.ع',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: Color(0xFF00FF88),
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettlementButton() {
    final ordersCount = (_stats['ordersCount'] as int?) ?? 0;
    final canRequestSettlement = ordersCount > 0 && !_hasPendingSettlement;
    
    String buttonText;
    IconData buttonIcon;
    Color buttonColor1, buttonColor2;
    
    if (_hasPendingSettlement) {
      buttonText = _pendingOrdersCount > 0 
          ? 'قيد الانتظار للموافقة $_pendingOrdersCount'
          : 'قيد الانتظار للموافقة';
      buttonIcon = Icons.hourglass_empty_rounded;
      buttonColor1 = Color(0xFFFFA726);
      buttonColor2 = Color(0xFFFF8A50);
    } else if (ordersCount > 0) {
      buttonText = 'طلب تحاسب';
      buttonIcon = Icons.send_rounded;
      buttonColor1 = Color(0xFF00D9FF);
      buttonColor2 = Color(0xFF00A8E8);
    } else {
      buttonText = 'لا يوجد طلبات للتحاسب';
      buttonIcon = Icons.info_outline;
      buttonColor1 = Color(0xFF1E3A5F);
      buttonColor2 = Color(0xFF0A2540);
    }
    
    return FadeIn(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: canRequestSettlement || _hasPendingSettlement
                ? [buttonColor1, buttonColor2]
                : [
                    buttonColor1.withOpacity(0.5),
                    buttonColor2.withOpacity(0.5),
                  ],
          ),
          boxShadow: canRequestSettlement || _hasPendingSettlement
              ? [
                  BoxShadow(
                    color: buttonColor1.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: canRequestSettlement ? _showSettlementRequestDialog : null,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    buttonIcon,
                    color: canRequestSettlement || _hasPendingSettlement
                        ? Colors.white
                        : Color(0xFF64B5F6).withOpacity(0.5),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    buttonText,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: canRequestSettlement || _hasPendingSettlement
                          ? Colors.white
                          : Color(0xFF64B5F6).withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettlementHistory() {
    if (_settlementHistory.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد سجل تحاسبات',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    
    // تصنيف التحاسبات حسب الحالة
    final pendingSettlements = _settlementHistory.where((s) => s['status'] == 'pending').toList();
    final approvedSettlements = _settlementHistory.where((s) => s['status'] == 'approved').toList();
    final rejectedSettlements = _settlementHistory.where((s) => s['status'] == 'rejected').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 سجل التحاسبات',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textGold,
          ),
        ),
        const SizedBox(height: 16),
        
        // نظام التبويبات
        Row(
          children: [
            _buildTabButton('قيد المراجعة', 'pending', pendingSettlements.length, Colors.orange),
            const SizedBox(width: 8),
            _buildTabButton('مقبول', 'approved', approvedSettlements.length, Colors.green),
            const SizedBox(width: 8),
            _buildTabButton('مرفوض', 'rejected', rejectedSettlements.length, Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        
        // عرض التحاسبات حسب التبويب المختار
        if (_selectedTab == 'pending')
          _buildSettlementsList(pendingSettlements),
        if (_selectedTab == 'approved')
          _buildSettlementsList(approvedSettlements),
        if (_selectedTab == 'rejected')
          _buildSettlementsList(rejectedSettlements),
      ],
    );
  }
  
  Widget _buildTabButton(String label, String tabValue, int count, Color color) {
    final isSelected = _selectedTab == tabValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabValue;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.15),
                    ],
                  )
                : null,
            color: isSelected ? null : AppColors.darkGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.textSecondary.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettlementsList(List<Map<String, dynamic>> settlements) {
    if (settlements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'لا توجد تحاسبات في هذا القسم',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    
    // إذا كان عدد التحاسبات أكثر من 5، نستخدم ExpansionTile
    if (settlements.length > 5) {
      return ExpansionTile(
        title: Text(
          'عرض جميع التحاسبات (${settlements.length})',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGold,
          ),
        ),
        initiallyExpanded: false,
        children: settlements.map((settlement) {
          return _buildHistoryCard(settlement);
        }).toList(),
      );
    }
    
    // إذا كان العدد 5 أو أقل، نعرضهم مباشرة
    return Column(
      children: settlements.map((settlement) {
        return _buildHistoryCard(settlement);
      }).toList(),
    );
  }
  
  Widget _buildHistoryCard(Map<String, dynamic> settlement) {
    final amount = ((settlement['commissionAmount'] ?? settlement['amount'] ?? 0) as num).toDouble();
    final totalOrders = ((settlement['totalOrders'] ?? settlement['total_orders'] ?? 0) as num).toInt();
    final status = settlement['status'] ?? 'pending';
    final createdAt = settlement['createdAt'] ?? settlement['created_at'] ?? '';
    final rejectionReason = settlement['rejectionReason'] ?? settlement['rejection_reason'] ?? '';
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'تم القبول ✓';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'مرفوض ✗';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'قيد المراجعة ⏳';
        statusIcon = Icons.pending;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
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
                      statusText,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (totalOrders > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$totalOrders طلب',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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
                    '${NumberFormat('#,##0').format(amount)} د.ع',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سبب الرفض: $rejectionReason',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showSettlementRequestDialog() {
    final estimatedCommission = (_stats['estimatedCommission'] as num?)?.toDouble() ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primaryGold, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.monetization_on, color: AppColors.primaryGold, size: 28),
            const SizedBox(width: 12),
            Text(
              'طلب تحاسب',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textGold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('عدد الطلبات', '$_currentProgress طلب', Icons.shopping_bag),
            const SizedBox(height: 12),
            _buildDetailRow(
              'العمولة المستحقة',
              '${NumberFormat('#,##0').format(estimatedCommission)} د.ع',
              Icons.attach_money,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'نسبة العمولة',
              '${_commissionRate.toStringAsFixed(1)}%',
              Icons.percent,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _confirmSettlement(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'تأكيد الطلب',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.pureBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _confirmSettlement(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.primaryGold),
      ),
    );
    
    try {
      // جمع معلومات التحاسب من الإحصائيات
      final ordersCount = (_stats['ordersCount'] as int?) ?? 0;
      final totalSales = (_stats['totalSales'] as num?)?.toDouble() ?? 0.0;
      final commissionAmount = (_stats['estimatedCommission'] as num?)?.toDouble() ?? 0.0;
      
      // إنشاء قائمة بمعرفات الطلبات (يمكنك الحصول عليها من API أو تمريرها فارغة)
      final List<int> orderIds = [];
      
      // إرسال طلب التحاسب مع جميع المعاملات المطلوبة
      final result = await ApiService.createSettlementRequest(
        totalOrders: ordersCount,
        totalSales: totalSales,
        commissionRate: _commissionRate,
        commissionAmount: commissionAmount,
        orderIds: orderIds,
      );
      
      if (mounted) {
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true
                  ? '✅ تم إرسال طلب التحاسب بنجاح'
                  : result['error'] ?? result['message'] ?? 'حدث خطأ',
              style: AppTextStyles.bodyMedium,
            ),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // إعادة تحميل البيانات في كلتا الحالتين
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy/MM/dd - hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.charcoal, AppColors.pureBlack],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                      ),
                      child: Icon(Icons.monetization_on, size: 40, color: AppColors.pureBlack),
                    ),
                    const SizedBox(height: 16),
                    Text('التحاسب', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold)),
                    Text('إدارة العمولات', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Divider(color: AppColors.glassWhite, thickness: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(Icons.home, 'الصفحة الرئيسية', () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/');
                    }),
                    Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                    _buildDrawerItem(Icons.subscriptions, 'إدارة الاشتراكات', () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/subscriptions');
                    }),
                    _buildDrawerItem(Icons.shopping_bag, 'إدارة الطلبات', () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/orders');
                    }),
                    _buildDrawerItem(Icons.archive, 'الأرشيف', () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/archive');
                    }),
                    _buildDrawerItem(Icons.monetization_on, 'التحاسب', () => Navigator.pop(context)),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.glassWhite, thickness: 1),
                    _buildDrawerItem(Icons.logout, 'تسجيل الخروج', () async {
                      await ApiService.logout();
                      if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGold),
      title: Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
      onTap: onTap,
      hoverColor: AppColors.glassWhite,
    );
  }
}
