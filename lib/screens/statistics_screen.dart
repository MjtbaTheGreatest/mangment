import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:io';
import 'dart:convert';

/// صفحة الإحصائيات المتطورة - للمدير فقط
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  late AnimationController _animationController;
  String _selectedPeriod = 'شهري'; // شهري، أسبوعي، يومي
  String _selectedChart = 'الإيرادات'; // الإيرادات، الأرباح، الطلبات

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
      final response = await ApiService.getCurrentMonthStatistics();
      if (response['success'] == true && mounted) {
        setState(() {
          _statistics = response['statistics'] ?? {};
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showMessage('فشل تحميل الإحصائيات', isError: true);
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل الإحصائيات: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('خطأ في الاتصال', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('📊 الإحصائيات المتقدمة', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold)),
              Text(
                'الشهر الحالي: ${_getCurrentMonthName()}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primaryGold),
              onPressed: _loadStatistics,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _loadStatistics,
                    color: AppColors.primaryGold,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildKPICards(),
                          const SizedBox(height: 24),
                          _buildAdvancedChart(),
                          const SizedBox(height: 24),
                          _buildPaymentMethodsAnalysis(),
                          const SizedBox(height: 24),
                          _buildMonthlyComparison(),
                          const SizedBox(height: 24),
                          _buildDailyOrdersHeatmap(),
                          const SizedBox(height: 24),
                          _buildTopProductsSection(),
                          const SizedBox(height: 24),
                          _buildProfitMarginAnalysis(),
                          const SizedBox(height: 24),
                          _buildYearlyAnalysis(),
                          const SizedBox(height: 24),
                          _buildExportSection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ========== KPI Cards - البطاقات الرئيسية ==========
  Widget _buildKPICards() {
    final totalOrders = (_statistics['totalOrders'] ?? 0) as int;
    final totalRevenue = ((_statistics['totalRevenue'] ?? 0) as num).toDouble();
    final totalCosts = ((_statistics['totalCosts'] ?? 0) as num).toDouble();
    final totalProfit = totalRevenue - totalCosts;
    final profitMargin = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100) : 0.0;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKPICard('إجمالي الطلبات', '$totalOrders', Icons.shopping_cart, Colors.blue, '📦')),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard('إجمالي المبيعات', '${_formatCurrency(totalRevenue)} د.ع', Icons.attach_money, Colors.green, '💰')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildKPICard('إجمالي التكاليف', '${_formatCurrency(totalCosts)} د.ع', Icons.shopping_bag, Colors.orange, '💸')),
              const SizedBox(width: 12),
              Expanded(child: _buildKPICard('صافي الأرباح', '${_formatCurrency(totalProfit)} د.ع', Icons.trending_up, Colors.purple, '📈')),
            ],
          ),
          const SizedBox(height: 12),
          _buildKPICard('هامش الربح', '${profitMargin.toStringAsFixed(1)}%', Icons.percent, Colors.cyan, '💎', fullWidth: true),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color, String emoji, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
              const Spacer(),
              Icon(icon, color: color, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: fullWidth ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ========== Advanced Chart - الرسم البياني المتقدم ==========
  Widget _buildAdvancedChart() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.glassBlack.withOpacity(0.5), AppColors.charcoal.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📊 التحليل الزمني',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
                ),
                const Spacer(),
                _buildPeriodSelector(),
              ],
            ),
            const SizedBox(height: 8),
            _buildChartTypeSelector(),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: _buildLineChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['يومي', 'أسبوعي', 'شهري'].map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [AppColors.primaryGold, Colors.amber.shade700]) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['الإيرادات', 'الأرباح', 'الطلبات', 'التكاليف'].map((type) {
          final isSelected = _selectedChart == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedChart = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGold.withOpacity(0.2) : AppColors.glassBlack.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryGold : AppColors.textSecondary.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type == 'الإيرادات' ? Icons.attach_money :
                      type == 'الأرباح' ? Icons.trending_up :
                      type == 'الطلبات' ? Icons.shopping_cart : Icons.shopping_bag,
                      color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    // حسب الفترة المختارة نجيب البيانات المناسبة
    List<dynamic> chartData = [];
    
    if (_selectedPeriod == 'شهري') {
      chartData = (_statistics['monthlyData'] as List?) ?? [];
    } else if (_selectedPeriod == 'يومي') {
      chartData = (_statistics['dailyOrders'] as List?) ?? [];
    } else if (_selectedPeriod == 'أسبوعي') {
      // تحويل البيانات اليومية إلى أسبوعية
      final dailyData = (_statistics['dailyOrders'] as List?) ?? [];
      chartData = _convertToWeeklyData(dailyData);
    }

    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 60, color: AppColors.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'لا توجد بيانات للفترة المحددة',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    List<FlSpot> spots = [];
    List<String> labels = [];
    double maxY = 0;
    double minY = double.infinity;

    for (int i = 0; i < chartData.length; i++) {
      final data = chartData[i];
      double value = 0;
      String label = '';

      if (_selectedPeriod == 'شهري') {
        label = _getMonthName(data['month']);
        if (_selectedChart == 'الإيرادات') {
          value = ((data['total_revenue'] ?? 0) as num).toDouble();
        } else if (_selectedChart == 'الأرباح') {
          final revenue = ((data['total_revenue'] ?? 0) as num).toDouble();
          final cost = ((data['total_cost'] ?? 0) as num).toDouble();
          value = revenue - cost;
        } else if (_selectedChart == 'الطلبات') {
          value = ((data['total_orders'] ?? 0) as num).toDouble();
        } else if (_selectedChart == 'التكاليف') {
          value = ((data['total_cost'] ?? 0) as num).toDouble();
        }
      } else if (_selectedPeriod == 'يومي') {
        final date = DateTime.parse(data['date']);
        label = '${date.day}/${date.month}';
        
        if (_selectedChart == 'الإيرادات') {
          value = ((data['total_revenue'] ?? 0) as num).toDouble();
        } else if (_selectedChart == 'الأرباح') {
          final revenue = ((data['total_revenue'] ?? 0) as num).toDouble();
          final cost = ((data['total_cost'] ?? 0) as num).toDouble();
          value = revenue - cost;
        } else if (_selectedChart == 'الطلبات') {
          value = ((data['count'] ?? 0) as num).toDouble();
        } else if (_selectedChart == 'التكاليف') {
          value = ((data['total_cost'] ?? 0) as num).toDouble();
        }
      } else if (_selectedPeriod == 'أسبوعي') {
        label = data['label'];
        
        if (_selectedChart == 'الإيرادات') {
          value = ((data['total_revenue'] ?? 0) as num).toDouble();
        } else if (_selectedChart == 'الأرباح') {
          value = ((data['profit'] ?? 0) as num).toDouble();
        } else if (_selectedChart == 'الطلبات') {
          value = ((data['count'] ?? 0) as num).toDouble();
        } else if (_selectedChart == 'التكاليف') {
          value = ((data['total_cost'] ?? 0) as num).toDouble();
        }
      }

      spots.add(FlSpot(i.toDouble(), value));
      labels.add(label);
      if (value > maxY) maxY = value;
      if (value < minY) minY = value;
    }

    // ضبط النطاق للرسم البياني
    final yRange = maxY - minY;
    final adjustedMaxY = maxY + (yRange * 0.2);
    final adjustedMinY = (minY > 0 ? math.max(0.0, minY - (yRange * 0.1)) : 0.0).toDouble();

    // اختيار اللون حسب نوع البيانات
    final chartColor = _getChartColor(_selectedChart);

    return LineChart(
      LineChartData(
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: math.max(1, (adjustedMaxY - adjustedMinY) / 5),
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.primaryGold.withOpacity(0.08),
            strokeWidth: 1.5,
            dashArray: [8, 4],
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: AppColors.primaryGold.withOpacity(0.05),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: _selectedPeriod == 'يومي' ? (labels.length / 6).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Transform.rotate(
                      angle: _selectedPeriod == 'يومي' ? -0.5 : 0,
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          color: AppColors.textGold.withOpacity(0.7),
                          fontSize: _selectedPeriod == 'يومي' ? 9 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              interval: math.max(1, (adjustedMaxY - adjustedMinY) / 5),
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    _formatChartValue(value),
                    style: TextStyle(
                      color: AppColors.textGold.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: AppColors.primaryGold.withOpacity(0.3), width: 2),
            left: BorderSide(color: AppColors.primaryGold.withOpacity(0.3), width: 2),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            preventCurveOverShooting: true,
            gradient: LinearGradient(
              colors: [
                chartColor,
                chartColor.withOpacity(0.8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            barWidth: 5,
            isStrokeCapRound: true,
            shadow: Shadow(
              color: chartColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 7,
                  color: Colors.white,
                  strokeWidth: 4,
                  strokeColor: chartColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  chartColor.withOpacity(0.4),
                  chartColor.withOpacity(0.2),
                  chartColor.withOpacity(0.05),
                  chartColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchSpotThreshold: 50,
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: chartColor.withOpacity(0.5),
                  strokeWidth: 3,
                  dashArray: [6, 3],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 10,
                      color: Colors.white,
                      strokeWidth: 5,
                      strokeColor: chartColor,
                    );
                  },
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => chartColor.withOpacity(0.95),
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            tooltipMargin: 12,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                String dateLabel = '';
                if (index >= 0 && index < labels.length) {
                  dateLabel = labels[index];
                }
                
                String valueLabel = '';
                if (_selectedChart == 'الطلبات') {
                  valueLabel = '${spot.y.toInt()} طلب';
                } else {
                  valueLabel = '${_formatCurrency(spot.y)} د.ع';
                }

                return LineTooltipItem(
                  '$dateLabel\n$valueLabel',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  List<Map<String, dynamic>> _convertToWeeklyData(List<dynamic> dailyData) {
    if (dailyData.isEmpty) return [];
    
    List<Map<String, dynamic>> weeklyData = [];
    int weekCount = 0;
    int totalOrders = 0;
    double totalRevenue = 0;
    double totalCost = 0;
    int daysInWeek = 0;

    for (int i = 0; i < dailyData.length; i++) {
      final data = dailyData[i];
      totalOrders += (data['count'] as int? ?? 0);
      totalRevenue += ((data['total_revenue'] ?? 0) as num).toDouble();
      totalCost += ((data['total_cost'] ?? 0) as num).toDouble();
      daysInWeek++;

      if (daysInWeek == 7 || i == dailyData.length - 1) {
        weekCount++;
        weeklyData.add({
          'label': 'أسبوع $weekCount',
          'count': totalOrders,
          'total_revenue': totalRevenue,
          'total_cost': totalCost,
          'profit': totalRevenue - totalCost,
        });
        totalOrders = 0;
        totalRevenue = 0;
        totalCost = 0;
        daysInWeek = 0;
      }
    }

    return weeklyData;
  }

  Color _getChartColor(String chartType) {
    switch (chartType) {
      case 'الإيرادات':
        return Colors.green.shade600;
      case 'الأرباح':
        return Colors.purple.shade600;
      case 'الطلبات':
        return Colors.blue.shade600;
      case 'التكاليف':
        return Colors.orange.shade600;
      default:
        return AppColors.primaryGold;
    }
  }

  // ========== Payment Methods Analysis - تحليل طرق الدفع ==========
  Widget _buildPaymentMethodsAnalysis() {
    final paymentMethods = (_statistics['paymentMethods'] as List?) ?? [];
    if (paymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = paymentMethods.fold<double>(0, (sum, method) => sum + ((method['total'] ?? 0) as num).toDouble());

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.glassBlack.withOpacity(0.5), AppColors.charcoal.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '💳 تحليل طرق الدفع',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${paymentMethods.length} طريقة',
                    style: TextStyle(color: AppColors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 50,
                        sections: paymentMethods.asMap().entries.map((entry) {
                          final method = entry.value;
                          final value = ((method['total'] ?? 0) as num).toDouble();
                          final percentage = (value / total) * 100;
                          final color = _getPaymentMethodColor(method['method']);
                          
                          return PieChartSectionData(
                            color: color,
                            value: value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: paymentMethods.map<Widget>((method) {
                        final methodName = method['method'] ?? '';
                        final count = method['count'] ?? 0;
                        final value = ((method['total'] ?? 0) as num).toDouble();
                        final percentage = (value / total) * 100;
                        final color = _getPaymentMethodColor(methodName);
                        final emoji = _getPaymentMethodEmoji(methodName);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$emoji $methodName',
                                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '$count طلب • ${percentage.toStringAsFixed(1)}%',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${_formatCurrency(value)} د.ع',
                                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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

  // يتبع في التعليق القادم بسبب حد الطول...

  Widget _buildMonthlyComparison() {
    final monthlyData = (_statistics['monthlyData'] as List?) ?? [];
    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 600),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.glassBlack.withOpacity(0.5), AppColors.charcoal.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 المقارنة الشهرية',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxYForMonthlyComparison(monthlyData),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => AppColors.charcoal.withOpacity(0.9),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_formatCurrency(rod.toY)} د.ع',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                            final month = monthlyData[value.toInt()]['month'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _getMonthName(month),
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatChartValue(value),
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getMaxYForMonthlyComparison(monthlyData) / 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.textSecondary.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                      left: BorderSide(color: AppColors.textSecondary.withOpacity(0.2)),
                    ),
                  ),
                  barGroups: monthlyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final revenue = ((data['total_revenue'] ?? 0) as num).toDouble();
                    final cost = ((data['total_cost'] ?? 0) as num).toDouble();
                    final profit = revenue - cost;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: revenue,
                          color: Colors.green,
                          width: 15,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                        BarChartRodData(
                          toY: cost,
                          color: Colors.orange,
                          width: 15,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                        BarChartRodData(
                          toY: profit,
                          color: Colors.purple,
                          width: 15,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('المبيعات', Colors.green),
                const SizedBox(width: 16),
                _buildLegend('التكاليف', Colors.orange),
                const SizedBox(width: 16),
                _buildLegend('الأرباح', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDailyOrdersHeatmap() {
    final dailyOrders = (_statistics['dailyOrders'] as List?) ?? [];
    if (dailyOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    final last30Days = dailyOrders.length > 30 ? dailyOrders.sublist(dailyOrders.length - 30) : dailyOrders;
    final maxOrders = last30Days.fold<int>(0, (max, day) {
      final count = (day['count'] ?? 0) as int;
      return count > max ? count : max;
    });

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.glassBlack.withOpacity(0.5), AppColors.charcoal.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🔥 خريطة الطلبات اليومية',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
                ),
                const Spacer(),
                Text(
                  'آخر 30 يوم',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: last30Days.map<Widget>((day) {
                final date = DateTime.parse(day['date']);
                final count = (day['count'] ?? 0) as int;
                final intensity = maxOrders > 0 ? count / maxOrders : 0.0;
                final color = Color.lerp(
                  Colors.blue.shade900.withOpacity(0.2),
                  Colors.blue,
                  intensity,
                )!;
                
                return Tooltip(
                  message: '${date.day}/${date.month}: $count طلب',
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: intensity > 0.5 ? Colors.white.withOpacity(0.3) : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: intensity > 0.5 ? Colors.white : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: intensity > 0.7 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('أقل', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  final intensity = index / 4;
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.blue.shade900.withOpacity(0.2),
                        Colors.blue,
                        intensity,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text('أكثر', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsSection() {
    final topProducts = (_statistics['topProducts'] as List?) ?? [];
    if (topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 1000),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.glassBlack.withOpacity(0.5), AppColors.charcoal.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '🏆 أفضل المنتجات مبيعاً',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'أفضل ${topProducts.length}',
                    style: TextStyle(color: AppColors.primaryGold, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final name = product['product_name'] ?? 'غير محدد';
              final count = (product['count'] ?? 0) as int;
              final revenue = ((product['total_revenue'] ?? 0) as num).toDouble();
              
              final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '${index + 1}';
              final color = index == 0 ? Colors.amber : index == 1 ? Colors.grey.shade400 : index == 2 ? Colors.brown.shade400 : AppColors.primaryGold;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      medal,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count طلب',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_formatCurrency(revenue)} د.ع',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitMarginAnalysis() {
    final totalRevenue = ((_statistics['totalRevenue'] ?? 0) as num).toDouble();
    final totalCosts = ((_statistics['totalCosts'] ?? 0) as num).toDouble();
    final totalProfit = totalRevenue - totalCosts;
    final profitMargin = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100) : 0.0;

    Color getMarginColor(double margin) {
      if (margin >= 30) return Colors.green;
      if (margin >= 20) return Colors.blue;
      if (margin >= 10) return Colors.orange;
      return Colors.red;
    }

    final marginColor = getMarginColor(profitMargin);

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 1200),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [marginColor.withOpacity(0.2), marginColor.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: marginColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '💎 تحليل هامش الربح',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: profitMargin / 100,
                        strokeWidth: 20,
                        backgroundColor: AppColors.glassBlack.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(marginColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${profitMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: marginColor,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'هامش الربح',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMarginDetail('المبيعات', totalRevenue, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMarginDetail('التكاليف', totalCosts, Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMarginDetail('الأرباح', totalProfit, marginColor, fullWidth: true),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: marginColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    profitMargin >= 30 ? Icons.sentiment_very_satisfied :
                    profitMargin >= 20 ? Icons.sentiment_satisfied :
                    profitMargin >= 10 ? Icons.sentiment_neutral :
                    Icons.sentiment_dissatisfied,
                    color: marginColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profitMargin >= 30 ? 'هامش ربح ممتاز! 🎉 استمر على هذا الأداء' :
                      profitMargin >= 20 ? 'هامش ربح جيد جداً 👍 يمكنك تحسينه' :
                      profitMargin >= 10 ? 'هامش ربح مقبول ⚠️ راجع التكاليف' :
                      'هامش ربح ضعيف ⚠️ تحتاج لتحسين عاجل',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildMarginDetail(String label, double value, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatCurrency(value)} د.ع',
            style: TextStyle(
              color: color,
              fontSize: fullWidth ? 20 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  String _formatChartValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  String _getMonthName(int month) {
    const months = ['ين', 'فبر', 'مار', 'أبر', 'ماي', 'يون', 'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس'];
    return months[month - 1];
  }

  double _getMaxYForMonthlyComparison(List monthlyData) {
    double maxY = 0;
    for (var data in monthlyData) {
      final revenue = ((data['total_revenue'] ?? 0) as num).toDouble();
      if (revenue > maxY) maxY = revenue;
    }
    return maxY * 1.2;
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'نقد':
      case 'cash':
        return Colors.green;
      case 'زين كاش':
      case 'zain cash':
        return Colors.purple;
      case 'آسيا حواله':
      case 'asia':
        return Colors.orange;
      case 'فاست باي':
      case 'fastpay':
        return Colors.blue;
      default:
        return AppColors.primaryGold;
    }
  }

  String _getPaymentMethodEmoji(String method) {
    switch (method.toLowerCase()) {
      case 'نقد':
      case 'cash':
        return '💵';
      case 'زين كاش':
      case 'zain cash':
        return '📱';
      case 'آسيا حواله':
      case 'asia':
        return '🏦';
      case 'فاست باي':
      case 'fastpay':
        return '⚡';
      default:
        return '💳';
    }
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${months[now.month - 1]} ${now.year}';
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
                Text('📊 الإحصائيات', style: TextStyle(color: AppColors.textGold, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('تحليل شامل ومتقدم', style: TextStyle(color: AppColors.textGold.withOpacity(0.7), fontSize: 14)),
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
            leading: Icon(Icons.account_balance_wallet, color: AppColors.primaryGold),
            title: Text('رأس المال', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/capital');
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
        ],
      ),
    );
  }

  // ========== Yearly Analysis - التحليل السنوي الشامل ==========
  Widget _buildYearlyAnalysis() {
    final monthlyData = (_statistics['monthlyData'] as List?) ?? [];
    
    // حساب إحصائيات السنة
    double yearlyRevenue = 0;
    double yearlyCost = 0;
    int yearlyOrders = 0;
    
    for (var data in monthlyData) {
      yearlyRevenue += ((data['total_revenue'] ?? 0) as num).toDouble();
      yearlyCost += ((data['total_cost'] ?? 0) as num).toDouble();
      yearlyOrders += ((data['total_orders'] ?? 0) as num).toInt();
    }
    
    final yearlyProfit = yearlyRevenue - yearlyCost;
    final yearlyMargin = yearlyRevenue > 0 ? ((yearlyProfit / yearlyRevenue) * 100) : 0.0;
    final avgOrderValue = yearlyOrders > 0 ? yearlyRevenue / yearlyOrders : 0.0;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 1400),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade900.withOpacity(0.3),
              Colors.blue.shade900.withOpacity(0.2),
              AppColors.charcoal.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            width: 2,
            color: AppColors.primaryGold.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text('📈', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌟 التحليل السنوي الشامل',
                        style: TextStyle(
                          color: AppColors.textGold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'نظرة عامة على أداء العام الحالي',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // الصف الأول من البطاقات
            Row(
              children: [
                Expanded(
                  child: _buildYearlyCard(
                    'إجمالي المبيعات',
                    '${_formatCurrency(yearlyRevenue)} د.ع',
                    Icons.monetization_on,
                    Colors.green,
                    '💰',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildYearlyCard(
                    'إجمالي الطلبات',
                    '$yearlyOrders طلب',
                    Icons.shopping_cart,
                    Colors.blue,
                    '📦',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // الصف الثاني
            Row(
              children: [
                Expanded(
                  child: _buildYearlyCard(
                    'صافي الأرباح',
                    '${_formatCurrency(yearlyProfit)} د.ع',
                    Icons.trending_up,
                    Colors.purple,
                    '📈',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildYearlyCard(
                    'متوسط قيمة الطلب',
                    '${_formatCurrency(avgOrderValue)} د.ع',
                    Icons.analytics,
                    Colors.orange,
                    '💎',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // هامش الربح السنوي
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    yearlyMargin >= 30 ? Colors.green.withOpacity(0.2) :
                    yearlyMargin >= 20 ? Colors.blue.withOpacity(0.2) :
                    Colors.orange.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: yearlyMargin >= 30 ? Colors.green :
                         yearlyMargin >= 20 ? Colors.blue : Colors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    yearlyMargin >= 30 ? Icons.sentiment_very_satisfied :
                    yearlyMargin >= 20 ? Icons.sentiment_satisfied :
                    Icons.sentiment_neutral,
                    color: yearlyMargin >= 30 ? Colors.green :
                           yearlyMargin >= 20 ? Colors.blue : Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هامش الربح السنوي',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${yearlyMargin.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: yearlyMargin >= 30 ? Colors.green :
                                   yearlyMargin >= 20 ? Colors.blue : Colors.orange,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (yearlyMargin >= 30 ? Colors.green :
                             yearlyMargin >= 20 ? Colors.blue : Colors.orange).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      yearlyMargin >= 30 ? 'ممتاز 🎉' :
                      yearlyMargin >= 20 ? 'جيد جداً 👍' :
                      'مقبول ⚠️',
                      style: TextStyle(
                        color: yearlyMargin >= 30 ? Colors.green :
                               yearlyMargin >= 20 ? Colors.blue : Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildYearlyCard(String label, String value, IconData icon, Color color, String emoji) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ========== Export Section - قسم التصدير ==========
  Widget _buildExportSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 1600),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.glassBlack.withOpacity(0.6),
              AppColors.charcoal.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGold.withOpacity(0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: AppColors.primaryGold, size: 28),
                const SizedBox(width: 12),
                Text(
                  '📥 تصدير التقرير الإحصائي',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'احفظ التقرير الشامل بصيغة PDF أو Excel مع جميع الرسوم البيانية',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    'PDF',
                    Icons.picture_as_pdf,
                    Colors.red,
                    _exportToPDF,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'Excel',
                    Icons.table_chart,
                    Colors.green,
                    _exportToExcel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportButton(
                    'HTML',
                    Icons.web,
                    Colors.blue,
                    _exportToHTML,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5), width: 2),
        ),
        elevation: 0,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ========== Export Functions ==========
  Future<void> _exportToPDF() async {
    try {
      _showMessage('جاري إنشاء ملف PDF...', isError: false);
      
      // تحميل خط عربي
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();
      
      final pdf = pw.Document();
      final now = DateTime.now();
      final monthName = _getCurrentMonthName();

      final totalOrders = (_statistics['totalOrders'] ?? 0) as int;
      final totalRevenue = ((_statistics['totalRevenue'] ?? 0) as num).toDouble();
      final totalCosts = ((_statistics['totalCosts'] ?? 0) as num).toDouble();
      final totalProfit = totalRevenue - totalCosts;
      final profitMargin = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100) : 0.0;
      final paymentMethods = (_statistics['paymentMethods'] as List?) ?? [];
      final topProducts = (_statistics['topProducts'] as List?) ?? [];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicFontBold,
          ),
          build: (context) => [
            // العنوان
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'تقرير الإحصائيات الشامل',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'الفترة: $monthName',
                    style: pw.TextStyle(fontSize: 14, font: arabicFont),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700, font: arabicFont),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),
            
            // الملخص
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'الملخص التنفيذي',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
              },
              children: [
                _buildPDFTableRow('إجمالي الطلبات', '$totalOrders طلب', arabicFont, arabicFontBold, isHeader: true),
                _buildPDFTableRow('إجمالي المبيعات', '${_formatCurrency(totalRevenue)} د.ع', arabicFont, arabicFontBold),
                _buildPDFTableRow('إجمالي التكاليف', '${_formatCurrency(totalCosts)} د.ع', arabicFont, arabicFontBold),
                _buildPDFTableRow('صافي الأرباح', '${_formatCurrency(totalProfit)} د.ع', arabicFont, arabicFontBold),
                _buildPDFTableRow('هامش الربح', '${profitMargin.toStringAsFixed(2)}%', arabicFont, arabicFontBold),
              ],
            ),
            
            // طرق الدفع
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'طرق الدفع',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'المبلغ (د.ع)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'عدد الطلبات',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'طريقة الدفع',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                ...paymentMethods.map((method) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          _formatCurrency((method['total'] as num).toDouble()),
                          style: pw.TextStyle(font: arabicFont),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${method['count']}',
                          style: pw.TextStyle(font: arabicFont),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          method['method'] ?? '',
                          style: pw.TextStyle(font: arabicFont),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            // أفضل المنتجات
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'أفضل المنتجات',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'الإيرادات (د.ع)',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'عدد المبيعات',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'المنتج',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: arabicFontBold),
                        textDirection: pw.TextDirection.rtl,
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                ...topProducts.take(10).map((product) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          _formatCurrency((product['total_revenue'] as num).toDouble()),
                          style: pw.TextStyle(font: arabicFont),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${product['count']}',
                          style: pw.TextStyle(font: arabicFont),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          product['product_name'] ?? '',
                          style: pw.TextStyle(font: arabicFont),
                          textDirection: pw.TextDirection.rtl,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            // التذييل
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'تم إنشاء هذا التقرير بواسطة نظام إدارة الطيف',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600, font: arabicFont),
                    textDirection: pw.TextDirection.rtl,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '© ${now.year} جميع الحقوق محفوظة',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500, font: arabicFont),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      final directory = await getApplicationDocumentsPath();
      await Directory(directory).create(recursive: true);
      final fileName = 'Statistics_Report_${DateFormat('yyyy-MM-dd_HHmmss').format(now)}.pdf';
      final filePath = '$directory\\$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      
      _showMessage('✅ تم حفظ الملف: $fileName', isError: false);
      
      // فتح الملف
      if (await file.exists()) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      }
    } catch (e) {
      print('❌ خطأ في تصدير PDF: $e');
      _showMessage('خطأ في إنشاء ملف PDF', isError: true);
    }
  }

  pw.TableRow _buildPDFTableRow(String label, String value, pw.Font font, pw.Font fontBold, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader ? const pw.BoxDecoration(color: PdfColors.grey200) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              font: isHeader ? fontBold : font,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              font: isHeader ? fontBold : font,
            ),
            textDirection: pw.TextDirection.rtl,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<String> getApplicationDocumentsPath() async {
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      return '$home\\Documents\\my_system_reports';
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/my_system_reports';
  }

  Future<void> _exportToExcel() async {
    try {
      _showMessage('جاري إنشاء ملف Excel...', isError: false);
      
      var excel = excel_lib.Excel.createExcel();
      excel_lib.Sheet sheetObject = excel['الإحصائيات'];
      
      final now = DateTime.now();
      final monthName = _getCurrentMonthName();

      // العنوان
      sheetObject.appendRow([excel_lib.TextCellValue('تقرير الإحصائيات الشامل')]);
      sheetObject.appendRow([excel_lib.TextCellValue('الفترة: $monthName')]);
      sheetObject.appendRow([excel_lib.TextCellValue('تاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}')]);
      sheetObject.appendRow([excel_lib.TextCellValue('')]);

      // الملخص
      final totalOrders = (_statistics['totalOrders'] ?? 0) as int;
      final totalRevenue = ((_statistics['totalRevenue'] ?? 0) as num).toDouble();
      final totalCosts = ((_statistics['totalCosts'] ?? 0) as num).toDouble();
      final totalProfit = totalRevenue - totalCosts;
      final profitMargin = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100) : 0.0;

      sheetObject.appendRow([excel_lib.TextCellValue('الملخص التنفيذي')]);
      sheetObject.appendRow([excel_lib.TextCellValue('البيان'), excel_lib.TextCellValue('القيمة')]);
      sheetObject.appendRow([excel_lib.TextCellValue('إجمالي الطلبات'), excel_lib.IntCellValue(totalOrders)]);
      sheetObject.appendRow([excel_lib.TextCellValue('إجمالي المبيعات'), excel_lib.DoubleCellValue(totalRevenue)]);
      sheetObject.appendRow([excel_lib.TextCellValue('إجمالي التكاليف'), excel_lib.DoubleCellValue(totalCosts)]);
      sheetObject.appendRow([excel_lib.TextCellValue('صافي الأرباح'), excel_lib.DoubleCellValue(totalProfit)]);
      sheetObject.appendRow([excel_lib.TextCellValue('هامش الربح %'), excel_lib.DoubleCellValue(profitMargin)]);
      sheetObject.appendRow([excel_lib.TextCellValue('')]);

      // طرق الدفع
      sheetObject.appendRow([excel_lib.TextCellValue('طرق الدفع')]);
      sheetObject.appendRow([excel_lib.TextCellValue('الطريقة'), excel_lib.TextCellValue('العدد'), excel_lib.TextCellValue('المبلغ')]);
      final paymentMethods = (_statistics['paymentMethods'] as List?) ?? [];
      for (var method in paymentMethods) {
        sheetObject.appendRow([
          excel_lib.TextCellValue(method['method'] ?? ''),
          excel_lib.IntCellValue(method['count'] ?? 0),
          excel_lib.DoubleCellValue((method['total'] as num).toDouble()),
        ]);
      }
      sheetObject.appendRow([excel_lib.TextCellValue('')]);

      // أفضل المنتجات
      sheetObject.appendRow([excel_lib.TextCellValue('أفضل المنتجات')]);
      sheetObject.appendRow([excel_lib.TextCellValue('المنتج'), excel_lib.TextCellValue('المبيعات'), excel_lib.TextCellValue('الإيرادات')]);
      final topProducts = (_statistics['topProducts'] as List?) ?? [];
      for (var product in topProducts.take(10)) {
        sheetObject.appendRow([
          excel_lib.TextCellValue(product['product_name'] ?? ''),
          excel_lib.IntCellValue(product['count'] ?? 0),
          excel_lib.DoubleCellValue((product['total_revenue'] as num).toDouble()),
        ]);
      }

      final directory = await getApplicationDocumentsPath();
      await Directory(directory).create(recursive: true);
      final fileName = 'تقرير_الإحصائيات_${DateFormat('yyyy-MM-dd_HHmmss').format(now)}.xlsx';
      final filePath = '$directory\\$fileName';
      
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        await File(filePath).writeAsBytes(fileBytes);
        _showMessage('✅ تم حفظ الملف: $fileName', isError: false);
      }
    } catch (e) {
      print('❌ خطأ في تصدير Excel: $e');
      _showMessage('خطأ في إنشاء ملف Excel', isError: true);
    }
  }

  Future<void> _exportToHTML() async {
    try {
      _showMessage('جاري إنشاء ملف HTML...', isError: false);
      
      final now = DateTime.now();
      final monthName = _getCurrentMonthName();
      final totalOrders = (_statistics['totalOrders'] ?? 0) as int;
      final totalRevenue = ((_statistics['totalRevenue'] ?? 0) as num).toDouble();
      final totalCosts = ((_statistics['totalCosts'] ?? 0) as num).toDouble();
      final totalProfit = totalRevenue - totalCosts;
      final profitMargin = totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100) : 0.0;

      final html = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>تقرير الإحصائيات الشامل</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        body { background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); color: #fff; padding: 40px; }
        .container { max-width: 1200px; margin: 0 auto; background: rgba(255,255,255,0.05); border-radius: 20px; padding: 40px; backdrop-filter: blur(10px); }
        h1 { color: #ffd700; font-size: 36px; margin-bottom: 10px; text-align: center; }
        .subtitle { color: #aaa; text-align: center; margin-bottom: 30px; }
        .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 30px 0; }
        .card { background: linear-gradient(135deg, rgba(255,215,0,0.1), rgba(255,215,0,0.05)); border: 2px solid rgba(255,215,0,0.3); border-radius: 15px; padding: 25px; text-align: center; }
        .card-icon { font-size: 48px; margin-bottom: 15px; }
        .card-label { color: #aaa; font-size: 14px; margin-bottom: 8px; }
        .card-value { color: #ffd700; font-size: 28px; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 30px 0; background: rgba(255,255,255,0.03); border-radius: 10px; overflow: hidden; }
        th { background: rgba(255,215,0,0.2); color: #ffd700; padding: 15px; text-align: right; font-weight: bold; }
        td { padding: 12px 15px; border-bottom: 1px solid rgba(255,255,255,0.1); }
        tr:hover { background: rgba(255,215,0,0.05); }
        .section-title { color: #ffd700; font-size: 24px; margin: 40px 0 20px; padding-bottom: 10px; border-bottom: 2px solid rgba(255,215,0,0.3); }
        .footer { text-align: center; margin-top: 40px; color: #888; font-size: 14px; }
        @media print { body { background: white; color: black; } .container { background: white; } }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 تقرير الإحصائيات الشامل</h1>
        <p class="subtitle">الفترة: $monthName | تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}</p>
        
        <div class="cards">
            <div class="card">
                <div class="card-icon">📦</div>
                <div class="card-label">إجمالي الطلبات</div>
                <div class="card-value">$totalOrders</div>
            </div>
            <div class="card">
                <div class="card-icon">💰</div>
                <div class="card-label">إجمالي المبيعات</div>
                <div class="card-value">${_formatCurrency(totalRevenue)} د.ع</div>
            </div>
            <div class="card">
                <div class="card-icon">💸</div>
                <div class="card-label">إجمالي التكاليف</div>
                <div class="card-value">${_formatCurrency(totalCosts)} د.ع</div>
            </div>
            <div class="card">
                <div class="card-icon">📈</div>
                <div class="card-label">صافي الأرباح</div>
                <div class="card-value">${_formatCurrency(totalProfit)} د.ع</div>
            </div>
            <div class="card">
                <div class="card-icon">💎</div>
                <div class="card-label">هامش الربح</div>
                <div class="card-value">${profitMargin.toStringAsFixed(2)}%</div>
            </div>
        </div>

        <h2 class="section-title">💳 طرق الدفع</h2>
        <table>
            <thead>
                <tr>
                    <th>طريقة الدفع</th>
                    <th>عدد الطلبات</th>
                    <th>المبلغ (د.ع)</th>
                </tr>
            </thead>
            <tbody>
${(_statistics['paymentMethods'] as List?)?.map((method) => '''
                <tr>
                    <td>${method['method']}</td>
                    <td>${method['count']}</td>
                    <td>${_formatCurrency((method['total'] as num).toDouble())}</td>
                </tr>''').join('\n') ?? ''}
            </tbody>
        </table>

        <h2 class="section-title">🏆 أفضل المنتجات</h2>
        <table>
            <thead>
                <tr>
                    <th>المنتج</th>
                    <th>عدد المبيعات</th>
                    <th>الإيرادات (د.ع)</th>
                </tr>
            </thead>
            <tbody>
${(_statistics['topProducts'] as List?)?.take(10).map((product) => '''
                <tr>
                    <td>${product['product_name']}</td>
                    <td>${product['count']}</td>
                    <td>${_formatCurrency((product['total_revenue'] as num).toDouble())}</td>
                </tr>''').join('\n') ?? ''}
            </tbody>
        </table>

        <div class="footer">
            <p>تم إنشاء هذا التقرير بواسطة نظام إدارة الطيف</p>
            <p>© ${now.year} جميع الحقوق محفوظة</p>
        </div>
    </div>
</body>
</html>
''';

      final directory = await getApplicationDocumentsPath();
      await Directory(directory).create(recursive: true);
      final fileName = 'تقرير_الإحصائيات_${DateFormat('yyyy-MM-dd_HHmmss').format(now)}.html';
      final filePath = '$directory\\$fileName';
      
      await File(filePath).writeAsString(html, encoding: utf8);
      _showMessage('✅ تم حفظ الملف: $fileName', isError: false);
      
      // فتح الملف في المتصفح
      if (await File(filePath).exists()) {
        await Process.run('cmd', ['/c', 'start', '', filePath]);
      }
    } catch (e) {
      print('❌ خطأ في تصدير HTML: $e');
      _showMessage('خطأ في إنشاء ملف HTML', isError: true);
    }
  }
}
