import 'package:flutter/material.dart' hide TextDirection;
import 'package:flutter/rendering.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui hide TextDirection;
import 'dart:typed_data';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// صفحة إدارة الطلبات
class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({super.key});

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> with TickerProviderStateMixin {
  String _sortBy = 'الأحدث';
  String _viewMode = 'list'; // 'grid' or 'list' - الافتراضي قائمة
  String _cardSize = 'صغير جداً';
  bool _isLoading = true;
  String? _role;
  String _dateFilter = 'الكل'; // الكل, اليوم, هذا الأسبوع, هذا الشهر, تاريخ مخصص
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // نظام التحديد المتعدد
  bool _selectionMode = false;
  Set<int> _selectedOrderIds = {};
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionAnimation;
  
  // البيانات الحقيقية من السيرفر
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _selectionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _selectionAnimation = CurvedAnimation(
      parent: _selectionAnimationController,
      curve: Curves.easeInOut,
    );
    _loadRole();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectionAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role');
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getOrders();
      print('📦 API Response: $result');
      
      if (result['success'] == true && mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(
            result['orders'].map((order) {
              // استخراج اسم المنتج الأصلي (قبل " - ")
              String fullProductName = order['product_name'] ?? '';
              String productName = fullProductName.split(' - ').first;
              
              // استخراج مدة الاشتراك من notes
              String notes = order['notes'] ?? '';
              int durationMonths = 1; // الافتراضي شهر واحد
              
              print('🔍 Order ${order['id']} - Notes: $notes');
              
              if (notes.contains('مدة:')) {
                String durationPart = notes.split('مدة:').last.trim();
                print('🔍 Duration Part: "$durationPart"');
                
                // البحث بترتيب من الأطول للأقصر لتجنب التطابق الخاطئ
                if (durationPart.contains('شهرين')) {
                  durationMonths = 2;
                } else if (durationPart.contains('ثلاثة أشهر') || durationPart.contains('ثلاث أشهر')) {
                  durationMonths = 3;
                } else if (durationPart.contains('أربعة أشهر') || durationPart.contains('اربعة أشهر') || durationPart.contains('أربع أشهر')) {
                  durationMonths = 4;
                } else if (durationPart.contains('خمسة أشهر') || durationPart.contains('خمس أشهر')) {
                  durationMonths = 5;
                } else if (durationPart.contains('ستة أشهر') || durationPart.contains('ست أشهر') || durationPart.contains('6')) {
                  durationMonths = 6;
                } else if (durationPart.contains('سبعة أشهر') || durationPart.contains('سبع أشهر') || durationPart.contains('7')) {
                  durationMonths = 7;
                } else if (durationPart.contains('ثمانية أشهر') || durationPart.contains('ثمان أشهر') || durationPart.contains('8')) {
                  durationMonths = 8;
                } else if (durationPart.contains('تسعة أشهر') || durationPart.contains('تسع أشهر') || durationPart.contains('9')) {
                  durationMonths = 9;
                } else if (durationPart.contains('عشرة أشهر') || durationPart.contains('عشر أشهر') || durationPart.contains('10')) {
                  durationMonths = 10;
                } else if (durationPart.contains('أحد عشر') || durationPart.contains('11')) {
                  durationMonths = 11;
                } else if (durationPart.contains('سنة') || durationPart.contains('12')) {
                  durationMonths = 12;
                } else if (durationPart.contains('شهر واحد') || durationPart.contains('شهر')) {
                  durationMonths = 1;
                }
                
                print('✅ Extracted Duration: $durationMonths months');
              }
              
              return {
                'id': order['id'],
                'productName': productName,
                'fullProductName': fullProductName,
                'customerName': order['customer_name'],
                'price': order['price'],
                'profit': order['profit'],
                'paymentMethod': order['payment_method'],
                'date': DateTime.parse(order['created_at']),
                'category': order['category'],
                'employee_username': order['employee_username'],
                'notes': notes,
                'durationMonths': durationMonths,
              };
            })
          );
          print('📦 Orders loaded: ${_orders.length} items');
          _applyFilters();
        });
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(int orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
        if (_selectedOrderIds.isEmpty) {
          _selectionMode = false;
          _selectionAnimationController.reverse();
        }
      } else {
        _selectedOrderIds.add(orderId);
        if (!_selectionMode) {
          _selectionMode = true;
          _selectionAnimationController.forward();
        }
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedOrderIds = Set<int>.from(_filteredOrders.map((o) => o['id'] as int));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedOrderIds.clear();
      _selectionMode = false;
      _selectionAnimationController.reverse();
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedOrderIds.length;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'حذف الطلبات',
              style: AppTextStyles.headlineSmall.copyWith(color: Colors.red),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف $count طلب؟\n⚠️ لا يمكن التراجع عن هذا الإجراء',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('حذف الكل', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('جارِ حذف $count طلب...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ),
      );

      try {
        for (final orderId in _selectedOrderIds) {
          await ApiService.deleteOrder(orderId);
        }
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم حذف $count طلب بنجاح', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _clearSelection();
          _loadOrders();
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ حدث خطأ: $e', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _archiveSelected() async {
    final count = _selectedOrderIds.length;
    
    // تأكيد الأرشفة
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.glassBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'أرشفة الطلبات',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primaryGold),
          ),
          content: Text(
            'هل تريد أرشفة $count طلب؟\nسيتم نقلها إلى الأرشيف ويمكن استرجاعها لاحقاً.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('أرشفة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      // أرشفة كل الطلبات المحددة
      for (var orderId in _selectedOrderIds) {
        final result = await ApiService.archiveOrder(orderId);
        if (result['success'] != true) {
          throw Exception(result['message']);
        }
      }

      if (mounted) {
        // إزالة الطلبات المؤرشفة من القائمة
        setState(() {
          _orders.removeWhere((order) => _selectedOrderIds.contains(order['id']));
          _applyFilters();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم أرشفة $count طلب بنجاح', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _clearSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ: $e', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        // Date filter
        final orderDate = order['date'] as DateTime;
        final now = DateTime.now();
        
        if (_dateFilter == 'اليوم') {
          if (orderDate.day != now.day ||
              orderDate.month != now.month ||
              orderDate.year != now.year) {
            return false;
          }
        } else if (_dateFilter == 'هذا الأسبوع') {
          final weekAgo = now.subtract(const Duration(days: 7));
          if (orderDate.isBefore(weekAgo)) {
            return false;
          }
        } else if (_dateFilter == 'هذا الشهر') {
          if (orderDate.month != now.month || orderDate.year != now.year) {
            return false;
          }
        } else if (_dateFilter == 'تاريخ مخصص') {
          if (_customStartDate != null && _customEndDate != null) {
            final startDate = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
            final endDate = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
            if (orderDate.isBefore(startDate) || orderDate.isAfter(endDate)) {
              return false;
            }
          }
        }
        
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final productName = (order['productName'] ?? '').toString().toLowerCase();
          final customerName = (order['customerName'] ?? '').toString().toLowerCase();
          final price = (order['price'] ?? '').toString();
          final paymentMethod = (order['paymentMethod'] ?? '').toString().toLowerCase();
          
          if (!productName.contains(query) &&
              !customerName.contains(query) &&
              !price.contains(query) &&
              !paymentMethod.contains(query)) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      // Sort
      if (_sortBy == 'الأحدث') {
        _filteredOrders.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      } else if (_sortBy == 'الأقدم') {
        _filteredOrders.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      } else if (_sortBy == 'السعر (الأعلى)') {
        _filteredOrders.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
      } else if (_sortBy == 'السعر (الأقل)') {
        _filteredOrders.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
      }
    });
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
            'إدارة الطلبات',
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
            child: Column(
              children: [
                // Selection Mode Bar
                if (_selectionMode)
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(_selectionAnimation),
                    child: _buildSelectionBar(),
                  ),
                
                // Search Bar
                _buildSearchBar(),
                
                const SizedBox(height: 12),
                
                // Controls Bar (Filter + Sort + View Mode)
                _buildControlsBar(),
                
                const SizedBox(height: 12),
                
                // Orders List
                Expanded(
                  child: _buildOrdersList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryGold.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث عن عميل، منتج، سعر، أو طريقة الدفع...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.primaryGold,
                size: 22,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGold.withOpacity(0.95),
              AppColors.mediumGold.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // عدد المحدد
            ScaleTransition(
              scale: _selectionAnimation,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.pureBlack.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_selectedOrderIds.length}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.pureBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '\u0645\u062d\u062f\u062f',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.pureBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // تحديد الكل
            FadeInRight(
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 50),
              child: _buildActionButton(
                icon: Icons.select_all,
                label: '\u0627\u0644\u0643\u0644',
                onTap: _selectAll,
              ),
            ),
            const SizedBox(width: 8),
            
            // أرشفة
            FadeInRight(
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 100),
              child: _buildActionButton(
                icon: Icons.archive,
                label: '\u0623\u0631\u0634\u0641\u0629',
                onTap: _archiveSelected,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            
            // حذف
            if (_role == 'admin')
              FadeInRight(
                duration: const Duration(milliseconds: 300),
                delay: const Duration(milliseconds: 150),
                child: _buildActionButton(
                  icon: Icons.delete,
                  label: '\u062d\u0630\u0641',
                  onTap: _deleteSelected,
                  color: Colors.red,
                ),
              ),
            const SizedBox(width: 8),
            
            // إلغاء
            FadeInRight(
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 200),
              child: _buildActionButton(
                icon: Icons.close,
                label: '\u0625\u0644\u063a\u0627\u0621',
                onTap: _clearSelection,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.pureBlack).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (color ?? AppColors.pureBlack).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? AppColors.pureBlack,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color ?? AppColors.pureBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar() {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Date Filter Button
            Expanded(
              child: GestureDetector(
                onTap: _showDateFilterOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.glassBlack,
                    border: Border.all(color: AppColors.primaryGold, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primaryGold, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _dateFilter,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 6),
            
            // Sort Button
            Expanded(
              child: GestureDetector(
                onTap: _showSortOptions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.glassBlack,
                    border: Border.all(color: AppColors.primaryGold, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sort, color: AppColors.primaryGold, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _sortBy,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 6),
            
            // View Mode Toggle Button
            GestureDetector(
              onTap: () {
                setState(() {
                  _viewMode = _viewMode == 'grid' ? 'list' : 'grid';
                });
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.glassBlack,
                  border: Border.all(color: AppColors.primaryGold, width: 1),
                ),
                child: Icon(
                  _viewMode == 'grid' ? Icons.view_list : Icons.grid_view,
                  color: AppColors.primaryGold,
                  size: 18,
                ),
              ),
            ),
            
            const SizedBox(width: 6),
            
            // Card Size Button (only in grid mode)
            if (_viewMode == 'grid')
              GestureDetector(
                onTap: _showCardSizeOptions,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.glassBlack,
                    border: Border.all(color: AppColors.primaryGold, width: 1),
                  ),
                  child: Icon(
                    Icons.photo_size_select_small,
                    color: AppColors.primaryGold,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDateFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.charcoal, AppColors.charcoal.withOpacity(0.95)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primaryGold, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'فلترة حسب التاريخ',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...['الكل', 'اليوم', 'هذا الأسبوع', 'هذا الشهر', 'تاريخ مخصص'].map((filter) {
                return _buildFilterOption(
                  filter,
                  _dateFilter == filter,
                  () async {
                    if (filter == 'تاريخ مخصص') {
                      Navigator.pop(context);
                      await _showCustomDatePicker();
                    } else {
                      setState(() {
                        _dateFilter = filter;
                        _customStartDate = null;
                        _customEndDate = null;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    }
                  },
                );
              }),
              if (_dateFilter == 'تاريخ مخصص' && _customStartDate != null && _customEndDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'الفترة المحددة:',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_customStartDate!.year}/${_customStartDate!.month}/${_customStartDate!.day} - ${_customEndDate!.year}/${_customEndDate!.month}/${_customEndDate!.day}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final startDate = await showDatePicker(
      context: context,
      initialDate: _customStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryGold,
              onPrimary: AppColors.pureBlack,
              surface: AppColors.charcoal,
              onSurface: AppColors.textGold,
            ), dialogTheme: DialogThemeData(backgroundColor: AppColors.charcoal),
          ),
          child: child!,
        );
      },
    );

    if (startDate != null && mounted) {
      final endDate = await showDatePicker(
        context: context,
        initialDate: _customEndDate ?? startDate,
        firstDate: startDate,
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.primaryGold,
                onPrimary: AppColors.pureBlack,
                surface: AppColors.charcoal,
                onSurface: AppColors.textGold,
              ), dialogTheme: DialogThemeData(backgroundColor: AppColors.charcoal),
            ),
            child: child!,
          );
        },
      );

      if (endDate != null && mounted) {
        setState(() {
          _customStartDate = startDate;
          _customEndDate = endDate;
          _dateFilter = 'تاريخ مخصص';
          _applyFilters();
        });
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.charcoal, AppColors.charcoal.withOpacity(0.95)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primaryGold, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ترتيب حسب',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textGold,
              ),
            ),
            const SizedBox(height: 20),
            _buildSortOption('الأحدث', Icons.new_releases),
            _buildSortOption('الأقدم', Icons.history),
            _buildSortOption('السعر (الأعلى)', Icons.arrow_upward),
            _buildSortOption('السعر (الأقل)', Icons.arrow_downward),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? AppColors.goldGradient : null,
          color: isSelected ? null : AppColors.glassBlack,
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.glassWhite,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.pureBlack, size: 20),
            if (isSelected) const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.pureBlack : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, IconData icon) {
    final isSelected = _sortBy == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = title;
          _applyFilters();
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? AppColors.goldGradient : null,
          color: isSelected ? null : AppColors.glassBlack,
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.glassWhite,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.pureBlack : AppColors.primaryGold,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.pureBlack : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.pureBlack,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showCardSizeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.charcoal, AppColors.charcoal.withOpacity(0.95)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primaryGold, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حجم البطاقات',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textGold,
              ),
            ),
            const SizedBox(height: 20),
            _buildCardSizeOption('صغير جداً', Icons.view_agenda),
            _buildCardSizeOption('صغير', Icons.view_module),
            _buildCardSizeOption('متوسط', Icons.view_comfy),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSizeOption(String title, IconData icon) {
    final isSelected = _cardSize == title;
    return GestureDetector(
      onTap: () {
        setState(() => _cardSize = title);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected ? AppColors.goldGradient : null,
          color: isSelected ? null : AppColors.glassBlack,
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : AppColors.glassWhite,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.pureBlack : AppColors.primaryGold,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.pureBlack : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.pureBlack,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGold,
        ),
      );
    }

    if (_filteredOrders.isEmpty) {
      return FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 60,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty || _dateFilter != 'الكل'
                    ? 'لا توجد نتائج للبحث'
                    : 'لا توجد طلبات',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'جرب تغيير معايير البحث أو الفلتر',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewMode == 'list') {
      // List view mode - horizontal rectangles
      return FadeInUp(
        duration: const Duration(milliseconds: 600),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _filteredOrders.length,
          itemBuilder: (context, index) {
            return _buildOrderListTile(_filteredOrders[index], index);
          },
        ),
      );
    }

    // Grid view mode - cards
    int crossAxisCount;
    double childAspectRatio;
    
    switch (_cardSize) {
      case 'صغير جداً':
        crossAxisCount = 5;
        childAspectRatio = 0.75;
        break;
      case 'صغير':
        crossAxisCount = 4;
        childAspectRatio = 0.85;
        break;
      case 'متوسط':
      default:
        crossAxisCount = 3;
        childAspectRatio = 1.0;
        break;
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_filteredOrders[index]);
        },
      ),
    );
  }

  Widget _buildOrderListTile(Map<String, dynamic> order, int index) {
    final categoryColor = order['category'] == 'ألعاب' 
        ? AppColors.info 
        : AppColors.primaryGold;
    final orderId = order['id'] as int;
    final isSelected = _selectedOrderIds.contains(orderId);

    return FadeInRight(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 50),
      child: GestureDetector(
        onTap: () {
          if (_selectionMode) {
            _toggleSelection(orderId);
          } else {
            _showOrderDetails(order);
          }
        },
        onLongPress: () => _toggleSelection(orderId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          transform: Matrix4.identity()..scale(isSelected ? 0.98 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected 
                  ? [AppColors.primaryGold.withOpacity(0.3), AppColors.mediumGold.withOpacity(0.2)]
                  : [AppColors.glassWhite, AppColors.glassBlack],
            ),
            border: Border.all(
              color: isSelected ? AppColors.primaryGold : categoryColor, 
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Row(
            children: [
              // Checkbox للتحديد
              if (_selectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGold : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGold : categoryColor,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: AppColors.pureBlack,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                ),
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  order['category'] == 'ألعاب'
                      ? Icons.sports_esports
                      : Icons.subscriptions,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['productName'],
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textGold,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline, 
                          color: AppColors.textSecondary, 
                          size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order['customerName'],
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.payment, 
                          color: AppColors.textSecondary, 
                          size: 16),
                        const SizedBox(width: 4),
                        Text(
                          order['paymentMethod'],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Price and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${order['price']} د.ع',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.pureBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Receipt Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showReceiptDialog(order),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.receipt,
                          color: Colors.blue,
                          size: 20,
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isExtraSmall = _cardSize == 'صغير جداً';
    final isSmall = _cardSize == 'صغير';
    
    final categoryColor = order['category'] == 'ألعاب' 
        ? AppColors.info 
        : AppColors.primaryGold;
    final orderId = order['id'] as int;
    final isSelected = _selectedOrderIds.contains(orderId);

    return GestureDetector(
      onTap: () {
        if (_selectionMode) {
          _toggleSelection(orderId);
        } else {
          _showOrderDetails(order);
        }
      },
      onLongPress: () => _toggleSelection(orderId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(isSelected ? 0.95 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isExtraSmall ? 10 : 12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [AppColors.primaryGold.withOpacity(0.3), AppColors.mediumGold.withOpacity(0.2)]
                : [AppColors.glassWhite, AppColors.glassBlack],
          ),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : categoryColor, 
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            // Checkbox للتحديد
            if (_selectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryGold : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryGold : categoryColor,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: AppColors.pureBlack,
                            size: 14,
                          )
                        : null,
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(isExtraSmall ? 10 : 12),
              child: Padding(
                padding: EdgeInsets.all(isExtraSmall ? 10 : (isSmall ? 12 : 14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isExtraSmall ? 6 : 8),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        order['category'] == 'ألعاب'
                            ? Icons.sports_esports
                            : Icons.subscriptions,
                        color: categoryColor,
                        size: isExtraSmall ? 18 : (isSmall ? 20 : 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order['productName'],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGold,
                          fontWeight: FontWeight.bold,
                          fontSize: isExtraSmall ? 13 : (isSmall ? 14 : 15),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isExtraSmall ? 6 : 8),
                
                // Customer
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: AppColors.textSecondary,
                      size: isExtraSmall ? 16 : 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order['customerName'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isExtraSmall ? 12 : (isSmall ? 13 : 14),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Price and Receipt Button
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: AppColors.primaryGold,
                      size: isExtraSmall ? 16 : 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${order['price']} د.ع',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: isExtraSmall ? 13 : (isSmall ? 14 : 15),
                      ),
                    ),
                    const Spacer(),
                    // Receipt Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showReceiptDialog(order),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: EdgeInsets.all(isExtraSmall ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.receipt,
                            color: Colors.blue,
                            size: isExtraSmall ? 16 : 18,
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
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final categoryColor = order['category'] == 'ألعاب' 
        ? AppColors.info 
        : AppColors.primaryGold;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 900),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.charcoal, AppColors.charcoal.withOpacity(0.95)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: categoryColor, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        order['category'] == 'ألعاب'
                            ? Icons.sports_esports
                            : Icons.subscriptions,
                        color: categoryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل الطلب #${order['id']}',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.textGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order['productName'],
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content - عريض باستخدام Grid
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // الصف الأول: المنتج والعميل
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailCard(
                              'المنتج',
                              order['productName'],
                              Icons.shopping_bag,
                              AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailCard(
                              'العميل',
                              order['customerName'],
                              Icons.person,
                              AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // الصف الثاني: السعر والربح
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailCard(
                              'السعر',
                              '${order['price']} د.ع',
                              Icons.attach_money,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailCard(
                              'الربح',
                              '${order['profit']} د.ع',
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // الصف الثالث: طريقة الدفع والتاريخ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailCard(
                              'طريقة الدفع',
                              order['paymentMethod'],
                              Icons.payment,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDetailCard(
                              'التاريخ',
                              _formatDate(order['date']),
                              Icons.calendar_today,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      
                      // عرض اسم الموظف للمدراء فقط
                      if (_role == 'admin' && order['employee_username'] != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailCard(
                          'سجله الموظف',
                          order['employee_username'],
                          Icons.badge,
                          AppColors.info,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.pureBlack.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // الأزرار على اليسار
                    Row(
                      children: [
                        // زر التعديل
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditOrderDialog(order);
                          },
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          label: Text(
                            'تعديل',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // زر الحذف
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDeleteOrder(order);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: Text(
                            'حذف',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.red.withOpacity(0.3)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // الأزرار على اليمين
                    Row(
                      children: [
                        // زر طباعة الإيصال
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showReceiptDialog(order);
                          },
                          icon: const Icon(Icons.receipt_long, color: Colors.blue),
                          label: Text(
                            'إيصال',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // زر الإغلاق
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: AppColors.primaryGold),
                          label: Text(
                            'إغلاق',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.primaryGold.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
                            ),
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
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(Map<String, dynamic> order) {
    final GlobalKey receiptKey = GlobalKey();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // محتوى الإيصال
              Flexible(
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: receiptKey,
                    child: Container(
                      width: 400,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      // شعار وعنوان
                      Text(
                        '🌟 TAIF STORE 🌟',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '✨ إيصال شراء ✨',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // خط فاصل
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // معلومات العميل
                      _buildReceiptRow('👤 العميل', order['customerName']),
                      const SizedBox(height: 16),
                      
                      // اسم المنتج
                      _buildReceiptRow('📦 المنتج', order['productName']),
                      const SizedBox(height: 16),
                      
                      // إذا كان اشتراك - عرض فترة الاشتراك
                      if (order['category'] == 'اشتراكات') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'فترة الاشتراك',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '📅 من',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(order['date'] as DateTime).day}/${(order['date'] as DateTime).month}/${(order['date'] as DateTime).year}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward, color: Colors.blue, size: 24),
                                  Column(
                                    children: [
                                      Text(
                                        '📅 إلى',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (context) {
                                          final durationDays = 30 * ((order['durationMonths'] as num?)?.toInt() ?? 1);
                                          final endDate = (order['date'] as DateTime).add(Duration(days: durationDays));
                                          return Text(
                                            '${endDate.day}/${endDate.month}/${endDate.year}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[900],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // طريقة الدفع
                      _buildReceiptRow('💳 طريقة الدفع', order['paymentMethod']),
                      const SizedBox(height: 24),
                      
                      // خط فاصل
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // الإجمالي المدفوع
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFD4AF37), width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '💰 الإجمالي',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                            Text(
                              '${NumberFormat('#,##0', 'en_US').format(order['price'] ?? 0)} د.ع',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // رسالة شكر
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '🙏 شكراً لتعاملكم معنا 🙏',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '⭐ نتمنى لك تجربة ممتعة ⭐',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // التاريخ
                      Text(
                        '📅 تاريخ الطلب: ${(order['date'] as DateTime).day}/${(order['date'] as DateTime).month}/${(order['date'] as DateTime).year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                ),
              ),
              
              // زر التنزيل
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _downloadReceipt(receiptKey),
                            icon: Icon(Icons.download, size: 20),
                            label: Text('تنزيل'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD4AF37),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _copyReceiptToClipboard(receiptKey),
                            icon: Icon(Icons.copy, size: 20),
                            label: Text('نسخ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      label: Text('إغلاق'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        padding: EdgeInsets.symmetric(vertical: 12),
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
  
  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[900],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  Future<void> _downloadReceipt(GlobalKey key) async {
    try {
      // عرض رسالة تحميل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏳ جاري إنشاء الإيصال...'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
      
      // الحصول على RenderRepaintBoundary
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // تحويل إلى صورة بجودة عالية (3x للوضوح)
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('فشل تحويل الصورة');
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // الحصول على مجلد Downloads
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('لم يتم العثور على مجلد التنزيلات');
      }
      
      // إنشاء اسم الملف
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}\\$fileName';
      
      // حفظ الملف
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      
      await Future.delayed(Duration(milliseconds: 300));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم حفظ الإيصال في:\n${directory.path}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ أثناء الحفظ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _copyReceiptToClipboard(GlobalKey key) async {
    try {
      // عرض رسالة تحميل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏳ جاري نسخ الإيصال...'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
      
      // الحصول على RenderRepaintBoundary
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // تحويل إلى صورة بجودة عالية (3x للوضوح)
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('فشل تحويل الصورة');
      }
      Uint8List pngBytes = byteData.buffer.asUint8List();
      
      // حفظ مؤقتاً
      final directory = await getTemporaryDirectory();
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}\\$fileName';
      
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      
      // نسخ الصورة للحافظة باستخدام PowerShell
      final result = await Process.run(
        'powershell',
        [
          '-command',
          'Add-Type -AssemblyName System.Windows.Forms; '
          '[System.Windows.Forms.Clipboard]::SetImage([System.Drawing.Image]::FromFile("$filePath"))'
        ],
      );
      
      if (result.exitCode != 0) {
        throw Exception('فشل النسخ: ${result.stderr}');
      }
      
      await Future.delayed(Duration(milliseconds: 300));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم نسخ الإيصال للحافظة\nيمكنك لصقه في أي مكان (Ctrl+V)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ حدث خطأ أثناء النسخ: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showEditOrderDialog(Map<String, dynamic> order) {
    final productNameController = TextEditingController(text: order['productName']);
    final customerNameController = TextEditingController(text: order['customerName']);
    final priceController = TextEditingController(text: order['price'].toString());
    
    String selectedPaymentMethod = order['paymentMethod'] ?? 'نقدي';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.charcoal, AppColors.charcoal.withOpacity(0.95)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'تعديل الطلب #${order['id']}',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildEditTextField('اسم المنتج', productNameController, Icons.shopping_bag),
                          const SizedBox(height: 16),
                          _buildEditTextField('اسم العميل', customerNameController, Icons.person),
                          const SizedBox(height: 16),
                          // عرض التكلفة (للقراءة فقط)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.glassBlack,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.money_off, color: AppColors.textSecondary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'التكلفة: ',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${order['cost']} د.ع',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'غير قابل للتعديل',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.orange,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildEditTextField('السعر', priceController, Icons.attach_money, isNumber: true),
                          const SizedBox(height: 16),
                          // طريقة الدفع
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.glassBlack,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.payment, color: AppColors.primaryGold, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'طريقة الدفع',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ['نقدي', 'زين كاش', 'آسيا حوالة', 'فاستباي'].map((method) {
                                    final isSelected = selectedPaymentMethod == method;
                                    return ChoiceChip(
                                      label: Text(method),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          selectedPaymentMethod = method;
                                        });
                                      },
                                      selectedColor: AppColors.primaryGold.withOpacity(0.3),
                                      labelStyle: AppTextStyles.bodySmall.copyWith(
                                        color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.pureBlack.withOpacity(0.3),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'إلغاء',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // التحقق من الحقول
                            if (productNameController.text.isEmpty ||
                                customerNameController.text.isEmpty ||
                                priceController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('يرجى ملء جميع الحقول المطلوبة'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            // الحفاظ على التكلفة الأصلية (مع التحقق من null)
                            final cost = (order['cost'] ?? 0) as num;
                            final price = double.tryParse(priceController.text) ?? 0;
                            
                            Navigator.pop(context);
                            
                            // عرض مؤشر التحميل
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.charcoal,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(
                                        'جارِ تعديل الطلب...',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            
                            try {
                              final response = await ApiService.updateOrder(
                                orderId: order['id'],
                                productName: productNameController.text,
                                customerName: customerNameController.text,
                                customerPhone: order['customerPhone'] ?? '',
                                cost: cost.toDouble(),
                                price: price,
                                paymentMethod: selectedPaymentMethod,
                                status: order['status'] ?? 'pending',
                                notes: order['notes'] ?? '',
                              );
                              
                              if (mounted) {
                                Navigator.pop(context); // إغلاق مؤشر التحميل
                                
                                if (response['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ تم تعديل الطلب بنجاح'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  _loadOrders();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('❌ ${response['message']}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ خطأ: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: Text('حفظ التعديلات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildEditTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryGold),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOrder(Map<String, dynamic> order) {
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'تأكيد الحذف',
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من حذف هذا الطلب؟',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الطلب #${order['id']}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['productName'],
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'العميل: ${order['customerName']}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ لا يمكن التراجع عن هذا الإجراء',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
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
            onPressed: () => _deleteOrder(order['id']),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
  }

  Future<void> _deleteOrder(int orderId) async {
    Navigator.pop(context); // إغلاق نافذة التأكيد
    
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'جارِ حذف الطلب...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await ApiService.deleteOrder(orderId);
      
      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        
        if (response['success'] == true) {
          // عرض رسالة نجاح
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ تم حذف الطلب بنجاح',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          
          // إعادة تحميل الطلبات
          _loadOrders();
        } else {
          // عرض رسالة خطأ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '❌ ${response['message'] ?? 'فشل حذف الطلب'}',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // إغلاق مؤشر التحميل
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ حدث خطأ أثناء حذف الطلب: $e',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
                      child: Icon(Icons.shopping_bag, size: 40, color: AppColors.pureBlack),
                    ),
                    const SizedBox(height: 16),
                    Text('إدارة الطلبات', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold)),
                    Text(_role == 'admin' ? 'مدير النظام' : 'موظف', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
                    _buildDrawerItem(Icons.shopping_bag, 'إدارة الطلبات', () => Navigator.pop(context)),
                    _buildDrawerItem(Icons.archive, 'الأرشيف', () { Navigator.pop(context); Navigator.pushNamed(context, '/archive'); }),
                    if (_role == 'admin') ...[
                      Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('إدارة المدير', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                      _buildDrawerItem(Icons.bar_chart, 'الإحصائيات', () { Navigator.pop(context); Navigator.pushNamed(context, '/statistics'); }),
                      _buildDrawerItem(Icons.account_balance_wallet, 'رأس المال', () { Navigator.pop(context); Navigator.pushNamed(context, '/capital'); }),
                      _buildDrawerItem(Icons.people, 'إدارة الموظفين', () { Navigator.pop(context); Navigator.pushNamed(context, '/employees'); }),
                    ],
                    const SizedBox(height: 16),
                    Divider(color: AppColors.glassWhite, thickness: 1),
                    _buildDrawerItem(Icons.logout, 'تسجيل الخروج', () async { await ApiService.logout(); if (context.mounted) Navigator.of(context).pushReplacementNamed('/login'); }),
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
