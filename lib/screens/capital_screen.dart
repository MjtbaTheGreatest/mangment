import 'dart:async';
import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:fl_chart/fl_chart.dart';

// RouteObserver للكشف عن حالة الصفحة - متاح عالمياً
final RouteObserver<PageRoute> capitalRouteObserver = RouteObserver<PageRoute>();

/// صفحة رأس المال المتطورة
class CapitalScreen extends StatefulWidget {
  const CapitalScreen({super.key});

  @override
  State<CapitalScreen> createState() => _CapitalScreenState();
}

class _CapitalScreenState extends State<CapitalScreen> with TickerProviderStateMixin, RouteAware {
  bool _isLoading = true;
  bool _isFirstLoad = true;
  Map<String, dynamic> _capitalData = {};
  late AnimationController _capitalAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _capitalAnimation;
  final TextEditingController _amountController = TextEditingController();
  double _previousCapital = 0;
  double _currentCapital = 0;
  List<Map<String, dynamic>> _dailyExpenses = [];
  
  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _capitalAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _capitalAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _capitalAnimationController, curve: Curves.easeOutCubic),
    );
    
    _loadCapitalData();
    _startAutoRefresh();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      capitalRouteObserver.subscribe(this, route);
    }
  }
  
  @override
  void didPopNext() {
    // عندما ترجع لهذه الصفحة من صفحة أخرى - ابدأ التحديث
    _startAutoRefresh();
  }
  
  @override
  void didPushNext() {
    // عندما تنتقل لصفحة أخرى - أوقف التحديث
    _stopAutoRefresh();
  }
  
  @override
  void didPush() {
    // عندما تفتح هذه الصفحة لأول مرة
    _startAutoRefresh();
  }
  
  @override
  void didPop() {
    // عندما تغلق هذه الصفحة
    _stopAutoRefresh();
  }
  
  void _startAutoRefresh() {
    // تجنب إنشاء تايمر مكرر إذا كان موجود بالفعل
    if (_refreshTimer != null && _refreshTimer!.isActive) {
      return;
    }
    
    // تحديث تلقائي كل 3 ثوانٍ - فقط عندما تكون الصفحة مفتوحة
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // التحقق من أن الصفحة مازالت نشطة ومفتوحة
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _loadCapitalData();
      }
    });
  }
  
  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    capitalRouteObserver.unsubscribe(this);
    _stopAutoRefresh();
    _capitalAnimationController.dispose();
    _pulseController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadCapitalData() async {
    if (_isFirstLoad) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await ApiService.getCapitalInfo();
      
      if (mounted && response['success'] == true) {
        final capitalData = response['capital'];
        final newCapital = ((capitalData['currentCapital'] ?? 0) as num).toDouble();
        
        // Check if capital changed before setState
        final capitalChanged = !_isFirstLoad && _currentCapital != newCapital;
        
        setState(() {
          if (_isFirstLoad) {
            // On first load, set both to the same value to avoid animation
            _previousCapital = newCapital;
            _currentCapital = newCapital;
          } else {
            // On subsequent loads, animate from previous to new value
            _previousCapital = _currentCapital;
            _currentCapital = newCapital;
          }
          _capitalData = capitalData; // Use the fixed capitalData
          _processDailyExpenses();
          _isLoading = false;
        });
        
        // تشغيل الأنيميشن عند التغيير
        if (capitalChanged) {
          _capitalAnimationController.reset();
          _capitalAnimationController.forward();
          _pulseController.forward().then((_) => _pulseController.reverse());
        } else if (_isFirstLoad) {
          _capitalAnimationController.value = 1.0; // Skip animation on first load
          _isFirstLoad = false;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('خطأ في الاتصال', isError: true);
      }
    }
  }

  void _processDailyExpenses() {
    final transactions = (_capitalData['transactions'] as List?) ?? [];
    Map<String, double> dailyDeposits = {};
    Map<String, double> dailyWithdrawals = {};
    
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    // Initialize all days in the month
    for (int day = 1; day <= endOfMonth.day; day++) {
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      dailyDeposits[dateKey] = 0;
      dailyWithdrawals[dateKey] = 0;
    }
    
    // Process transactions
    for (var transaction in transactions) {
      try {
        final date = DateTime.parse(transaction['created_at']);
        if (date.year == now.year && date.month == now.month) {
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final amount = ((transaction['amount'] ?? 0) as num).toDouble();
          final type = (transaction['type'] ?? '').toString().toLowerCase();
          
          if (type == 'deposit' || type == 'إضافة') {
            dailyDeposits[dateKey] = (dailyDeposits[dateKey] ?? 0) + amount;
          } else if (type == 'withdraw' || type == 'سحب') {
            dailyWithdrawals[dateKey] = (dailyWithdrawals[dateKey] ?? 0) + amount;
          }
        }
      } catch (e) {}
    }
    
    // Create combined list with both deposits and withdrawals
    _dailyExpenses = dailyDeposits.keys.map((dateKey) {
      final date = DateTime.parse(dateKey);
      return {
        'date': date,
        'day': date.day,
        'deposits': dailyDeposits[dateKey] ?? 0,
        'withdrawals': dailyWithdrawals[dateKey] ?? 0,
      };
    }).toList()..sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));
  }

  Future<void> _addCapital() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showMessage('الرجاء إدخال مبلغ صحيح', isError: true);
      return;
    }

    try {
      final response = await ApiService.addCapital(amount);
      if (response['success'] == true && mounted) {
        _showMessage('✅ تم إضافة ${_formatCurrency(amount)} د.ع بنجاح');
        _amountController.clear();
        await _loadCapitalData();
      }
    } catch (e) {
      _showMessage('حدث خطأ', isError: true);
    }
  }

  Future<void> _withdrawCapital() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showMessage('الرجاء إدخال مبلغ صحيح', isError: true);
      return;
    }

    try {
      final response = await ApiService.withdrawCapital(amount);
      if (response['success'] == true && mounted) {
        _showMessage('✅ تم سحب ${_formatCurrency(amount)} د.ع بنجاح');
        _amountController.clear();
        await _loadCapitalData();
      }
    } catch (e) {
      _showMessage('حدث خطأ', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCurrency(num amount) {
    return NumberFormat('#,##0', 'en_US').format(amount);
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
            'إدارة رأس المال',
            style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primaryGold),
              onPressed: _loadCapitalData,
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildAnimatedCapitalCard(),
                        const SizedBox(height: 24),
                        _buildCapitalOperations(),
                        const SizedBox(height: 24),
                        _buildMonthlyChart(),
                        const SizedBox(height: 24),
                        _buildCompactTransactionsHistory(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2C1810).withOpacity(0.8),
              const Color(0xFF1A0F0A).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💰', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(
                  'إدارة رأس المال',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'متابعة مباشرة لحركة رأس المال والمصروفات',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textGold.withOpacity(0.7),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildAnimatedCapitalCard() {
    final currentCapital = _currentCapital;
    final totalDeposits = ((_capitalData['totalDeposits'] ?? 0) as num).toDouble();
    final totalWithdrawals = ((_capitalData['totalWithdrawals'] ?? 0) as num).toDouble();
    final isNegative = currentCapital < 0;

    return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.05),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isNegative
                      ? [Colors.red.shade900.withOpacity(0.3), Colors.red.shade800.withOpacity(0.2)]
                      : [Colors.green.shade900.withOpacity(0.3), Colors.green.shade700.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isNegative ? Colors.red.withOpacity(0.5) : Colors.green.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isNegative ? Colors.red : Colors.green).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'رأس المال الحالي',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textGold.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _capitalAnimation,
                    builder: (context, child) {
                      final animatedValue = _previousCapital + (_currentCapital - _previousCapital) * _capitalAnimation.value;
                      return Text(
                        '${_formatCurrency(animatedValue)} د.ع',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: isNegative ? Colors.red.shade300 : Colors.green.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      );
                    },
                  ),
                  if (isNegative) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⚠️ رأس المال بالسالب - يُرجى الإضافة',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red.shade300,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('📥', 'إجمالي الإيداعات', '${_formatCurrency(totalDeposits)} د.ع', Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem('📤', 'إجمالي السحوبات', '${_formatCurrency(totalWithdrawals)} د.ع', Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
    );
  }

  Widget _buildStatItem(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textGold.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCapitalOperations() {
    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: AppColors.primaryGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  'عمليات رأس المال',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'المبلغ (دينار عراقي)',
                hintText: '0',
                prefixIcon: Icon(Icons.payments, color: AppColors.primaryGold),
                filled: true,
                fillColor: AppColors.charcoal.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addCapital,
                    icon: Icon(Icons.add_circle),
                    label: Text('إضافة رأس مال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _withdrawCapital,
                    icon: Icon(Icons.remove_circle),
                    label: Text('سحب رأس مال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }

  Widget _buildMonthlyChart() {
    if (_dailyExpenses.isEmpty) return const SizedBox.shrink();

    // Calculate max value for chart scaling
    double maxDeposit = 0;
    double maxWithdrawal = 0;
    
    for (var day in _dailyExpenses) {
      final deposits = (day['deposits'] as double?) ?? 0;
      final withdrawals = (day['withdrawals'] as double?) ?? 0;
      if (deposits > maxDeposit) maxDeposit = deposits;
      if (withdrawals > maxWithdrawal) maxWithdrawal = withdrawals;
    }
    
    final maxValue = maxDeposit > maxWithdrawal ? maxDeposit : maxWithdrawal;
    final chartMax = maxValue > 1000000 ? maxValue * 1.2 : 1000000.0;

    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppColors.primaryGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  'حركة رأس المال الشهرية',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('إضافات', Colors.green),
                const SizedBox(width: 24),
                _buildLegendItem('سحوبات', Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartMax / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: chartMax / 5,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              _formatChartValue(value),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: AppColors.textSecondary.withOpacity(0.3), width: 1),
                      bottom: BorderSide(color: AppColors.textSecondary.withOpacity(0.3), width: 1),
                    ),
                  ),
                  minX: 1,
                  maxX: _dailyExpenses.length.toDouble(),
                  minY: 0,
                  maxY: chartMax,
                  lineBarsData: [
                    // Green line for deposits
                    LineChartBarData(
                      spots: _dailyExpenses.asMap().entries.map((entry) {
                        return FlSpot(
                          (entry.key + 1).toDouble(),
                          (entry.value['deposits'] as double?) ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.green.shade400,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.green.shade300,
                            strokeWidth: 2,
                            strokeColor: Colors.green.shade700,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.2),
                            Colors.green.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Red line for withdrawals
                    LineChartBarData(
                      spots: _dailyExpenses.asMap().entries.map((entry) {
                        return FlSpot(
                          (entry.key + 1).toDouble(),
                          (entry.value['withdrawals'] as double?) ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.red.shade400,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: Colors.red.shade300,
                            strokeWidth: 2,
                            strokeColor: Colors.red.shade700,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.2),
                            Colors.red.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOutCubic,
              ),
            ),
          ],
        ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textGold.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  String _formatChartValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}م';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}ألف';
    }
    return value.toStringAsFixed(0);
  }
  
  Future<void> _showDeleteDateDialog(DateTime date, List<Map<String, dynamic>> transactions) async {
    final arabicMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final monthName = arabicMonths[date.month - 1];
    final dateStr = '${date.day} $monthName';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text(
                'تأكيد الحذف',
                style: TextStyle(color: AppColors.textGold, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من حذف جميع عمليات يوم $dateStr؟',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سيتم حذف ${transactions.length} عملية:',
                      style: TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ...transactions.take(3).map((t) {
                      final amount = ((t['amount'] ?? 0) as num).toDouble();
                      final type = (t['type'] ?? '').toString();
                      final isDeposit = type.toLowerCase() == 'deposit' || type == 'إضافة';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• ${isDeposit ? "إضافة" : "سحب"}: ${_formatCurrency(amount)} د.ع',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      );
                    }),
                    if (transactions.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• و ${transactions.length - 3} عملية أخرى...',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '⚠️ هذا الإجراء لا يمكن التراجع عنه',
                style: TextStyle(color: Colors.orange.shade300, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    
    if (confirmed == true) {
      await _deleteTransactionsByDate(date, transactions);
    }
  }
  
  Future<void> _deleteTransactionsByDate(DateTime date, List<Map<String, dynamic>> transactions) async {
    try {
      final result = await ApiService.deleteTransactionsByDate(date);
      
      if (result['success'] == true) {
        final deletedCount = result['deletedCount'] ?? transactions.length;
        _showMessage('✅ تم حذف $deletedCount عملية بنجاح');
        await _loadCapitalData();
      } else {
        _showMessage(result['message'] ?? 'حدث خطأ أثناء الحذف', isError: true);
      }
    } catch (e) {
      _showMessage('حدث خطأ أثناء الحذف', isError: true);
    }
  }

  Widget _buildCompactTransactionsHistory() {
    final transactions = (_capitalData['transactions'] as List?) ?? [];
    Map<String, List<Map<String, dynamic>>> dailyTransactions = {};
    
    for (var transaction in transactions) {
      try {
        final date = DateTime.parse(transaction['created_at']);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        
        if (!dailyTransactions.containsKey(dateKey)) {
          dailyTransactions[dateKey] = [];
        }
        dailyTransactions[dateKey]!.add(transaction);
      } catch (e) {}
    }
    
    final sortedDays = dailyTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.charcoal.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.primaryGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  'سجل العمليات اليومي',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            sortedDays.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 60, color: AppColors.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('لا توجد عمليات بعد', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : Column(
                    children: sortedDays.take(10).map((dateKey) {
                      final date = DateTime.parse(dateKey);
                      final dayTransactions = dailyTransactions[dateKey]!;
                      return _buildDailyTransactionCard(date, dayTransactions);
                    }).toList(),
                  ),
          ],
        ),
    );
  }

  Widget _buildDailyTransactionCard(DateTime date, List<Map<String, dynamic>> transactions) {
    // Format date without requiring locale initialization
    final arabicDays = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final arabicMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final dayName = arabicDays[date.weekday - 1];
    final monthName = arabicMonths[date.month - 1];
    final formattedDate = '$dayName، ${date.day} $monthName';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.glassBlack.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                formattedDate,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
              onPressed: () => _showDeleteDateDialog(date, transactions),
              tooltip: 'حذف عمليات هذا اليوم',
            ),
          ],
        ),
        subtitle: Text('${transactions.length} عملية', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        children: transactions.map((t) {
          final amount = ((t['amount'] ?? 0) as num).toDouble();
          final type = (t['type'] ?? '').toString();
          final isDeposit = type.toLowerCase() == 'deposit' || type == 'إضافة';
          final displayType = isDeposit ? 'إضافة' : 'سحب';
          
          return ListTile(
            leading: Icon(
              isDeposit ? Icons.add_circle : Icons.remove_circle,
              color: isDeposit ? Colors.green : Colors.red,
            ),
            title: Text(displayType, style: TextStyle(color: AppColors.textGold)),
            trailing: Text(
              '${_formatCurrency(amount)} د.ع',
              style: TextStyle(
                color: isDeposit ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.charcoal,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('💰 رأس المال', style: TextStyle(color: AppColors.textGold, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('إدارة مالية متقدمة', style: TextStyle(color: AppColors.textGold.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: AppColors.primaryGold),
            title: Text('الصفحة الرئيسية', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          Divider(color: AppColors.primaryGold.withOpacity(0.2)),
          ListTile(
            leading: Icon(Icons.subscriptions, color: AppColors.primaryGold),
            title: Text('إدارة الاشتراكات', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/subscriptions');
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_bag, color: AppColors.primaryGold),
            title: Text('إدارة الطلبات', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/orders');
            },
          ),
          ListTile(
            leading: Icon(Icons.archive, color: AppColors.primaryGold),
            title: Text('الأرشيف', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/archive');
            },
          ),
          Divider(color: AppColors.primaryGold.withOpacity(0.2)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('إدارة المدير', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.bar_chart, color: AppColors.primaryGold),
            title: Text('الإحصائيات', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/statistics');
            },
          ),
          ListTile(
            leading: Icon(Icons.account_balance_wallet, color: AppColors.primaryGold),
            title: Text('رأس المال', style: TextStyle(color: AppColors.textPrimary)),
            selected: true,
            selectedTileColor: AppColors.primaryGold.withOpacity(0.1),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.people, color: AppColors.primaryGold),
            title: Text('إدارة الموظفين', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/employees');
            },
          ),
        ],
      ),
    );
  }
}