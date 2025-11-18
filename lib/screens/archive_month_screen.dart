import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'archive_day_screen.dart';

/// صفحة الشهر في الأرشيف - تعرض الأيام والطلبات
class ArchiveMonthScreen extends StatefulWidget {
  final String monthKey;
  final String monthName;
  final int year;
  final List<Map<String, dynamic>> orders;

  const ArchiveMonthScreen({
    super.key,
    required this.monthKey,
    required this.monthName,
    required this.year,
    required this.orders,
  });

  @override
  State<ArchiveMonthScreen> createState() => _ArchiveMonthScreenState();
}

class _ArchiveMonthScreenState extends State<ArchiveMonthScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _allDays = [];
  List<Map<String, dynamic>> _filteredDays = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSelectionMode = false;
  Set<String> _selectedDays = {};
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _groupOrdersByDay();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _groupOrdersByDay() {
    Map<String, List<Map<String, dynamic>>> daysMap = {};

    for (var order in widget.orders) {
      try {
        final date = DateTime.parse(order['created_at']);
        final dayKey = DateFormat('yyyy-MM-dd').format(date);

        if (!daysMap.containsKey(dayKey)) {
          daysMap[dayKey] = [];
        }
        daysMap[dayKey]!.add(order);
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    _allDays = daysMap.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final orders = entry.value;

      double totalRevenue = 0;
      double totalProfit = 0;
      for (var order in orders) {
        totalRevenue += ((order['price'] ?? 0) as num).toDouble();
        totalProfit += ((order['profit'] ?? 0) as num).toDouble();
      }

      return {
        'key': entry.key,
        'day': date.day,
        'dayName': _getDayName(date.weekday),
        'date': date,
        'orders': orders,
        'count': orders.length,
        'totalRevenue': totalRevenue,
        'totalProfit': totalProfit,
      };
    }).toList();

    _allDays.sort((a, b) => (b['key'] as String).compareTo(a['key'] as String));
    _filteredDays = List.from(_allDays);
  }

  String _getDayName(int weekday) {
    const days = [
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    return days[weekday - 1];
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredDays = List.from(_allDays);
      });
      return;
    }

    // البحث الذكي في جميع الطلبات
    final query = _searchQuery.toLowerCase().trim();
    List<Map<String, dynamic>> results = [];

    for (var order in widget.orders) {
      bool matches = false;

      // البحث في اسم الزبون (ذكي - يتجاهل الفراغات والفواصل)
      final customerName = (order['customer_name'] ?? '').toString().toLowerCase();
      final cleanCustomerName = customerName.replaceAll(RegExp(r'[\s,،-]'), '');
      final cleanQuery = query.replaceAll(RegExp(r'[\s,،-]'), '');
      if (cleanCustomerName.contains(cleanQuery) || customerName.contains(query)) {
        matches = true;
      }

      // البحث في اسم المنتج
      final productName = (order['product_name'] ?? '').toString().toLowerCase();
      if (productName.contains(query)) {
        matches = true;
      }

      // البحث في رقم الهاتف
      final phone = (order['customer_phone'] ?? '').toString();
      if (phone.contains(query)) {
        matches = true;
      }

      // البحث في طريقة الدفع
      final paymentMethod = (order['payment_method'] ?? '').toString().toLowerCase();
      if (paymentMethod.contains(query)) {
        matches = true;
      }

      // البحث في المبلغ
      final price = (order['price'] ?? 0).toString();
      if (price.contains(query)) {
        matches = true;
      }

      // البحث في الملاحظات
      final notes = (order['notes'] ?? '').toString().toLowerCase();
      if (notes.contains(query)) {
        matches = true;
      }

      if (matches) {
        results.add(order);
      }
    }

    setState(() {
      _searchResults = results;
      if (results.isNotEmpty) {
        _filteredDays = [];
      } else {
        _filteredDays = List.from(_allDays);
      }
    });
  }

  void _filterDays() {
    setState(() {
      _filteredDays = _allDays.where((day) {
        if (_filterStartDate != null || _filterEndDate != null) {
          final dayDate = day['date'] as DateTime;

          if (_filterStartDate != null &&
              dayDate.isBefore(_filterStartDate!)) {
            return false;
          }

          if (_filterEndDate != null && dayDate.isAfter(_filterEndDate!)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _toggleSelection(String dayKey) {
    setState(() {
      if (_selectedDays.contains(dayKey)) {
        _selectedDays.remove(dayKey);
        if (_selectedDays.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedDays.add(dayKey);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedDays = _filteredDays.map((d) => d['key'] as String).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDays.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _exportToExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('سيتم تصدير ${_selectedDays.length} يوم إلى Excel'),
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
          'تحديد نطاق الأيام',
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'من يوم',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _filterStartDate != null
                    ? DateFormat('yyyy/MM/dd').format(_filterStartDate!)
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
                'إلى يوم',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                _filterEndDate != null
                    ? DateFormat('yyyy/MM/dd').format(_filterEndDate!)
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
              _filterDays();
              Navigator.pop(context);
            },
            child: Text('إعادة تعيين',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _filterDays();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isSelectionMode
              ? '${_selectedDays.length} محدد'
              : '${widget.monthName} ${widget.year}',
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
          ],
        ],
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
              // شريط البحث
              _buildSearchBar(),
              const SizedBox(height: 16),

              // المحتوى
              Expanded(
                child: _searchResults.isNotEmpty
                    ? _buildSearchResults()
                    : _filteredDays.isEmpty
                        ? _buildEmptyState()
                        : _buildDaysGrid(),
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
                  border: Border.all(
                      color: AppColors.primaryGold.withOpacity(0.3), width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'ابحث (اسم، منتج، طريقة دفع، مبلغ)...',
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

  Widget _buildDaysGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: _filteredDays.length,
      itemBuilder: (context, index) {
        final day = _filteredDays[index];
        final isSelected = _selectedDays.contains(day['key']);

        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 50 + (index * 30)),
          child: _buildDayCard(day, isSelected),
        );
      },
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(day['key']);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArchiveDayScreen(
                dayKey: day['key'],
                day: day['day'],
                dayName: day['dayName'],
                monthName: widget.monthName,
                year: widget.year,
                orders: day['orders'],
              ),
            ),
          );
        }
      },
      onLongPress: () {
        setState(() {
          _isSelectionMode = true;
          _toggleSelection(day['key']);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(isSelected ? 0.95 : 1.0),
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
            color: isSelected
                ? AppColors.primaryGold
                : AppColors.primaryGold.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 1,
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
                        Icons.today,
                        color: AppColors.primaryGold,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${day['day']}',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.textGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day['dayName'],
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
                          '${day['count']}',
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

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final order = _searchResults[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: 50 + (index * 30)),
          child: _buildOrderCard(order),
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final date = DateTime.parse(order['created_at']);
    final formattedDate = DateFormat('yyyy/MM/dd - hh:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.glassWhite, AppColors.glassBlack],
        ),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['customer_name'] ?? '',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order['payment_method'] ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order['product_name'] ?? '',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${NumberFormat('#,##0').format(order['price'])} د.ع',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أيام',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
