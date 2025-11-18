import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// صفحة إدارة الاشتراكات
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  List<Map<String, dynamic>> _subscriptions = [];
  String? _userRole;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadSubscriptions();
  }

  Future<void> _loadUserRole() async {
    final role = await ApiService.getRole();
    setState(() => _userRole = role);
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiService.getSubscriptions();
      
      if (response['success'] == true) {
        final subscriptions = response['subscriptions'] as List;
        
        // تحويل البيانات وتحميل المستخدمين لكل اشتراك
        final List<Map<String, dynamic>> loadedSubscriptions = [];
        
        for (var sub in subscriptions) {
          try {
            // تحميل المستخدمين لهذا الاشتراك
            final usersResponse = await ApiService.getSubscriptionUsers(sub['id']);
            final users = usersResponse['success'] == true 
                ? (usersResponse['users'] as List).map((u) {
                    try {
                      return {
                        'id': u['id'],
                        'customerName': u['customerName'] ?? '',
                        'profileName': u['profileName'] ?? '',
                        'amount': u['amount'] ?? 0.0,
                        'startDate': u['startDate'] != null ? DateTime.parse(u['startDate']) : DateTime.now(),
                        'endDate': u['endDate'] != null ? DateTime.parse(u['endDate']) : DateTime.now().add(Duration(days: 30)),
                        'addedBy': u['addedBy'] ?? 'مجهول',
                      };
                    } catch (e) {
                      print('خطأ في تحويل بيانات المستخدم: $e');
                      return null;
                    }
                  }).where((u) => u != null).cast<Map<String, dynamic>>().toList()
                : [];
            
            loadedSubscriptions.add({
              'id': sub['id'],
              'serviceName': sub['serviceName'] ?? 'غير محدد',
              'accountNumber': sub['accountNumber'],
              'cost': sub['cost'] ?? 0.0,
              'maxUsers': sub['maxUsers'] ?? 0,
              'currentUsers': users.length,
              'startDate': sub['startDate'] != null ? DateTime.parse(sub['startDate']) : DateTime.now(),
              'endDate': sub['endDate'] != null ? DateTime.parse(sub['endDate']) : DateTime.now().add(Duration(days: 30)),
              'email': sub['email'],
              'password': sub['password'],
              'users': users,
            });
          } catch (e) {
            print('خطأ في تحميل اشتراك: $e');
            continue;
          }
        }
        
        setState(() {
          _subscriptions = loadedSubscriptions;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'فشل تحميل الاشتراكات'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('خطأ عام في تحميل الاشتراكات: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getServiceColor(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('netflix') || name.contains('نتفلكس')) {
      return const Color(0xFFE50914); // أحمر Netflix
    } else if (name.contains('shahid') || name.contains('شاهد')) {
      return const Color(0xFF9C27B0); // بنفسجي Shahid
    }
    return const Color(0xFF424242); // رمادي داكن
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
            'إدارة الاشتراكات',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textGold,
            ),
          ),
          centerTitle: true,
          actions: [
            // Add Subscription Icon Button
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.add, color: AppColors.pureBlack, size: 24),
              ),
              onPressed: _showAddSubscriptionDialog,
            ),
            const SizedBox(width: 8),
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
                        CircularProgressIndicator(color: AppColors.primaryGold),
                        const SizedBox(height: 20),
                        Text(
                          'جاري تحميل الاشتراكات...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : _subscriptions.isEmpty
                ? Center(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subscriptions_outlined,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد اشتراكات حالياً',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط على زر + لإضافة اشتراك جديد',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // حساب عدد الأعمدة بناءً على عرض الشاشة
                      int crossAxisCount;
                      double childAspectRatio;
                      
                      if (constraints.maxWidth >= 1400) {
                        crossAxisCount = 4;
                        childAspectRatio = 1.15;
                      } else if (constraints.maxWidth >= 1000) {
                        crossAxisCount = 3;
                        childAspectRatio = 1.1;
                      } else if (constraints.maxWidth >= 700) {
                        crossAxisCount = 2;
                        childAspectRatio = 1.05;
                      } else {
                        crossAxisCount = 1;
                        childAspectRatio = 1.3;
                      }
                      
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _subscriptions.length,
                        itemBuilder: (context, index) {
                          final subscription = _subscriptions[index];
                          return _buildSubscriptionCard(subscription);
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  void _showAddSubscriptionDialog() {
    final serviceNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final costController = TextEditingController();
    final maxUsersController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إضافة اشتراك',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryGold,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGold.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(Icons.add_circle, color: AppColors.charcoal, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'إضافة اشتراك جديد',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.textGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Service Name & Account Number
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: serviceNameController,
                              label: 'اسم الخدمة',
                              icon: Icons.subscriptions,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: accountNumberController,
                              label: 'رقم الحساب (اختياري)',
                              icon: Icons.numbers,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Monthly Cost & Max Users
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: costController,
                              label: 'التكلفة الشهرية (د.ع)',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: maxUsersController,
                              label: 'عدد المستخدمين',
                              icon: Icons.people,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'تاريخ البداية',
                              date: startDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppColors.primaryGold,
                                          surface: AppColors.charcoal,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  startDate = picked;
                                  (context as Element).markNeedsBuild();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(
                              label: 'تاريخ النهاية',
                              date: endDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppColors.primaryGold,
                                          surface: AppColors.charcoal,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  endDate = picked;
                                  (context as Element).markNeedsBuild();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Email & Password
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: emailController,
                              label: 'البريد الإلكتروني',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: passwordController,
                              label: 'كلمة المرور',
                              icon: Icons.lock,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (serviceNameController.text.isEmpty ||
                                costController.text.isEmpty ||
                                maxUsersController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'الرجاء ملء جميع الحقول المطلوبة',
                                    style: AppTextStyles.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            
                            Navigator.pop(context);
                            
                            // Add subscription via API
                            final response = await ApiService.createSubscription(
                              serviceName: serviceNameController.text,
                              accountNumber: accountNumberController.text.trim().isEmpty 
                                  ? null 
                                  : accountNumberController.text.trim(),
                              cost: double.tryParse(costController.text) ?? 0,
                              maxUsers: int.tryParse(maxUsersController.text) ?? 0,
                              startDate: startDate.toIso8601String().split('T')[0],
                              endDate: endDate.toIso8601String().split('T')[0],
                              email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                              password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
                            );
                            
                            if (response['success'] == true) {
                              await _loadSubscriptions();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        TweenAnimationBuilder<double>(
                                          duration: const Duration(milliseconds: 600),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: Icon(Icons.check_circle, color: Colors.white, size: 24),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'تم إضافة الاشتراك بنجاح',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response['message'] ?? 'فشل إضافة الاشتراك'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: const BoxConstraints(minHeight: 50),
                              child: Text(
                                'تسجيل الخدمة',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.pureBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [AppColors.glassWhite, AppColors.glassBlack],
        ),
        border: Border.all(color: AppColors.glassWhite, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primaryGold, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.glassWhite, AppColors.glassBlack],
          ),
          border: Border.all(color: AppColors.glassWhite, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primaryGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    final serviceColor = _getServiceColor(subscription['serviceName']);
    final currentUsers = subscription['currentUsers'] as int;
    final maxUsers = subscription['maxUsers'] as int;
    final progress = maxUsers > 0 ? currentUsers / maxUsers : 0.0;
    
    // تحديد حالة الاشتراك
    final endDate = subscription['endDate'] as DateTime;
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    final isActive = daysLeft > 0;
    
    // الحرف الأول من اسم الخدمة
    final firstLetter = subscription['serviceName'].isNotEmpty 
        ? subscription['serviceName'][0].toUpperCase() 
        : '?';
    
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 250,
          maxWidth: 450,
          minHeight: 200,
          maxHeight: 350,
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showSubscriptionDetails(subscription),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.charcoal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.glassWhite.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // شريط علوي ملون
                  Container(
                    height: 3,
                    color: serviceColor,
                  ),
                  
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            // أيقونة المستخدم في الزاوية
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 12,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                            
                            SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                              // الرأس: اللوجو + الاسم + الحالة
                              Row(
                                children: [
                                  // لوجو الخدمة
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: serviceColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        firstLetter,
                                        style: AppTextStyles.headlineMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // اسم الخدمة ورقم الحساب
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            subscription['serviceName'],
                                            style: AppTextStyles.bodyLarge.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (subscription['accountNumber'] != null && 
                                            subscription['accountNumber'].toString().isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Flexible(
                                            child: Text(
                                              'حساب رقم ${subscription['accountNumber']}',
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 10),
                              
                              // بطاقة الحالة
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive 
                                      ? AppColors.success.withOpacity(0.2)
                                      : AppColors.error.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isActive ? AppColors.success : AppColors.error,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isActive ? 'نشط' : 'منتهي',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isActive ? AppColors.success : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Email & Password
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactInfo(
                                      icon: Icons.email,
                                      text: subscription['email'],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactInfo(
                                      icon: Icons.lock,
                                      text: subscription['password'],
                                      isPassword: true,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // شبكة المعلومات
                              Row(
                                children: [
                                  // المشتركين
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.glassBlack,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$currentUsers/$maxUsers',
                                            style: AppTextStyles.headlineSmall.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'المشتركين',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  // السعر
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.glassBlack,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            subscription['cost'].toStringAsFixed(0),
                                            style: AppTextStyles.headlineSmall.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'د.ع / شهر',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // شريط التقدم
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'الاستخدام',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    tween: Tween<double>(begin: 0, end: progress),
                                    builder: (context, value, child) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: value,
                                          backgroundColor: AppColors.glassBlack,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            value >= 1.0 ? AppColors.error : AppColors.success,
                                          ),
                                          minHeight: 6,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // أزرار التحكم
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showEditSubscriptionDialog(subscription),
                                      icon: Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                                      label: Text(
                                        'تعديل',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        side: BorderSide(
                                          color: AppColors.glassWhite.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  
                                  OutlinedButton(
                                    onPressed: () => _deleteSubscription(subscription),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.all(8),
                                      side: BorderSide(
                                        color: AppColors.error.withOpacity(0.5),
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
    
  }
  
  void _deleteSubscription(Map<String, dynamic> subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.error, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 32),
            const SizedBox(width: 12),
            Text(
              'حذف الاشتراك',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف اشتراك ${subscription['serviceName']}؟',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
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
            onPressed: () async {
              Navigator.pop(context);
              
              // تحديث فوري للواجهة
              setState(() {
                _subscriptions.removeWhere((s) => s['id'] == subscription['id']);
              });
              
              // إرسال الطلب للسيرفر بالخلفية
              ApiService.deleteSubscription(subscription['id']).then((response) {
                if (response['success'] != true) {
                  // إذا فشل، استعادة البيانات من السيرفر
                  _loadSubscriptions();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message'] ?? 'فشل حذف الاشتراك'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              });
              
              // إشعار النجاح فوراً
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Icon(Icons.check_circle, color: Colors.white),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تم حذف الاشتراك بنجاح',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
  
  Widget _buildCompactInfo({
    required IconData icon,
    required String text,
    bool isPassword = false,
  }) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        
        // إظهار إشعار منبثق جميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'تم النسخ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassWhite.withOpacity(0.2), width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryGold, size: 12),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isPassword ? '••••' : text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.copy, color: AppColors.primaryGold.withOpacity(0.5), size: 10),
          ],
        ),
      ),
    );
  }
  
  void _showEditSubscriptionDialog(Map<String, dynamic> subscription) {
    final serviceNameController = TextEditingController(text: subscription['serviceName']);
    final accountNumberController = TextEditingController(text: subscription['accountNumber'] ?? '');
    final costController = TextEditingController(text: subscription['cost'].toString());
    final maxUsersController = TextEditingController(text: subscription['maxUsers'].toString());
    final emailController = TextEditingController(text: subscription['email']);
    final passwordController = TextEditingController(text: subscription['password']);
    
    DateTime startDate = subscription['startDate'];
    DateTime endDate = subscription['endDate'];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'تعديل الاشتراك',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.info,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.info, AppColors.info.withOpacity(0.7)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit, color: AppColors.charcoal, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'تعديل الاشتراك',
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: AppColors.primaryGold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Service Name & Account Number
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: serviceNameController,
                              label: 'اسم الخدمة',
                              icon: Icons.subscriptions,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: accountNumberController,
                              label: 'رقم الحساب (اختياري)',
                              icon: Icons.numbers,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Monthly Cost & Max Users
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: costController,
                              label: 'التكلفة الشهرية (د.ع)',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: maxUsersController,
                              label: 'عدد المستخدمين',
                              icon: Icons.people,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'تاريخ البداية',
                              date: startDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppColors.primaryGold,
                                          surface: AppColors.charcoal,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  startDate = picked;
                                  (context as Element).markNeedsBuild();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(
                              label: 'تاريخ النهاية',
                              date: endDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppColors.primaryGold,
                                          surface: AppColors.charcoal,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  endDate = picked;
                                  (context as Element).markNeedsBuild();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Email & Password
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: emailController,
                              label: 'البريد الإلكتروني',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: passwordController,
                              label: 'كلمة المرور',
                              icon: Icons.lock,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (serviceNameController.text.isEmpty ||
                                costController.text.isEmpty ||
                                maxUsersController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'الرجاء ملء جميع الحقول المطلوبة',
                                    style: AppTextStyles.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            
                            Navigator.pop(context);
                            
                            // تحديث الاشتراك عبر API
                            final response = await ApiService.updateSubscription(
                              subscriptionId: subscription['id'],
                              serviceName: serviceNameController.text,
                              accountNumber: accountNumberController.text.trim().isEmpty 
                                  ? null 
                                  : accountNumberController.text.trim(),
                              cost: double.tryParse(costController.text) ?? 0,
                              maxUsers: int.tryParse(maxUsersController.text) ?? 0,
                              startDate: startDate.toIso8601String().split('T')[0],
                              endDate: endDate.toIso8601String().split('T')[0],
                              email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                              password: passwordController.text.trim().isEmpty ? null : passwordController.text.trim(),
                            );
                            
                            if (response['success'] == true) {
                              await _loadSubscriptions();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text(
                                          'تم تحديث الاشتراك بنجاح',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response['message'] ?? 'فشل تحديث الاشتراك'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: AppColors.info,
                          ),
                          child: Text(
                            'حفظ التعديلات',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubscriptionDetails(Map<String, dynamic> subscription) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'تفاصيل الاشتراك',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: _SubscriptionDetailsDialog(
              subscription: subscription,
              userRole: _userRole,
              onAddUser: () {
                Navigator.pop(context);
                _showAddUserDialog(subscription);
              },
              onUpdate: () async {
                await _loadSubscriptions();
                // إعادة فتح نافذة التفاصيل بالبيانات المحدثة
                final updatedSub = _subscriptions.firstWhere(
                  (s) => s['id'] == subscription['id'],
                  orElse: () => subscription,
                );
                Navigator.pop(context);
                _showSubscriptionDetails(updatedSub);
              },
            ),
          ),
        );
      },
    );
  }

  void _showAddUserDialog(Map<String, dynamic> subscription) {
    final customerNameController = TextEditingController();
    final profileNameController = TextEditingController();
    final amountController = TextEditingController();
    
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 30));

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إضافة مستخدم',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.info, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.info,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.person_add, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إضافة مستخدم',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.textGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  subscription['serviceName'],
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      _buildTextField(
                        controller: customerNameController,
                        label: 'اسم العميل',
                        icon: Icons.person,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: profileNameController,
                        label: 'اسم البروفايل',
                        icon: Icons.badge,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: amountController,
                        label: 'المبلغ المدفوع (د.ع)',
                        icon: Icons.payments,
                        keyboardType: TextInputType.number,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'من',
                              date: startDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppColors.primaryGold,
                                          surface: AppColors.charcoal,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  startDate = picked;
                                  (context as Element).markNeedsBuild();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(
                              label: 'إلى',
                              date: endDate,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: AppColors.primaryGold,
                                          surface: AppColors.charcoal,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  endDate = picked;
                                  (context as Element).markNeedsBuild();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (customerNameController.text.isEmpty ||
                                profileNameController.text.isEmpty ||
                                amountController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'الرجاء ملء جميع الحقول',
                                    style: AppTextStyles.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            
                            Navigator.pop(context);
                            
                            // تحديث فوري للواجهة
                            final newUser = {
                              'id': DateTime.now().millisecondsSinceEpoch, // معرف مؤقت
                              'customerName': customerNameController.text,
                              'profileName': profileNameController.text,
                              'amount': double.tryParse(amountController.text) ?? 0,
                              'startDate': startDate,
                              'endDate': endDate,
                            };
                            
                            setState(() {
                              final subIndex = _subscriptions.indexWhere((s) => s['id'] == subscription['id']);
                              if (subIndex != -1) {
                                if (_subscriptions[subIndex]['users'] == null) {
                                  _subscriptions[subIndex]['users'] = [];
                                }
                                _subscriptions[subIndex]['users'].add(newUser);
                              }
                            });
                            
                            // إرسال للسيرفر بالخلفية
                            ApiService.addSubscriptionUser(
                              subscriptionId: subscription['id'],
                              customerName: customerNameController.text,
                              profileName: profileNameController.text,
                              amount: double.tryParse(amountController.text) ?? 0,
                              startDate: startDate.toIso8601String().split('T')[0],
                              endDate: endDate.toIso8601String().split('T')[0],
                            ).then((response) {
                              if (response['success'] == true) {
                                // تحديث البيانات بالمعرف الحقيقي من السيرفر
                                _loadSubscriptions();
                              } else {
                                // إذا فشل، إزالة المستخدم واستعادة البيانات
                                setState(() {
                                  final subIndex = _subscriptions.indexWhere((s) => s['id'] == subscription['id']);
                                  if (subIndex != -1) {
                                    _subscriptions[subIndex]['users']?.removeWhere((u) => u['id'] == newUser['id']);
                                  }
                                });
                                _loadSubscriptions();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(response['message'] ?? 'فشل إضافة المستخدم'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            });
                            
                            // إعادة فتح نافذة التفاصيل فوراً
                            final updatedSub = _subscriptions.firstWhere(
                              (s) => s['id'] == subscription['id'],
                              orElse: () => subscription,
                            );
                            _showSubscriptionDetails(updatedSub);
                            
                            // إشعار النجاح فوراً
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text(
                                        'تم إضافة المستخدم بنجاح',
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: AppColors.info,
                          ),
                          child: Text(
                            'إضافة',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.charcoal,
              AppColors.pureBlack,
            ],
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
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
                          child: Icon(
                            Icons.subscriptions,
                            size: 40,
                            color: AppColors.pureBlack,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'إدارة الاشتراكات',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.textGold,
                          ),
                        ),
                        Text(
                          _userRole == 'admin' ? 'مدير النظام' : 'موظف',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: AppColors.glassWhite, thickness: 1),
                  
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildDrawerItem(
                          icon: Icons.home,
                          title: 'الصفحة الرئيسية',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushReplacementNamed(context, '/');
                          },
                        ),
                        
                        Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                        
                        _buildDrawerItem(
                          icon: Icons.subscriptions,
                          title: 'إدارة الاشتراكات',
                          onTap: () => Navigator.pop(context),
                        ),
                        _buildDrawerItem(
                          icon: Icons.shopping_bag,
                          title: 'إدارة الطلبات',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/orders');
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.archive,
                          title: 'الأرشيف',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/archive');
                          },
                        ),
                        
                        if (_userRole == 'admin') ...[
                          Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'إدارة المدير',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildDrawerItem(
                            icon: Icons.bar_chart,
                            title: 'الإحصائيات',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/statistics');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.account_balance_wallet,
                            title: 'رأس المال',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/capital');
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.people,
                            title: 'إدارة الموظفين',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/employees');
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        Divider(color: AppColors.glassWhite, thickness: 1),
                        
                        _buildDrawerItem(
                          icon: Icons.logout,
                          title: 'تسجيل الخروج',
                          onTap: () async {
                            await ApiService.logout();
                            if (context.mounted) {
                              Navigator.of(context).pushReplacementNamed('/login');
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGold),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      hoverColor: AppColors.glassWhite,
    );
  }
}

// Subscription Details Dialog Widget
class _SubscriptionDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> subscription;
  final String? userRole;
  final VoidCallback onAddUser;
  final Future<void> Function() onUpdate;

  const _SubscriptionDetailsDialog({
    required this.subscription,
    required this.userRole,
    required this.onAddUser,
    required this.onUpdate,
  });

  @override
  State<_SubscriptionDetailsDialog> createState() => _SubscriptionDetailsDialogState();
}

class _SubscriptionDetailsDialogState extends State<_SubscriptionDetailsDialog> {
  
  void _showReceiptDialog(Map<String, dynamic> user) {
    final endDate = user['endDate'] as DateTime;
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                AppColors.charcoal,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primaryGold,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGold.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header simplified - just close button
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.primaryGold, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        children: [
                          // Greeting Message
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryGold.withOpacity(0.2),
                                  AppColors.primaryGold.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primaryGold.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'عزيزنا العميل',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user['customerName'],
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.textGold,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 19,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Thank You Message
                          Text(
                            '🌟 شكراً لاختيارك الطيف ستور 🌟',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Subscription Info Card
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.glassBlack,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryGold.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildReceiptRow(
                                  icon: Icons.tv,
                                  label: 'الخدمة',
                                  value: widget.subscription['serviceName'],
                                  valueColor: AppColors.textGold,
                                ),
                                const Divider(color: Colors.white24, height: 12),
                                _buildReceiptRow(
                                  icon: Icons.person,
                                  label: 'اسم الحساب',
                                  value: user['profileName'],
                                  valueColor: AppColors.textPrimary,
                                ),
                                const Divider(color: Colors.white24, height: 12),
                                _buildReceiptRow(
                                  icon: Icons.calendar_today,
                                  label: 'تاريخ الانتهاء',
                                  value: '${endDate.year}/${endDate.month}/${endDate.day}',
                                  valueColor: daysLeft <= 3 ? AppColors.error : AppColors.success,
                                ),
                                const Divider(color: Colors.white24, height: 12),
                                _buildReceiptRow(
                                  icon: Icons.access_time,
                                  label: 'الأيام المتبقية',
                                  value: daysLeft > 0 ? '$daysLeft يوم' : 'منتهي',
                                  valueColor: daysLeft <= 3 ? AppColors.error : AppColors.success,
                                ),
                                const Divider(color: Colors.white24, height: 12),
                                _buildReceiptRow(
                                  icon: Icons.attach_money,
                                  label: 'قيمة التجديد',
                                  value: '${user['amount']} د.ع',
                                  valueColor: AppColors.primaryGold,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Renewal Question
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success.withOpacity(0.2),
                                  AppColors.success.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.success.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.autorenew,
                                  color: AppColors.success,
                                  size: 26,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'هل تريد تجديد باقة الاشتراك؟',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'تواصل معنا لتجديد اشتراكك والاستمتاع بخدماتنا المميزة',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Footer Message
                          Text(
                            '💎 نقدر ثقتكم بنا ونتطلع لخدمتكم دائماً 💎',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                  
                  // Action Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'تم إعداد الإيصال! يمكنك الآن تصويره وإرساله للزبون',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.primaryGold,
                      ),
                      icon: Icon(Icons.camera_alt, color: AppColors.charcoal, size: 20),
                      label: Text(
                        'جاهز للإرسال',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.charcoal,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
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
  
  Widget _buildReceiptRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.primaryGold, size: 15),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _editUser(int index) {
    final user = widget.subscription['users'][index];
    final customerNameController = TextEditingController(text: user['customerName']);
    final profileNameController = TextEditingController(text: user['profileName']);
    final amountController = TextEditingController(text: user['amount'].toString());
    DateTime startDate = user['startDate'];
    DateTime endDate = user['endDate'];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 580),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.info, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.info.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.info, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'تعديل المستخدم',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: customerNameController,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'اسم الزبون',
                        prefixIcon: Icon(Icons.person, color: AppColors.primaryGold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: profileNameController,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        labelText: 'اسم البروفايل',
                        prefixIcon: Icon(Icons.badge, color: AppColors.primaryGold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: amountController,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.right,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'المبلغ المدفوع (د.ع)',
                        prefixIcon: Icon(Icons.attach_money, color: AppColors.primaryGold),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'من',
                            date: startDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: AppColors.primaryGold,
                                        surface: AppColors.charcoal,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                startDate = picked;
                                (context as Element).markNeedsBuild();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateField(
                            label: 'إلى',
                            date: endDate,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: ColorScheme.dark(
                                        primary: AppColors.primaryGold,
                                        surface: AppColors.charcoal,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                endDate = picked;
                                (context as Element).markNeedsBuild();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (customerNameController.text.isEmpty ||
                              profileNameController.text.isEmpty ||
                              amountController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'الرجاء ملء جميع الحقول',
                                  style: AppTextStyles.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                backgroundColor: AppColors.error,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          
                          Navigator.pop(context);
                          
                          // تحديث المستخدم عبر API
                          final response = await ApiService.updateSubscriptionUser(
                            userId: user['id'],
                            customerName: customerNameController.text,
                            profileName: profileNameController.text,
                            amount: double.tryParse(amountController.text) ?? 0,
                            startDate: startDate.toIso8601String().split('T')[0],
                            endDate: endDate.toIso8601String().split('T')[0],
                          );
                          
                          if (response['success'] == true) {
                            await widget.onUpdate();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text(
                                        'تم تعديل البيانات بنجاح',
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response['message'] ?? 'فشل تحديث البيانات'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: AppColors.info,
                        ),
                        child: Text(
                          'حفظ التعديلات',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _extendSubscription(int index) async {
    final user = widget.subscription['users'][index];
    
    // تمديد الاشتراك عبر API
    final response = await ApiService.extendSubscriptionUser(user['id'], 30);
    
    if (response['success'] == true) {
      await widget.onUpdate();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'تم تمديد الاشتراك لمدة شهر',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'فشل تمديد الاشتراك'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _deleteUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.error, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 32),
            const SizedBox(width: 12),
            Text(
              'تأكيد الحذف',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا المستخدم؟',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.right,
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
            onPressed: () async {
              Navigator.pop(context);
              
              final user = widget.subscription['users'][index];
              
              // حذف المستخدم عبر API في الخلفية
              ApiService.deleteSubscriptionUser(user['id']).then((response) async {
                if (response['success'] == true) {
                  await widget.onUpdate();
                } else {
                  // استعادة البيانات إذا فشل
                  await widget.onUpdate();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message'] ?? 'فشل حذف المستخدم'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              });
              
              // تحديث فوري وإشعار
              await widget.onUpdate();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 24,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تم حذف المستخدم بنجاح',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
  
  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glassBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassWhite, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primaryGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${date.year}/${date.month}/${date.day}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final users = widget.subscription['users'] as List;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryGold,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGold.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Icon(Icons.subscriptions, color: AppColors.charcoal, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subscription['serviceName'],
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: AppColors.charcoal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${users.length} / ${widget.subscription['maxUsers']} مستخدمين',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.charcoal.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.charcoal),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Add User Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onAddUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                  icon: Icon(Icons.person_add, color: Colors.white),
                  label: Text(
                    'إضافة مستخدم جديد',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Users List
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 60, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'لا يوجد مستخدمين',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(user, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final endDate = user['endDate'] as DateTime;
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    
    Color dateColor;
    if (daysLeft <= 1) {
      dateColor = AppColors.error;
    } else if (daysLeft <= 2) {
      dateColor = const Color(0xFFFF9800); // Orange
    } else if (daysLeft <= 3) {
      dateColor = AppColors.warning;
    } else {
      dateColor = AppColors.success;
    }
    
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: index * 100),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [AppColors.glassWhite, AppColors.glassBlack],
          ),
          border: Border.all(color: dateColor, width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['customerName'],
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['profileName'],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (widget.userRole == 'admin') ...[
                        const SizedBox(height: 4),
                        Text(
                          'أضافه: ${user['addedBy']}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.info,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action Icons
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.receipt_long, color: AppColors.primaryGold, size: 20),
                      onPressed: () => _showReceiptDialog(user),
                      tooltip: 'إيصال التذكير',
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: AppColors.info, size: 20),
                      onPressed: () => _editUser(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.access_time, color: AppColors.warning, size: 20),
                      onPressed: () => _extendSubscription(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: AppColors.error, size: 20),
                      onPressed: () => _deleteUser(index),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dateColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    daysLeft > 0 ? 'متبقي $daysLeft يوم' : 'منتهي',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${user['amount']} د.ع',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
