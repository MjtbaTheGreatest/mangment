import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// خدمة التحديث التلقائي للبرنامج
class UpdateService {
  // رابط ملف الإصدار على GitHub
  static const String versionUrl = 
      'https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/version.json';
  
  // رابط صفحة الإصدارات
  static const String releasesUrl = 
      'https://github.com/YOUR_USERNAME/YOUR_REPO/releases/latest';

  /// فحص وجود تحديث جديد
  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      // الحصول على معلومات البرنامج الحالي
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      print('🔍 النسخة الحالية: $currentVersion (Build $currentBuildNumber)');

      // جلب معلومات الإصدار من السيرفر
      final response = await http.get(
        Uri.parse(versionUrl),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['version'] as String;
        final latestBuildNumber = data['build_number'] as int;
        final downloadUrl = data['download_url'] as String;
        final changelog = data['changelog'] as String;
        final isMandatory = data['mandatory'] as bool? ?? false;

        print('📦 آخر إصدار: $latestVersion (Build $latestBuildNumber)');

        // مقارنة رقم البناء
        if (latestBuildNumber > currentBuildNumber) {
          return {
            'hasUpdate': true,
            'currentVersion': currentVersion,
            'latestVersion': latestVersion,
            'currentBuild': currentBuildNumber,
            'latestBuild': latestBuildNumber,
            'downloadUrl': downloadUrl,
            'changelog': changelog,
            'mandatory': isMandatory,
          };
        }

        return {'hasUpdate': false};
      } else {
        print('❌ فشل جلب معلومات التحديث: ${response.statusCode}');
        return {'hasUpdate': false, 'error': 'فشل الاتصال بالسيرفر'};
      }
    } catch (e) {
      print('❌ خطأ في فحص التحديث: $e');
      return {'hasUpdate': false, 'error': e.toString()};
    }
  }

  /// فتح صفحة التحميل
  static Future<void> openDownloadPage(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('❌ لا يمكن فتح الرابط: $url');
      }
    } catch (e) {
      print('❌ خطأ في فتح رابط التحميل: $e');
    }
  }

  /// مقارنة الإصدارات (semantic versioning)
  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }

    return 0;
  }
}
