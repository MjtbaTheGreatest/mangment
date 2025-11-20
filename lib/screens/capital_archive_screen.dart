import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../styles/app_colors.dart';
import '../services/api_service.dart';

/// صفحة أرشيف السجل المالي
class CapitalArchiveScreen extends StatefulWidget {
  const CapitalArchiveScreen({super.key});

  @override
  State<CapitalArchiveScreen> createState() => _CapitalArchiveScreenState();
}

class _CapitalArchiveScreenState extends State<CapitalArchiveScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _archivedTransactions = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'الكل'; // الكل، إضافة، سحب

  @override
  void initState() {
    super.initState();
    _loadArchivedTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArchivedTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await ApiService.getArchivedCapitalTransactions();
      
      if (result['success'] == true) {
        setState(() {
          _archivedTransactions = List<Map<String, dynamic>>.from(result['transactions'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showMessage('فشل تحميل الأرشيف', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('خطأ في الاتصال', isError: true);
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    var filtered = _archivedTransactions;

    // تطبيق فلتر النوع
    if (_filterType != 'الكل') {
      filtered = filtered.where((t) {
        final type = (t['type'] ?? '').toString().toLowerCase();
        if (_filterType == 'إضافة') {
          return type == 'deposit' || type == 'إضافة';
        } else {
          return type == 'withdraw' || type == 'سحب';
        }
      }).toList();
    }

    // تطبيق البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) {
        final description = (t['description'] ?? '').toString().toLowerCase();
        final createdBy = (t['created_by'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return description.contains(query) || createdBy.contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> _unarchiveTransaction(int transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        'استرجاع من الأرشيف',
        'هل تريد استرجاع هذه العملية من الأرشيف؟',
        Colors.blue,
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ApiService.unarchiveCapitalTransaction(transactionId);
      
      if (result['success'] == true) {
        _showMessage('تم استرجاع العملية بنجاح');
        _loadArchivedTransactions();
      } else {
        _showMessage(result['message'] ?? 'فشل الاسترجاع', isError: true);
      }
    } catch (e) {
      _showMessage('خطأ في الاتصال', isError: true);
    }
  }

  Future<void> _deleteArchivedTransaction(int transactionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmDialog(
        'حذف نهائي',
        'هل تريد حذف هذه العملية نهائياً من الأرشيف؟\n⚠️ لا يمكن التراجع عن هذا الإجراء',
        Colors.red,
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await ApiService.deleteArchivedCapitalTransaction(transactionId);
      
      if (result['success'] == true) {
        _showMessage('تم الحذف بنجاح');
        _loadArchivedTransactions();
      } else {
        _showMessage(result['message'] ?? 'فشل الحذف', isError: true);
      }
    } catch (e) {
      _showMessage('خطأ في الاتصال', isError: true);
    }
  }

  Widget _buildConfirmDialog(String title, String message, Color color) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 28),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: AppColors.textGold, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
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

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(amount);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.pureBlack,
        body: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
                  : _buildArchiveContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.charcoal,
            AppColors.pureBlack,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade700, Colors.amber.shade900],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.inventory_2, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أرشيف السجل المالي',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_archivedTransactions.length} عملية مؤرشفة',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadArchivedTransactions,
              tooltip: 'تحديث',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glassBlack.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            // شريط البحث
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'ابحث في الأرشيف...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.primaryGold),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.glassBlack.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // فلاتر
            Row(
              children: [
                Expanded(child: _buildFilterChip('الكل')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('إضافة')),
                const SizedBox(width: 8),
                Expanded(child: _buildFilterChip('سحب')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    MaterialColor materialColor;
    IconData icon;

    if (label == 'إضافة') {
      materialColor = Colors.green;
      icon = Icons.add_circle;
    } else if (label == 'سحب') {
      materialColor = Colors.red;
      icon = Icons.remove_circle;
    } else {
      materialColor = Colors.blue;
      icon = Icons.all_inclusive;
    }

    return InkWell(
      onTap: () => setState(() => _filterType = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [materialColor.shade700, materialColor.shade900])
              : null,
          color: isSelected ? null : AppColors.glassBlack.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? materialColor : AppColors.textSecondary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : materialColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveContent() {
    final filteredTransactions = _getFilteredTransactions();

    if (filteredTransactions.isEmpty) {
      return Center(
        child: FadeIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'لا توجد عمليات مؤرشفة',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          duration: Duration(milliseconds: 300 + (index * 50)),
          child: _buildArchivedTransactionCard(filteredTransactions[index]),
        );
      },
    );
  }

  Widget _buildArchivedTransactionCard(Map<String, dynamic> transaction) {
    final amount = ((transaction['amount'] ?? 0) as num).toDouble();
    final type = (transaction['type'] ?? '').toString();
    final isDeposit = type.toLowerCase() == 'deposit' || type == 'إضافة';
    final description = (transaction['description'] ?? '').toString();
    final createdBy = (transaction['created_by'] ?? '').toString();
    final createdAt = transaction['created_at'];
    final archivedAt = transaction['archived_at'];
    final transactionId = transaction['id'] as int?;

    return InkWell(
      onTap: () => _showArchivedTransactionDetails(transaction),
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.glassBlack.withOpacity(0.5),
            AppColors.charcoal.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeposit ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDeposit
                    ? [Colors.green.shade800.withOpacity(0.3), Colors.green.shade900.withOpacity(0.3)]
                    : [Colors.red.shade800.withOpacity(0.3), Colors.red.shade900.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDeposit ? Icons.add_circle : Icons.remove_circle,
                    color: isDeposit ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDeposit ? 'إضافة رأس مال' : 'سحب من رأس المال',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_formatCurrency(amount)} د.ع',
                  style: TextStyle(
                    color: isDeposit ? Colors.green.shade200 : Colors.red.shade200,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(Icons.person, 'المستخدم', createdBy),
                    ),
                    Expanded(
                      child: _buildInfoItem(Icons.calendar_today, 'التاريخ', _formatDate(createdAt)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(Icons.archive, 'تاريخ الأرشفة', _formatDate(archivedAt)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.glassBlack.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: transactionId != null ? () => _unarchiveTransaction(transactionId) : null,
                    icon: const Icon(Icons.unarchive, size: 18),
                    label: const Text('استرجاع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: transactionId != null ? () => _deleteArchivedTransaction(transactionId) : null,
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('حذف نهائي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // عرض تفاصيل العملية المؤرشفة بالكامل
  void _showArchivedTransactionDetails(Map<String, dynamic> transaction) {
    final amount = ((transaction['amount'] ?? 0) as num).toDouble();
    final type = (transaction['type'] ?? '').toString();
    final isDeposit = type.toLowerCase() == 'deposit' || type == 'إضافة';
    final description = (transaction['description'] ?? '').toString();
    final createdBy = (transaction['created_by'] ?? '').toString();
    final createdAt = transaction['created_at'];
    final archivedAt = transaction['archived_at'];
    
    // تفاصيل الطلب (إن وجدت)
    final orderId = transaction['order_id'];
    final productName = transaction['product_name'];
    final customerName = transaction['customer_name'];
    final customerPhone = transaction['customer_phone'];
    final sellPrice = transaction['sell_price'];

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDeposit
                    ? [Colors.green.shade800, Colors.green.shade900]
                    : [Colors.red.shade800, Colors.red.shade900],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isDeposit ? Colors.green : Colors.red).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDeposit ? Icons.add_circle : Icons.remove_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'معلومات العملية',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2, color: Colors.amber.shade200, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'عملية مؤرشفة',
                                    style: TextStyle(
                                      color: Colors.amber.shade200,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // المبلغ والنوع
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isDeposit ? 'إضافة رأس مال' : 'سحب من رأس المال',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_formatCurrency(amount)} د.ع',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // الوصف
                        if (description.isNotEmpty) ...[
                          _buildDetailRow(
                            Icons.description,
                            'الوصف',
                            description,
                          ),
                          const SizedBox(height: 16),
                        ],
                        // المستخدم
                        _buildDetailRow(
                          Icons.person,
                          'من قام بتسجيل العملية',
                          createdBy,
                        ),
                        const SizedBox(height: 16),
                        // التوقيت الأصلي
                        _buildDetailRow(
                          Icons.access_time,
                          'التوقيت بالضبط',
                          _formatDateTime(createdAt),
                        ),
                        const SizedBox(height: 16),
                        // تاريخ الأرشفة
                        _buildDetailRow(
                          Icons.archive,
                          'تاريخ الأرشفة',
                          _formatDateTime(archivedAt),
                        ),
                        // تفاصيل الطلب (إن وجدت)
                        if (orderId != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_bag, color: AppColors.primaryGold, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تفاصيل الطلب',
                                      style: TextStyle(
                                        color: AppColors.primaryGold,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(Icons.tag, 'رقم الطلب', '#$orderId'),
                                if (productName != null) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow(Icons.inventory, 'اسم المنتج', productName.toString()),
                                ],
                                if (customerName != null) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow(Icons.person_outline, 'اسم الزبون', customerName.toString()),
                                ],
                                if (customerPhone != null) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow(Icons.phone, 'رقم الهاتف', customerPhone.toString()),
                                ],
                                if (sellPrice != null) ...[
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    Icons.attach_money,
                                    'سعر البيع',
                                    '${_formatCurrency((sellPrice as num).toDouble())} د.ع',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Footer Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (transaction['id'] != null) {
                              _unarchiveTransaction(transaction['id'] as int);
                            }
                          },
                          icon: const Icon(Icons.unarchive, size: 18),
                          label: const Text('استرجاع من الأرشيف'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إغلاق'),
                      ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryGold.withOpacity(0.9), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final arabicDays = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      final arabicMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
      
      final dayName = arabicDays[date.weekday % 7];
      final monthName = arabicMonths[date.month - 1];
      
      // تحويل إلى 12 ساعة
      final hour12 = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final period = date.hour >= 12 ? 'مساءً' : 'صباحاً';
      
      return '$dayName، ${date.day} $monthName ${date.year}\n⏰ ${hour12.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGold.withOpacity(0.7), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
