import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';
import '../widgets/app_drawer.dart';
import 'package:intl/intl.dart';
import 'archive_month_screen.dart';

/// صفحة الأرشيف - نظام متطور للأرشفة
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMonths = [];
  List<Map<String, dynamic>> _filteredMonths = [];
  bool _isSelectionMode = false;
  Set<String> _selectedMonths = {};
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _loadArchiveMonths();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArchiveMonths() async {
    setState(() => _isLoading = true);
    try {
      // جلب جميع الطلبات المؤرشفة
      final response = await ApiService.getArchivedOrders();
      if (response['success'] == true && mounted) {
        final orders = response['orders'] as List;
        
        // تجميع الطلبات حسب الأشهر
        Map<String, List<Map<String, dynamic>>> monthsMap = {};
        
        for (var order in orders) {
          try {
            final date = DateTime.parse(order['created_at']);
            final monthKey = DateFormat('yyyy-MM').format(date);
            
            if (!monthsMap.containsKey(monthKey)) {
              monthsMap[monthKey] = [];
            }
            monthsMap[monthKey]!.add(order);
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
        
        // تحويل إلى قائمة
        _allMonths = monthsMap.entries.map((entry) {
          final date = DateTime.parse('${entry.key}-01');
          final orders = entry.value;
          
          // حساب الإحصائيات
          double totalRevenue = 0;
          double totalProfit = 0;
          for (var order in orders) {
            totalRevenue += ((order['price'] ?? 0) as num).toDouble();
            totalProfit += ((order['profit'] ?? 0) as num).toDouble();
          }
          
          return {
            'key': entry.key,
            'month': _getMonthName(date.month),
            'year': date.year,
            'date': date,
            'orders': orders,
            'count': orders.length,
            'totalRevenue': totalRevenue,
            'totalProfit': totalProfit,
          };
        }).toList();
        
        // ترتيب حسب التاريخ (الأحدث أولاً)
        _allMonths.sort((a, b) => (b['key'] as String).compareTo(a['key'] as String));
        _filteredMonths = List.from(_allMonths);
        
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading archive: $e');
      if (mounted) {
        setState(() {
          _allMonths = [];
          _filteredMonths = [];
          _isLoading = false;
        });
      }
    }
  }

  void _filterMonths() {
    setState(() {
      _filteredMonths = _allMonths.where((month) {
        // تصفية حسب البحث
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final monthName = '${month['month']} ${month['year']}'.toLowerCase();
          
          // البحث في اسم الشهر
          if (monthName.contains(query)) {
            return true;
          }
          
          // البحث في الطلبات المؤرشفة
          final orders = month['orders'] as List;
          for (var order in orders) {
            final customerName = (order['customer_name'] ?? '').toString().toLowerCase();
            final productName = (order['product_name'] ?? '').toString().toLowerCase();
            final phone = (order['customer_phone'] ?? '').toString();
            final paymentMethod = (order['payment_method'] ?? '').toString().toLowerCase();
            
            if (customerName.contains(query) ||
                productName.contains(query) ||
                phone.contains(query) ||
                paymentMethod.contains(query)) {
              return true;
            }
          }
          
          return false;
        }
        
        // تصفية حسب التاريخ
        if (_filterStartDate != null || _filterEndDate != null) {
          final monthDate = month['date'] as DateTime;
          
          if (_filterStartDate != null && monthDate.isBefore(DateTime(_filterStartDate!.year, _filterStartDate!.month))) {
            return false;
          }
          
          if (_filterEndDate != null && monthDate.isAfter(DateTime(_filterEndDate!.year, _filterEndDate!.month))) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  void _toggleSelection(String monthKey) {
    setState(() {
      if (_selectedMonths.contains(monthKey)) {
        _selectedMonths.remove(monthKey);
        if (_selectedMonths.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedMonths.add(monthKey);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedMonths = _filteredMonths.map((m) => m['key'] as String).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMonths.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _exportToExcel() async {
    // TODO: تنفيذ التصدير إلى Excel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم تصدير ${_selectedMonths.length} شهر إلى Excel'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تحديد نطاق التاريخ',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'من تاريخ',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _filterStartDate != null 
                  ? DateFormat('yyyy/MM').format(_filterStartDate!)
                  : 'غير محدد',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              trailing: Icon(Icons.calendar_today, color: AppColors.primaryGold),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filterStartDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _filterStartDate = date);
                  Navigator.pop(context);
                  _showDateRangePicker();
                }
              },
            ),
            ListTile(
              title: Text(
                'إلى تاريخ',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _filterEndDate != null 
                  ? DateFormat('yyyy/MM').format(_filterEndDate!)
                  : 'غير محدد',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              trailing: Icon(Icons.calendar_today, color: AppColors.primaryGold),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _filterEndDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _filterEndDate = date);
                  Navigator.pop(context);
                  _showDateRangePicker();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStartDate = null;
                _filterEndDate = null;
              });
              _filterMonths();
              Navigator.pop(context);
            },
            child: Text('إعادة تعيين', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _filterMonths();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: AppColors.pureBlack,
            ),
            child: Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      endDrawer: const AppDrawer(currentRoute: '/archive'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isSelectionMode ? '${_selectedMonths.length} محدد' : 'الأرشيف',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textGold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.select_all, color: AppColors.primaryGold),
              onPressed: _selectAll,
              tooltip: 'تحديد الكل',
            ),
            IconButton(
              icon: Icon(Icons.file_download, color: AppColors.primaryGold),
              onPressed: _exportToExcel,
              tooltip: 'تصدير إلى Excel',
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.primaryGold),
              onPressed: _clearSelection,
              tooltip: 'إلغاء التحديد',
            ),
          ] else
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primaryGold),
              onPressed: _loadArchiveMonths,
              tooltip: 'تحديث',
            ),
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: AppColors.primaryGold),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'القائمة',
            ),
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
              ? Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : Column(
                  children: [
                    // شريط البحث والفلترة
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    
                    // قائمة الأشهر
                    Expanded(
                      child: _filteredMonths.isEmpty
                          ? _buildEmptyState()
                          : _buildMonthsGrid(),
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
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [AppColors.glassWhite, AppColors.glassBlack],
                  ),
                  border: Border.all(color: AppColors.primaryGold.withOpacity(0.3), width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن شهر...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppColors.primaryGold),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _filterMonths();
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _showDateRangePicker,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGold, AppColors.mediumGold],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.date_range,
                  color: AppColors.pureBlack,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: _filteredMonths.length,
      itemBuilder: (context, index) {
        final month = _filteredMonths[index];
        final isSelected = _selectedMonths.contains(month['key']);
        
        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 100 + (index * 50)),
          child: _buildMonthCard(month, isSelected),
        );
      },
    );
  }

  Widget _buildMonthCard(Map<String, dynamic> month, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(month['key']);
        } else {
          // الانتقال إلى صفحة الأيام
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArchiveMonthScreen(
                monthKey: month['key'],
                monthName: month['month'],
                year: month['year'],
                orders: month['orders'],
              ),
            ),
          );
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _toggleSelection(month['key']);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(isSelected ? 0.95 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: AppColors.pureBlack,
                    size: 12,
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        color: AppColors.primaryGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      month['month'],
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${month['year']}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag, size: 14, color: AppColors.primaryGold),
                        const SizedBox(width: 4),
                        Text(
                          '${month['count']} طلب',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'لا توجد نتائج' : 'الأرشيف فارغ',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'جرب البحث بكلمات مختلفة'
                : 'سيتم عرض الطلبات المؤرشفة هنا',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

}
