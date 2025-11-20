import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import 'payment_methods_screen.dart';

/// صفحة إدارة إعدادات النظام
class ManageSettingsScreen extends StatelessWidget {
  const ManageSettingsScreen({super.key});

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
            'إدارة الأقسام والمنتجات',
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
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade700.withOpacity(0.3),
                            Colors.blue.shade700.withOpacity(0.3),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.settings_applications,
                              size: 32,
                              color: AppColors.primaryGold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إعدادات النظام',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: AppColors.textGold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'إدارة البيانات الأساسية للنظام',
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
                  
                  const SizedBox(height: 32),
                  
                  // Section: Order Settings
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      '⚙️ إعدادات الطلبات',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textGold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSettingCard(
                    context,
                    icon: Icons.payment,
                    title: 'طرق الدفع',
                    subtitle: 'إضافة وتعديل وحذف طرق الدفع',
                    color: Colors.green,
                    emoji: '💳',
                    delay: 300,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildSettingCard(
                    context,
                    icon: Icons.category,
                    title: 'الأقسام',
                    subtitle: 'إدارة أقسام المنتجات',
                    color: Colors.orange,
                    emoji: '📂',
                    delay: 400,
                    onTap: () {
                      _showComingSoon(context, 'إدارة الأقسام');
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildSettingCard(
                    context,
                    icon: Icons.inventory_2,
                    title: 'المنتجات',
                    subtitle: 'إضافة وتعديل المنتجات',
                    color: Colors.blue,
                    emoji: '📦',
                    delay: 500,
                    onTap: () {
                      _showComingSoon(context, 'إدارة المنتجات');
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section: General Settings
                  FadeInLeft(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 600),
                    child: Text(
                      '🎨 الإعدادات العامة',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textGold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildSettingCard(
                    context,
                    icon: Icons.color_lens,
                    title: 'المظهر والألوان',
                    subtitle: 'تخصيص شكل النظام',
                    color: Colors.purple,
                    emoji: '🎨',
                    delay: 700,
                    onTap: () {
                      _showComingSoon(context, 'إعدادات المظهر');
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildSettingCard(
                    context,
                    icon: Icons.notifications,
                    title: 'الإشعارات',
                    subtitle: 'إدارة الإشعارات والتنبيهات',
                    color: Colors.red,
                    emoji: '🔔',
                    delay: 800,
                    onTap: () {
                      _showComingSoon(context, 'إعدادات الإشعارات');
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

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String emoji,
    required int delay,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: delay),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 16,
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
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'قريباً: $feature',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
