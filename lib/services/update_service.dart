import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// خدمة التحديث التلقائي للبرنامج
class UpdateService {
  // معلومات المستودع على GitHub
  static const String repoOwner = 'MjtbaTheGreatest';
  static const String repoName = 'mangment';
  static const String githubApiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String releasesUrl = 'https://github.com/$repoOwner/$repoName/releases/latest';

  /// فحص وجود تحديث جديد
  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      // الحصول على معلومات البرنامج الحالي
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.parse(packageInfo.buildNumber);

      print('🔍 النسخة الحالية: $currentVersion (Build $currentBuildNumber)');

      // جلب معلومات آخر إصدار من GitHub API
      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String;
        final latestVersion = tagName.replaceAll('v', '').replaceAll('V', '');
        final downloadUrl = _getWindowsDownloadUrl(data['assets'] as List<dynamic>);
        final changelog = data['body'] as String? ?? 'لا توجد ملاحظات إصدار';

        print('📦 آخر إصدار: $latestVersion');
        print('📥 رابط التحميل: $downloadUrl');

        // مقارنة النسخ
        final needsUpdate = compareVersions(latestVersion, currentVersion) > 0;

        if (needsUpdate) {
          return {
            'hasUpdate': true,
            'currentVersion': currentVersion,
            'latestVersion': latestVersion,
            'currentBuild': currentBuildNumber,
            'downloadUrl': downloadUrl,
            'changelog': changelog,
            'mandatory': false,
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

  /// الحصول على رابط تحميل نسخة Windows من assets
  static String? _getWindowsDownloadUrl(List<dynamic> assets) {
    for (var asset in assets) {
      final name = (asset['name'] as String).toLowerCase();
      if (name.endsWith('.exe') || 
          name.endsWith('.msi') ||
          name.endsWith('.zip') && name.contains('windows')) {
        return asset['browser_download_url'] as String;
      }
    }
    return releasesUrl; // إذا لم يجد ملف مباشر، يعيد رابط صفحة الإصدارات
  }

  /// مقارنة الإصدارات (semantic versioning)
  static int compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final p1 = parts1.length > i ? parts1[i] : 0;
        final p2 = parts2.length > i ? parts2[i] : 0;
        
        if (p1 > p2) return 1;
        if (p1 < p2) return -1;
      }

      return 0;
    } catch (e) {
      print('❌ خطأ في مقارنة الإصدارات: $e');
      return 0;
    }
  }
}
