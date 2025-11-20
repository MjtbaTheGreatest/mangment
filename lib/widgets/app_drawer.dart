import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';

/// Drawer موحد لجميع الصفحات - يحتوي على جميع الروابط
class AppDrawer extends StatelessWidget {
  final String? currentRoute;

  const AppDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
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
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGold.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.diamond, size: 40, color: AppColors.pureBlack),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'إدارة الطيف',
                      style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textGold),
                    ),
                    Text(
                      'نظام الإدارة المتكامل',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              
              Divider(color: AppColors.primaryGold.withOpacity(0.3), thickness: 1),
              
              // القائمة الرئيسية
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      title: 'الصفحة الرئيسية',
                      route: '/',
                    ),
                    
                    const SizedBox(height: 8),
                    Divider(
                      color: AppColors.glassWhite.withOpacity(0.3),
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    const SizedBox(height: 8),
                    
                    _buildDrawerItem(
                      context,
                      icon: Icons.subscriptions,
                      title: 'إدارة الاشتراكات',
                      route: '/subscriptions',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.shopping_bag,
                      title: 'إدارة الطلبات',
                      route: '/orders',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.archive,
                      title: 'الأرشيف',
                      route: '/archive',
                    ),
                    
                    const SizedBox(height: 8),
                    Divider(
                      color: AppColors.glassWhite.withOpacity(0.3),
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    const SizedBox(height: 8),
                    
                    _buildDrawerItem(
                      context,
                      icon: Icons.bar_chart,
                      title: 'الإحصائيات',
                      route: '/statistics',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.attach_money,
                      title: 'رأس المال',
                      route: '/capital',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.calculate,
                      title: 'التسوية',
                      route: '/settlement',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.list_alt,
                      title: 'إدارة التسويات',
                      route: '/settlements_management',
                    ),
                    
                    const SizedBox(height: 8),
                    Divider(
                      color: AppColors.glassWhite.withOpacity(0.3),
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    const SizedBox(height: 8),
                    
                    // إدارة الموظفين - للمدير فقط
                    FutureBuilder<String?>(
                      future: ApiService.getRole(),
                      builder: (context, snapshot) {
                        if (snapshot.data == 'admin') {
                          return Column(
                            children: [
                              _buildDrawerItem(
                                context,
                                icon: Icons.manage_accounts,
                                title: 'إدارة الموظفين',
                                route: '/employees',
                              ),
                              _buildDrawerItem(
                                context,
                                icon: Icons.admin_panel_settings,
                                title: 'إعدادات المدير',
                                route: '/admin-settings',
                              ),
                            ],
                          );
                        } else {
                          return _buildDrawerItem(
                            context,
                            icon: Icons.settings,
                            title: 'الإعدادات',
                            route: '/settings',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              Divider(color: AppColors.primaryGold.withOpacity(0.3), thickness: 1),
              
              // تسجيل الخروج
              ListTile(
                leading: Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'تسجيل الخروج',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                hoverColor: AppColors.error.withOpacity(0.1),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isSelected = currentRoute == route;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryGold : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.primaryGold : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primaryGold.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context); // إغلاق الـ Drawer
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      hoverColor: AppColors.glassWhite,
    );
  }
}
