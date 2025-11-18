import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// صفحة اليوم في الأرشيف - تعرض الطلبات
class ArchiveDayScreen extends StatefulWidget {
  final String dayKey;
  final int day;
  final String dayName;
  final String monthName;
  final int year;
  final List<Map<String, dynamic>> orders;

  const ArchiveDayScreen({
    super.key,
    required this.dayKey,
    required this.day,
    required this.dayName,
    required this.monthName,
    required this.year,
    required this.orders,
  });

  @override
  State<ArchiveDayScreen> createState() => _ArchiveDayScreenState();
}

class _ArchiveDayScreenState extends State<ArchiveDayScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isSelectionMode = false;
  Set<int> _selectedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _filteredOrders = List.from(widget.orders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
        if (_selectedOrderIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedOrderIds = _filteredOrders.map((o) => o['id'] as int).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedOrderIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _unarchiveSelected() async {
    try {
      for (var orderId in _selectedOrderIds) {
        await ApiService.unarchiveOrder(orderId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إلغاء أرشفة ${_selectedOrderIds.length} طلب'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: Text('تأكيد الحذف', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold)),
        content: Text(
          'هل تريد حذف ${_selectedOrderIds.length} طلب نهائياً؟',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (var orderId in _selectedOrderIds) {
          await ApiService.deleteOrder(orderId);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف ${_selectedOrderIds.length} طلب'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _exportToExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم تصدير ${_selectedOrderIds.length} طلب إلى Excel'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredOrders = List.from(widget.orders);
      });
      return;
    }

    final query = _searchQuery.toLowerCase().trim();
    List<Map<String, dynamic>> results = [];

    for (var order in widget.orders) {
      bool matches = false;

      // البحث الذكي
      final customerName = (order['customer_name'] ?? '').toString().toLowerCase();
      final cleanCustomerName = customerName.replaceAll(RegExp(r'[\s,،-]'), '');
      final cleanQuery = query.replaceAll(RegExp(r'[\s,،-]'), '');
      if (cleanCustomerName.contains(cleanQuery) || customerName.contains(query)) {
        matches = true;
      }

      if ((order['product_name'] ?? '').toString().toLowerCase().contains(query)) matches = true;
      if ((order['customer_phone'] ?? '').toString().contains(query)) matches = true;
      if ((order['payment_method'] ?? '').toString().toLowerCase().contains(query)) matches = true;
      if ((order['price'] ?? 0).toString().contains(query)) matches = true;
      if ((order['notes'] ?? '').toString().toLowerCase().contains(query)) matches = true;

      if (matches) {
        results.add(order);
      }
    }

    setState(() {
      _filteredOrders = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isSelectionMode ? '${_selectedOrderIds.length} محدد' : '${widget.dayName} ${widget.day} ${widget.monthName} ${widget.year}',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textGold,
          ),
        ),
        centerTitle: true,
        actions: _isSelectionMode ? [
          IconButton(
            icon: Icon(Icons.select_all, color: AppColors.primaryGold),
            onPressed: _selectAll,
            tooltip: 'تحديد الكل',
          ),
          IconButton(
            icon: Icon(Icons.unarchive, color: AppColors.primaryGold),
            onPressed: _unarchiveSelected,
            tooltip: 'إلغاء الأرشفة',
          ),
          IconButton(
            icon: Icon(Icons.file_download, color: AppColors.primaryGold),
            onPressed: _exportToExcel,
            tooltip: 'تصدير Excel',
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteSelected,
            tooltip: 'حذف',
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.primaryGold),
            onPressed: _clearSelection,
            tooltip: 'إلغاء',
          ),
        ] : null,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildStatistics(),
              const SizedBox(height: 16),
              Expanded(
                child: _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FadeInDown(
        duration: const Duration(milliseconds: 600),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppColors.glassWhite, AppColors.glassBlack],
            ),
            border: Border.all(
                color: AppColors.primaryGold.withOpacity(0.3), width: 1),
          ),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'ابحث في طلبات اليوم...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: AppColors.primaryGold),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _performSearch();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    double totalRevenue = 0;
    double totalProfit = 0;

    for (var order in _filteredOrders) {
      totalRevenue += ((order['price'] ?? 0) as num).toDouble();
      totalProfit += ((order['profit'] ?? 0) as num).toDouble();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: FadeInDown(
        duration: const Duration(milliseconds: 600),
        delay: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppColors.primaryGold.withOpacity(0.2),
                AppColors.mediumGold.withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: AppColors.primaryGold.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_filteredOrders.length}',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'طلب',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.primaryGold.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      NumberFormat('#,##0').format(totalRevenue),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المبيعات',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.primaryGold.withOpacity(0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      NumberFormat('#,##0').format(totalProfit),
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.green.shade300,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الربح',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
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

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 50 + (index * 30)),
          child: _buildOrderCard(order, index),
        );
      },
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تفاصيل الطلب',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('اسم الزبون', order['customer_name'] ?? '', Icons.person),
              _buildDetailRow('رقم الهاتف', order['customer_phone'] ?? '', Icons.phone),
              _buildDetailRow('المنتج', order['product_name'] ?? '', Icons.shopping_bag),
              _buildDetailRow('السعر', '${NumberFormat('#,##0').format(order['price'])} د.ع', Icons.attach_money),
              _buildDetailRow('التكلفة', '${NumberFormat('#,##0').format(order['cost'])} د.ع', Icons.money_off),
              _buildDetailRow('الربح', '${NumberFormat('#,##0').format(order['profit'])} د.ع', Icons.trending_up),
              _buildDetailRow('وسيلة الدفع', order['payment_method'] ?? '', Icons.payment),
              if (order['notes'] != null && order['notes'].toString().isNotEmpty)
                _buildDetailRow('ملاحظات', order['notes'], Icons.notes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: TextStyle(color: AppColors.primaryGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGold),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    final date = DateTime.parse(order['created_at']);
    final formattedTime = DateFormat('hh:mm a').format(date);
    final isSelected = _selectedOrderIds.contains(order['id']);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(order['id']);
        } else {
          _showOrderDetails(order);
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _toggleSelection(order['id']);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(isSelected ? 0.95 : 1.0),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryGold.withOpacity(0.3),
                    AppColors.mediumGold.withOpacity(0.2),
                  ],
                )
              : LinearGradient(
                  colors: [AppColors.glassWhite, AppColors.glassBlack],
                ),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.primaryGold.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryGold.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isSelected
                      ? Icon(Icons.check_circle, color: AppColors.primaryGold, size: 20)
                      : Text(
                          '#${index + 1}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['customer_name'] ?? '',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (order['customer_phone'] != null && order['customer_phone'].toString().isNotEmpty)
                        Text(
                          order['customer_phone'],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat('#,##0').format(order['price'])} د.ع',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.charcoal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.shopping_bag, size: 18, color: AppColors.primaryGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order['product_name'] ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPaymentMethodColor(order['payment_method']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _getPaymentMethodEmoji(order['payment_method']),
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order['payment_method'] ?? '',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _getPaymentMethodColor(order['payment_method']),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'ربح: ${NumberFormat('#,##0').format(order['profit'])} د.ع',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.green.shade300,
                ),
              ),
            ],
          ),
          if (order['notes'] != null && order['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.charcoal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order['notes'],
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(String? method) {
    switch (method?.toLowerCase()) {
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
        return AppColors.primaryGold;
    }
  }

  String _getPaymentMethodEmoji(String? method) {
    switch (method?.toLowerCase()) {
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
        return '💵';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب البحث بكلمات مختلفة'
                : 'لا توجد طلبات في هذا اليوم',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
