import 'package:flutter/material.dart';
import '../styles/app_colors.dart';

/// Layout رئيسي مع NavigationRail ثابت في كل الصفحات
class MainLayout extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  const MainLayout({
    super.key,
    required this.child,
    this.selectedIndex = 0,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // NavigationRail الذهبي الثابت
          _buildNavigationRail(),
          
          // المحتوى الرئيسي
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.charcoal,
            AppColors.pureBlack,
          ],
        ),
        border: Border(
          left: BorderSide(
            color: AppColors.primaryGold.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // شعار البرنامج
            Container(
              width: 50,
              height: 50,
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
              child: Icon(
                Icons.diamond,
                color: AppColors.pureBlack,
                size: 28,
              ),
            ),
            
            const SizedBox(height: 30),
            Divider(color: AppColors.primaryGold.withOpacity(0.2), thickness: 1),
            const SizedBox(height: 20),
            
            // أزرار التنقل
            _buildNavItem(Icons.home, 'الرئيسية', 0, '/'),
            const SizedBox(height: 20),
            _buildNavItem(Icons.subscriptions, 'الاشتراكات', 1, '/subscriptions'),
            const SizedBox(height: 20),
            _buildNavItem(Icons.shopping_bag, 'الطلبات', 2, '/orders'),
            const SizedBox(height: 20),
            _buildNavItem(Icons.archive, 'الأرشيف', 3, '/archive'),
            const SizedBox(height: 20),
            _buildNavItem(Icons.bar_chart, 'الإحصائيات', 4, '/statistics'),
            const SizedBox(height: 20),
            _buildNavItem(Icons.attach_money, 'رأس المال', 5, '/capital'),
            const SizedBox(height: 20),
            _buildNavItem(Icons.calculate, 'التسوية', 6, '/settlement'),
            const SizedBox(height: 20),
            _buildNavItem(Icons.manage_accounts, 'الموظفين', 7, '/employees'),
            const SizedBox(height: 20),
            _buildNavItem(Icons.list_alt, 'إدارة التسويات', 8, '/settlements_management'),
            
            const Spacer(),
            
            // زر الإعدادات
            _buildNavItem(Icons.settings, 'الإعدادات', 9, '/settings'),
            const SizedBox(height: 20),
            
            // زر تسجيل الخروج
            InkWell(
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String tooltip, int index, String route) {
    final isSelected = widget.selectedIndex == index;
    
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      verticalOffset: 10,
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: isSelected
                ? AppColors.goldGradient
                : null,
            color: isSelected
                ? null
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppColors.primaryGold.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isSelected ? AppColors.pureBlack : AppColors.primaryGold,
            size: 24,
          ),
        ),
      ),
    );
  }
}
