import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/update_service.dart';

/// نافذة التحديث الإجباري
class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String changelog;
  final String downloadUrl;
  final bool isMandatory;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.changelog,
    required this.downloadUrl,
    required this.isMandatory,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isMandatory, // لا يمكن إغلاق النافذة إذا كان التحديث إجباري
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2A2A3E).withOpacity(0.95),
                    const Color(0xFF1E1E2E).withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryGold.withOpacity(0.5),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isMandatory 
                          ? Colors.orange.withOpacity(0.2)
                          : AppColors.primaryGold.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                    ),
                    child: Column(
                      children: [
                        // أيقونة
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isMandatory
                                ? Colors.orange.withOpacity(0.2)
                                : AppColors.primaryGold.withOpacity(0.2),
                            border: Border.all(
                              color: isMandatory 
                                  ? Colors.orange
                                  : AppColors.primaryGold,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            isMandatory ? Icons.system_update_alt : Icons.update,
                            size: 48,
                            color: isMandatory ? Colors.orange : AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // العنوان
                        Text(
                          isMandatory ? 'تحديث إجباري متوفر! 🎉' : 'تحديث جديد متوفر! ✨',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // معلومات الإصدار
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildVersionBadge(
                              'الحالية',
                              currentVersion,
                              Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: AppColors.primaryGold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            _buildVersionBadge(
                              'الجديدة',
                              latestVersion,
                              AppColors.primaryGold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // رسالة تحذيرية إذا كان إجباري
                        if (isMandatory) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'هذا التحديث إجباري ويجب تثبيته للاستمرار',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // عنوان التغييرات
                        Row(
                          children: [
                            Icon(
                              Icons.new_releases,
                              color: AppColors.primaryGold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ما الجديد:',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // قائمة التغييرات
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                changelog,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white70,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(22),
                      ),
                    ),
                    child: Row(
                      children: [
                        // زر التأجيل (فقط إذا لم يكن إجباري)
                        if (!isMandatory)
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'لاحقاً',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white60,
                                ),
                              ),
                            ),
                          ),
                        if (!isMandatory) const SizedBox(width: 12),

                        // زر التحديث
                        Expanded(
                          flex: isMandatory ? 1 : 2,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // TODO: استدعاء دالة التحميل والتثبيت من الإعدادات
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('للتحميل، اذهب إلى الإعدادات > التحقق من التحديثات')),
                              );
                              if (!isMandatory && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: Text(
                              isMandatory ? 'تحديث الآن' : 'تحميل التحديث',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMandatory 
                                  ? Colors.orange 
                                  : AppColors.primaryGold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
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

  Widget _buildVersionBadge(String label, String version, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
          Text(
            version,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
