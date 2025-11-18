import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// صفحة الإحصائيات - للمدير فقط
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  late AnimationController _animationController;
  final Map<String, bool> _visiblePaymentMethods = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _loadStatistics();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getOrdersStatistics();
      if (response['success'] == true && mounted) {
        final stats = response['statistics'];
        
        // تهيئة visibility لطرق الدفع
        final paymentMethods = (stats['paymentMethods'] as List?) ?? [];
        for (var method in paymentMethods) {
          _visiblePaymentMethods[method['method']] = true;
        }
        
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Now unambiguous
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
            'الإحصائيات التفصيلية',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textGold,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 24),
                      
                      // الإحصائيات العامة
                      _buildGeneralStatsSection(),
                      const SizedBox(height: 24),
                      
                      // إحصائيات الشهر الحالي
                      _buildMonthlyStatsSection(),
                      const SizedBox(height: 24),
                      
                      // طرق الدفع
                      _buildPaymentMethodsSection(),
                      const SizedBox(height: 24),
                      
                      // نمو الطلبات
                      _buildDailyOrdersSection(),
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
              AppColors.primaryGold.withOpacity(0.15),
              AppColors.mediumGold.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '📊',
                  style: TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Text(
                  'الإحصائيات التفصيلية',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'تحليل شامل لجميع الطلبات والمبيعات والأرباح',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGold.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralStatsSection() {
    final totalOrders = _statistics['totalOrders'] ?? 0;
    final totalRevenue = ((_statistics['totalRevenue'] ?? 0) as num).toDouble();
    final totalCosts = ((_statistics['totalCosts'] ?? 0) as num).toDouble();
    final totalProfit = totalRevenue - totalCosts;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 100),
      child: Column(
        children: [
          _buildSectionTitle('📈', 'الإحصائيات العامة'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLargeStatCard(
                  'إجمالي الطلبات',
                  '$totalOrders',
                  const Color(0xFF4FACFE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLargeStatCard(
                  'إجمالي المبيعات',
                  '${_formatCurrency(totalRevenue)} د.ع',
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLargeStatCard(
                  'إجمالي التكاليف',
                  '${_formatCurrency(totalCosts)} د.ع',
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLargeStatCard(
                  'صافي الربح',
                  '${_formatCurrency(totalProfit)} د.ع',
                  Colors.green.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textGold.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStatsSection() {
    final monthlyData = (_statistics['monthlyData'] as List?) ?? [];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Column(
        children: [
          _buildSectionTitle('📆', 'إحصائيات الشهر الحالي'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.charcoal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 المبيعات والأرباح اليومية - ${_getCurrentMonthName()}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                monthlyData.isEmpty ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Text(
                    'لا توجد بيانات لعرضها',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGold.withOpacity(0.5),
                    ),
                  ),
                ) : Container(
                  height: 250,
                  alignment: Alignment.center,
                  child: Text(
                    '📊 بيانات متوفرة للشهر الحالي',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textGold,
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

  Widget _buildPaymentMethodsSection() {
    final paymentMethods = (_statistics['paymentMethods'] as List?) ?? [];
    
    if (paymentMethods.isEmpty) {
      return SizedBox.shrink();
    }

    // ترتيب طرق الدفع حسب المبلغ
    final sortedMethods = List<Map<String, dynamic>>.from(paymentMethods);
    sortedMethods.sort((a, b) => ((b['total'] ?? 0) as num).compareTo((a['total'] ?? 0) as num));

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 300),
      child: Column(
        children: [
          _buildSectionTitle('💳', 'توزيع طرق الدفع'),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Methods Cards
              Expanded(
                child: Column(
                  children: sortedMethods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final method = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < sortedMethods.length - 1 ? 12 : 0),
                      child: _buildPaymentMethodCard(method, index),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method, int rank) {
    final methodName = method['method'] ?? '';
    final count = method['count'] ?? 0;
    final total = ((method['total'] ?? 0) as num).toDouble();
    final percentage = ((method['percentage'] ?? 0) as num).toDouble();
    final color = _getPaymentMethodColor(methodName);
    
    // تأثيرات بصرية حسب الترتيب
    final scale = 1.05 - (rank * 0.03);
    final opacity = 1.0 - (rank * 0.05);
    final badge = rank == 0 ? '⭐' : rank == 1 ? '🏆' : rank == 2 ? '💎' : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.identity()..scale(scale),
      child: Opacity(
        opacity: opacity.clamp(0.7, 1.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                Color.lerp(color, Colors.black, 0.2)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(rank == 0 ? 0.4 : 0.2),
                blurRadius: rank == 0 ? 32 : 16,
                offset: Offset(0, rank == 0 ? 8 : 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Badge
              if (badge.isNotEmpty)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              // Rank
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#${rank + 1}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Content
              Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getPaymentMethodEmoji(methodName),
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getPaymentMethodDisplayName(methodName),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$count',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📦 طلب',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '💵',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatCurrency(total)} د.ع',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Progress Bar
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerRight,
                      widthFactor: (percentage / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyOrdersSection() {
    final dailyOrders = (_statistics['dailyOrders'] as List?) ?? [];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Column(
        children: [
          _buildSectionTitle('📊', 'نمو الطلبات اليومية'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.charcoal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📊 المبيعات والأرباح اليومية - ${_getCurrentMonthName()}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                dailyOrders.isEmpty ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Text(
                    'لا توجد بيانات لعرضها',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGold.withOpacity(0.5),
                    ),
                  ),
                ) : Container(
                  height: 250,
                  alignment: Alignment.center,
                  child: Text(
                    '📊 بيانات متوفرة: ${dailyOrders.length} يوم',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textGold,
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

  String _formatCurrency(num amount) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return formatter.format(amount);
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'زين كاش':
      case 'zaincash':
        return const Color(0xFF1E40AF);
      case 'آفدين':
      case 'rafidain':
        return const Color(0xFFFFC107);
      case 'اسياسيل':
      case 'asiacell':
        return const Color(0xFFDC3545);
      case 'نقدي':
      case 'cash':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFFF97316);
    }
  }

  String _getPaymentMethodEmoji(String method) {
    switch (method.toLowerCase()) {
      case 'زين كاش':
      case 'zaincash':
        return '💳';
      case 'آفدين':
      case 'rafidain':
        return '🏦';
      case 'اسياسيل':
      case 'asiacell':
        return '📱';
      case 'نقدي':
      case 'cash':
        return '💰';
      default:
        return '💰';
    }
  }

  String _getPaymentMethodDisplayName(String method) {
    switch (method.toLowerCase()) {
      case 'zaincash':
        return 'زين كاش';
      case 'rafidain':
        return 'رافدين';
      case 'asiacell':
        return 'اسياسيل';
      case 'cash':
        return 'نقدي';
      default:
        return method;
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
                      child: Icon(Icons.bar_chart, size: 40, color: AppColors.pureBlack),
                    ),
                    const SizedBox(height: 16),
                    Text('الإحصائيات', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold)),
                    Text('مدير النظام', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Divider(color: AppColors.glassWhite, thickness: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(Icons.home, 'الصفحة الرئيسية', () { Navigator.pop(context); Navigator.pushReplacementNamed(context, '/'); }),
                    Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                    _buildDrawerItem(Icons.subscriptions, 'إدارة الاشتراكات', () { Navigator.pop(context); Navigator.pushNamed(context, '/subscriptions'); }),
                    _buildDrawerItem(Icons.shopping_bag, 'إدارة الطلبات', () { Navigator.pop(context); Navigator.pushNamed(context, '/orders'); }),
                    _buildDrawerItem(Icons.archive, 'الأرشيف', () { Navigator.pop(context); Navigator.pushNamed(context, '/archive'); }),
                    Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('إدارة المدير', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                    _buildDrawerItem(Icons.bar_chart, 'الإحصائيات', () => Navigator.pop(context)),
                    _buildDrawerItem(Icons.account_balance_wallet, 'رأس المال', () { Navigator.pop(context); Navigator.pushNamed(context, '/capital'); }),
                    _buildDrawerItem(Icons.people, 'إدارة الموظفين', () { Navigator.pop(context); Navigator.pushNamed(context, '/employees'); }),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.glassWhite, thickness: 1),
                    _buildDrawerItem(Icons.logout, 'تسجيل الخروج', () async { if (context.mounted) Navigator.of(context).pushReplacementNamed('/login'); }),
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
