import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

/// صفحة إدارة طرق الدفع
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:53366/api/payment-methods'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _paymentMethods = List<Map<String, dynamic>>.from(data['methods']);
          _isLoading = false;
        });
      } else {
        throw Exception('فشل تحميل البيانات');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('خطأ في تحميل البيانات: $e');
      }
    }
  }

  Future<void> _addPaymentMethod(String name) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:53366/api/payment-methods'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200) {
        await _loadPaymentMethods();
        if (mounted) {
          _showSuccess('تمت الإضافة بنجاح');
        }
      } else {
        throw Exception('فشل الإضافة');
      }
    } catch (e) {
      if (mounted) {
        _showError('خطأ في الإضافة: $e');
      }
    }
  }

  Future<void> _updatePaymentMethod(int id, String name) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:53366/api/payment-methods/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (response.statusCode == 200) {
        await _loadPaymentMethods();
        if (mounted) {
          _showSuccess('تم التعديل بنجاح');
        }
      } else {
        throw Exception('فشل التعديل');
      }
    } catch (e) {
      if (mounted) {
        _showError('خطأ في التعديل: $e');
      }
    }
  }

  Future<void> _deletePaymentMethod(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
              const SizedBox(width: 12),
              Text(
                'تأكيد الحذف',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textGold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف طريقة الدفع "$name"؟\n\nسيتم حذفها من النظام بالكامل.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'إلغاء',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'حذف',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final response = await http.delete(
          Uri.parse('http://localhost:53366/api/payment-methods/$id'),
        );

        if (response.statusCode == 200) {
          await _loadPaymentMethods();
          if (mounted) {
            _showSuccess('تم الحذف بنجاح');
          }
        } else {
          throw Exception('فشل الحذف');
        }
      } catch (e) {
        if (mounted) {
          _showError('خطأ في الحذف: $e');
        }
      }
    }
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.primaryGold, size: 28),
              const SizedBox(width: 12),
              Text(
                'إضافة طريقة دفع',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textGold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'اسم طريقة الدفع',
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  hintText: 'مثال: نقد، زين كاش، آسيا حواله',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppColors.darkGray.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _addPaymentMethod(name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'إضافة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.charcoal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(int id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.edit, color: AppColors.info, size: 28),
              const SizedBox(width: 12),
              Text(
                'تعديل طريقة الدفع',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textGold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'اسم طريقة الدفع',
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.darkGray.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGold.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
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
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                  _updatePaymentMethod(id, name);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'حفظ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primaryGold),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إدارة طرق الدفع',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textGold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primaryGold),
              onPressed: _loadPaymentMethods,
              tooltip: 'تحديث',
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primaryGold,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جاري التحميل...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header Stats
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade700.withOpacity(0.3),
                                Colors.teal.shade700.withOpacity(0.3),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.primaryGold.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '💳',
                                  style: TextStyle(fontSize: 32),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'عدد طرق الدفع',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_paymentMethods.length}',
                                      style: AppTextStyles.displayMedium.copyWith(
                                        color: AppColors.textGold,
                                        fontSize: 32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // List
                      Expanded(
                        child: _paymentMethods.isEmpty
                            ? Center(
                                child: FadeIn(
                                  duration: const Duration(milliseconds: 600),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.payment,
                                        size: 80,
                                        color: AppColors.textSecondary.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'لا توجد طرق دفع',
                                        style: AppTextStyles.headlineSmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'اضغط على زر + لإضافة طريقة دفع جديدة',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _paymentMethods.length,
                                itemBuilder: (context, index) {
                                  final method = _paymentMethods[index];
                                  return FadeInUp(
                                    duration: const Duration(milliseconds: 400),
                                    delay: Duration(milliseconds: index * 100),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade700.withOpacity(0.15),
                                            Colors.teal.shade700.withOpacity(0.15),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.primaryGold.withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        leading: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryGold.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.payments,
                                            color: AppColors.primaryGold,
                                            size: 24,
                                          ),
                                        ),
                                        title: Text(
                                          method['name'],
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'معرف: ${method['id']}',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: AppColors.info,
                                                size: 22,
                                              ),
                                              onPressed: () => _showEditDialog(
                                                method['id'],
                                                method['name'],
                                              ),
                                              tooltip: 'تعديل',
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: AppColors.error,
                                                size: 22,
                                              ),
                                              onPressed: () => _deletePaymentMethod(
                                                method['id'],
                                                method['name'],
                                              ),
                                              tooltip: 'حذف',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ),
        floatingActionButton: FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 800),
          child: FloatingActionButton.extended(
            onPressed: _showAddDialog,
            backgroundColor: AppColors.primaryGold,
            icon: Icon(Icons.add, color: AppColors.charcoal),
            label: Text(
              'إضافة طريقة دفع',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.charcoal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
