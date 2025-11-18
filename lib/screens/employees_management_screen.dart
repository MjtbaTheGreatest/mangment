import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

/// صفحة إدارة الموظفين الشاملة - للمدير فقط
class EmployeesManagementScreen extends StatefulWidget {
  const EmployeesManagementScreen({super.key});

  @override
  State<EmployeesManagementScreen> createState() => _EmployeesManagementScreenState();
}

class _EmployeesManagementScreenState extends State<EmployeesManagementScreen> {
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
            'إدارة الموظفين',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textGold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.person_add, color: AppColors.primaryGold),
              onPressed: () {
                // TODO: Add employee
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'يمكنك إضافة موظفين من صفحة الإعدادات',
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
                children: [
                  // Overview Cards
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildOverviewCard(
                            'إجمالي الموظفين',
                            '0',
                            Icons.people,
                            AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverviewCard(
                            'النشطين اليوم',
                            '0',
                            Icons.done_all,
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Search Bar
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [AppColors.glassWhite, AppColors.glassBlack],
                        ),
                        border: Border.all(color: AppColors.primaryGold, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppColors.primaryGold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'بحث عن موظف...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Employees List
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 400),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا يوجد موظفين',
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سيتم عرض إحصائيات الموظفين هنا',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [AppColors.glassWhite, AppColors.glassBlack],
                              ),
                              border: Border.all(color: AppColors.info, width: 1),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.info, size: 40),
                                const SizedBox(height: 12),
                                Text(
                                  'ستظهر هنا معلومات مفصلة عن كل موظف:',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• عدد الطلبات المنجزة\n'
                                  '• إجمالي المبيعات\n'
                                  '• ساعات العمل\n'
                                  '• تقييم الأداء',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.glassWhite, AppColors.glassBlack],
        ),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
                      child: Icon(Icons.people, size: 40, color: AppColors.pureBlack),
                    ),
                    const SizedBox(height: 16),
                    Text('إدارة الموظفين', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold)),
                    Text('مدير النظام', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
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
                    _buildDrawerItem(Icons.shopping_bag, 'إدارة الطلبات', () { Navigator.pop(context); Navigator.pushNamed(context, '/orders'); }),
                    _buildDrawerItem(Icons.archive, 'الأرشيف', () { Navigator.pop(context); Navigator.pushNamed(context, '/archive'); }),
                    Divider(color: AppColors.glassWhite.withOpacity(0.3), thickness: 1, indent: 16, endIndent: 16),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('إدارة المدير', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                  _buildDrawerItem(Icons.bar_chart, 'الإحصائيات', () { Navigator.pop(context); Navigator.pushNamed(context, '/statistics'); }),
                  _buildDrawerItem(Icons.account_balance_wallet, 'رأس المال', () { Navigator.pop(context); Navigator.pushNamed(context, '/capital'); }),
                  _buildDrawerItem(Icons.people, 'إدارة الموظفين', () => Navigator.pop(context)),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.glassWhite, thickness: 1),
                    _buildDrawerItem(Icons.logout, 'تسجيل الخروج', () async { if (context.mounted) Navigator.of(context).pushReplacementNamed('/login'); }),
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
