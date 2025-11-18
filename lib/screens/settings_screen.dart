import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// صفحة الإعدادات (للمدير فقط)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            'الإعدادات',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 40,
                            color: AppColors.pureBlack,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'لوحة التحكم',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: AppColors.pureBlack,
                                  ),
                                ),
                                Text(
                                  'إدارة النظام والمستخدمين',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.darkGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section Title
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'إدارة المستخدمين',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textGold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // User Management Cards
                  _buildSettingCard(
                    icon: Icons.person_add,
                    title: 'إضافة موظف جديد',
                    subtitle: 'إنشاء حساب لموظف جديد',
                    color: AppColors.success,
                    delay: 300,
                    onTap: () {
                      _showAddUserDialog();
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildSettingCard(
                    icon: Icons.people,
                    title: 'عرض جميع الموظفين',
                    subtitle: 'إدارة وتعديل حسابات الموظفين',
                    color: AppColors.info,
                    delay: 400,
                    onTap: () {
                      _showUsersListDialog();
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section Title
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'إعدادات النظام',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textGold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSettingCard(
                    icon: Icons.category,
                    title: 'إدارة الأقسام والمنتجات',
                    subtitle: 'إضافة وتعديل المنتجات',
                    color: AppColors.warning,
                    delay: 600,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'قريباً: إدارة المنتجات',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: AppColors.info,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildSettingCard(
                    icon: Icons.receipt_long,
                    title: 'التقارير والإحصائيات',
                    subtitle: 'عرض تقارير المبيعات',
                    color: AppColors.primaryGold,
                    delay: 700,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'قريباً: التقارير',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: AppColors.info,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildSettingCard(
                    icon: Icons.backup,
                    title: 'النسخ الاحتياطي',
                    subtitle: 'حفظ نسخة من قاعدة البيانات',
                    color: AppColors.mediumGold,
                    delay: 800,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'قريباً: النسخ الاحتياطي',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: AppColors.info,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int delay,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: delay),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.glassWhite,
              AppColors.glassBlack,
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.2),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: color,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'employee';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.primaryGold,
              width: 2,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGold, AppColors.mediumGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.person_add, color: AppColors.charcoal, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'إضافة موظف جديد',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(
                  controller: nameController,
                  label: 'الاسم الكامل',
                  icon: Icons.badge,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: usernameController,
                  label: 'اسم المستخدم',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildDialogTextField(
                  controller: passwordController,
                  label: 'كلمة المرور',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.glassBlack,
                    border: Border.all(color: AppColors.glassWhite),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    dropdownColor: AppColors.charcoal,
                    underline: const SizedBox(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'employee',
                        child: Text('موظف'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('مدير'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedRole = value!);
                    },
                  ),
                ),
              ],
            ),
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
                if (nameController.text.isEmpty ||
                    usernameController.text.isEmpty ||
                    passwordController.text.isEmpty) {
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

                // عرض loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGold,
                    ),
                  ),
                );

                // استدعاء API
                final result = await ApiService.createUser(
                  usernameController.text.trim(),
                  passwordController.text,
                  nameController.text.trim(),
                  selectedRole,
                );

                if (context.mounted) {
                  Navigator.pop(context); // إغلاق loading
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'],
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: result['success']
                          ? AppColors.success
                          : AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'إضافة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUsersListDialog() async {
    // عرض loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGold,
        ),
      ),
    );

    // جلب قائمة المستخدمين
    final result = await ApiService.getUsersList();

    if (!mounted) return;
    
    Navigator.pop(context); // إغلاق loading

    if (result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'],
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final users = result['users'] as List;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.primaryGold, width: 2),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGold.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: AppColors.charcoal, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'قائمة الموظفين',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${users.length}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isAdmin = user['role'] == 'admin';
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.glassWhite,
                        AppColors.glassBlack,
                      ],
                    ),
                    border: Border.all(
                      color: isAdmin ? AppColors.primaryGold : AppColors.glassWhite,
                      width: isAdmin ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isAdmin 
                            ? AppColors.primaryGold.withOpacity(0.2)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar with gradient
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: isAdmin 
                                ? AppColors.goldGradient
                                : LinearGradient(
                                    colors: [AppColors.mediumGray, AppColors.darkGray],
                                  ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: isAdmin 
                                    ? AppColors.primaryGold.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: isAdmin ? AppColors.charcoal : AppColors.textPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? user['username'],
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${user['username']}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isAdmin 
                                      ? AppColors.goldGradient
                                      : LinearGradient(
                                          colors: [AppColors.mediumGray, AppColors.darkGray],
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isAdmin ? 'مدير' : 'موظف',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isAdmin ? AppColors.charcoal : AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons
                        Column(
                          children: [
                            // Change Password Button
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.info,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.info.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.lock_reset, color: Colors.white, size: 20),
                              ),
                              onPressed: () {
                                _showChangePasswordDialog(user['id'], user['name'] ?? user['username']);
                              },
                            ),
                            // Delete Button (only for non-admin users)
                            if (!isAdmin)
                              IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.error.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.delete, color: Colors.white, size: 20),
                                ),
                                onPressed: () {
                                  _showDeleteConfirmDialog(user['id'], user['name'] ?? user['username'], () {
                                    Navigator.pop(context); // Close users list
                                    _showUsersListDialog(); // Refresh the list
                                  });
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'إغلاق',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.charcoal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(int userId, String userName, VoidCallback onSuccess) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.error, width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.warning, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'تأكيد الحذف',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف المستخدم "$userName"؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGold,
                  ),
                ),
              );

              // Call API
              final result = await ApiService.deleteUser(userId);

              if (!mounted) return;
              Navigator.pop(context); // Close loading

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message'],
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: result['success'] ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              if (result['success']) {
                onSuccess();
              }
            },
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

  void _showChangePasswordDialog(int userId, String userName) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.info, width: 2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.info.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.lock_reset, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تغيير كلمة المرور',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              controller: passwordController,
              label: 'كلمة المرور الجديدة',
              icon: Icons.lock,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildDialogTextField(
              controller: confirmPasswordController,
              label: 'تأكيد كلمة المرور',
              icon: Icons.lock_outline,
              obscureText: true,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (passwordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
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

              if (passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'كلمات المرور غير متطابقة',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.pop(context); // Close dialog

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGold,
                  ),
                ),
              );

              // Call API
              final result = await ApiService.changePassword(
                userId,
                passwordController.text,
              );

              if (!mounted) return;
              Navigator.pop(context); // Close loading

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message'],
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  backgroundColor: result['success'] ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'تغيير',
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

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        filled: true,
        fillColor: AppColors.glassBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassWhite),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassWhite),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryGold, width: 2),
        ),
      ),
    );
  }
}
