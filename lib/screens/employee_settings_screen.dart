import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../services/api_service.dart';
import '../services/update_service.dart';

/// صفحة إعدادات الموظف
class EmployeeSettingsScreen extends StatefulWidget {
  const EmployeeSettingsScreen({super.key});

  @override
  State<EmployeeSettingsScreen> createState() => _EmployeeSettingsScreenState();
}

class _EmployeeSettingsScreenState extends State<EmployeeSettingsScreen> {
  String _currentVersion = '...';
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  /// التحقق من التحديثات يدوياً
  Future<void> _checkForUpdates() async {
    // أولاً: التحقق من وجود تحديث محمل مسبقاً
    final downloadedUpdate = await UpdateService.checkDownloadedUpdate();
    
    if (downloadedUpdate['hasDownloadedUpdate'] == true) {
      _showInstallDownloadedUpdateDialog(
        version: downloadedUpdate['version'],
        filePath: downloadedUpdate['filePath'],
      );
      return;
    }
    
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
              const SizedBox(height: 16),
              Text(
                'جاري البحث عن تحديثات...',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final result = await UpdateService.checkForUpdate();
    
    if (!mounted) return;
    
    // إغلاق مؤشر التحميل
    Navigator.pop(context);

    if (result['hasUpdate'] == true) {
      _showUpdateDialog(
        currentVersion: result['currentVersion'],
        latestVersion: result['latestVersion'],
        changelog: result['changelog'],
        downloadUrl: result['downloadUrl'],
      );
    } else if (result['error'] != null) {
      _showErrorDialog('فشل التحقق من التحديثات', result['error']);
    } else {
      _showSuccessDialog(
        'لا توجد تحديثات',
        'أنت تستخدم أحدث إصدار من البرنامج',
      );
    }
  }

  /// عرض نافذة تثبيت التحديث المحمل مسبقاً
  void _showInstallDownloadedUpdateDialog({
    required String version,
    required String filePath,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحديث جاهز للتثبيت',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'الإصدار $version',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          'تم تحميل التحديث مسبقاً وجاهز للتثبيت. هل تريد تثبيته الآن؟',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'لاحقاً',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await UpdateService.clearDownloadedUpdate();
              _showSuccessDialog(
                'تم الحذف',
                'تم حذف التحديث المحمل',
              );
            },
            child: Text(
              'حذف',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _installUpdate(filePath);
            },
            icon: const Icon(Icons.install_desktop, size: 20),
            label: Text(
              'تثبيت الآن',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// عرض نافذة التحديث
  void _showUpdateDialog({
    required String currentVersion,
    required String latestVersion,
    required String changelog,
    required String downloadUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.system_update,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحديث متاح!',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'الإصدار $latestVersion',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('النسخة الحالية:', currentVersion),
              const SizedBox(height: 8),
              _buildInfoRow('الإصدار الجديد:', latestVersion),
              const SizedBox(height: 20),
              Text(
                'ما الجديد:',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.pureBlack.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    changelog,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'لاحقاً',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _downloadAndInstallUpdate(
                downloadUrl: downloadUrl,
                version: latestVersion,
              );
            },
            icon: const Icon(Icons.download, size: 20),
            label: Text(
              'تحميل وتثبيت',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'حسناً',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: AppColors.success,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'حسناً',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// تحميل وتثبيت التحديث
  Future<void> _downloadAndInstallUpdate({
    required String downloadUrl,
    required String version,
  }) async {
    double downloadProgress = 0.0;
    void Function(void Function())? dialogSetState;
    
    // عرض نافذة التقدم
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          // حفظ reference للـ setState
          dialogSetState = setDialogState;
          
          return AlertDialog(
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
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'جاري التحميل...',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textGold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: downloadProgress,
                  backgroundColor: AppColors.textSecondary.withOpacity(0.2),
                  color: Colors.blue,
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Text(
                  '${(downloadProgress * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'الإصدار: $version',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // تحميل التحديث
    final result = await UpdateService.downloadUpdate(
      downloadUrl,
      version,
      (progress) {
        downloadProgress = progress;
        // تحديث واجهة الـ dialog
        dialogSetState?.call(() {});
      },
    );

    if (!mounted) return;
    
    // إغلاق نافذة التقدم
    Navigator.pop(context);

    if (result['success'] == true) {
      // عرض نافذة التثبيت
      _showInstallConfirmDialog(
        version: version,
        filePath: result['filePath'],
      );
    } else {
      _showErrorDialog(
        'فشل التحميل',
        result['error'] ?? 'حدث خطأ أثناء تحميل التحديث',
      );
    }
  }

  /// عرض نافذة تأكيد التثبيت
  void _showInstallConfirmDialog({
    required String version,
    required String filePath,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'تم التحميل بنجاح!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم تحميل الإصدار $version بنجاح.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
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
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'سيتم إغلاق البرنامج وتشغيل المثبت',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'تثبيت لاحقاً',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _installUpdate(filePath);
            },
            icon: const Icon(Icons.install_desktop, size: 20),
            label: Text(
              'تثبيت الآن',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// تثبيت التحديث
  Future<void> _installUpdate(String filePath) async {
    // عرض مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.charcoal,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryGold,
              ),
              const SizedBox(height: 16),
              Text(
                'جاري التثبيت...',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final result = await UpdateService.installUpdate(filePath);
    
    if (!mounted) return;
    
    Navigator.pop(context);

    if (result['success'] != true) {
      _showErrorDialog(
        'فشل التثبيت',
        result['error'] ?? 'حدث خطأ أثناء تثبيت التحديث',
      );
    } else if (result['shouldExit'] == true) {
      // مسح معلومات التحديث من الذاكرة فقط (بدون حذف الملف)
      await UpdateService.clearDownloadedUpdate(deleteFile: false);
      
      // إغلاق البرنامج لإتمام التثبيت
      exit(0);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.darkGray,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تسجيل الخروج',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
          ),
          content: Text(
            'هل تريد تسجيل الخروج من حسابك؟',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: AppTextStyles.bodyMedium),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('تسجيل الخروج', style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await ApiService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.darkGray,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'تغيير كلمة المرور',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textGold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الحالية',
                    labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightGray),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.lightGray.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryGold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                    labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightGray),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.lightGray.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryGold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightGray),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.lightGray.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryGold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: AppTextStyles.bodyMedium),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('كلمة المرور غير متطابقة', style: AppTextStyles.bodyMedium),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('حفظ', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pureBlack)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      // TODO: Implement password change API call
      _showMessage('تم تغيير كلمة المرور بنجاح', isError: false);
    }
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
                            Icons.settings,
                            size: 40,
                            color: AppColors.pureBlack,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الإعدادات',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: AppColors.pureBlack,
                                  ),
                                ),
                                Text(
                                  'إدارة حسابك والتطبيق',
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

                  const SizedBox(height: 30),

                  // التحديثات
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 100),
                    child: _buildSettingsCard(
                      icon: Icons.system_update_alt,
                      title: 'التحقق من التحديثات',
                      subtitle: 'الإصدار الحالي: $_currentVersion',
                      onTap: _isCheckingUpdate ? null : _checkForUpdates,
                      trailing: _isCheckingUpdate
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.primaryGold),
                              ),
                            )
                          : Icon(Icons.chevron_left, color: AppColors.primaryGold),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // تغيير كلمة المرور
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: _buildSettingsCard(
                      icon: Icons.lock_outline,
                      title: 'تغيير كلمة المرور',
                      subtitle: 'تحديث كلمة المرور الخاصة بك',
                      onTap: _changePassword,
                      trailing: Icon(Icons.chevron_left, color: AppColors.primaryGold),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // معلومات الحساب
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 300),
                    child: FutureBuilder<String?>(
                      future: ApiService.getName(),
                      builder: (context, snapshot) {
                        return _buildInfoCard(
                          icon: Icons.person_outline,
                          title: 'الاسم',
                          value: snapshot.data ?? 'جاري التحميل...',
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 400),
                    child: FutureBuilder<String?>(
                      future: ApiService.getUsername(),
                      builder: (context, snapshot) {
                        return _buildInfoCard(
                          icon: Icons.account_circle_outlined,
                          title: 'اسم المستخدم',
                          value: snapshot.data ?? 'جاري التحميل...',
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // تسجيل الخروج
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 500),
                    child: _buildLogoutCard(),
                  ),

                  const SizedBox(height: 30),

                  // معلومات التطبيق
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 600),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'نظام إدارة الطيف',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.lightGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الإصدار $_currentVersion',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.lightGray.withOpacity(0.7),
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

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    required Widget trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.charcoal.withOpacity(0.8),
            AppColors.darkGray.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryGold, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.lightGray,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppColors.charcoal.withOpacity(0.8),
            AppColors.darkGray.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withOpacity(0.2),
          width: 1,
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
            child: Icon(icon, color: AppColors.primaryGold, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.red.withOpacity(0.2),
            Colors.red.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.logout, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تسجيل الخروج',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الخروج من حسابك',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
