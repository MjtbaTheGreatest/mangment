import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة التحديث التلقائي للبرنامج
class UpdateService {
  // معلومات المستودع على GitHub
  static const String repoOwner = 'MjtbaTheGreatest';
  static const String repoName = 'mangment';
  static const String githubApiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String releasesUrl = 'https://github.com/$repoOwner/$repoName/releases/latest';
  
  // مفاتيح التخزين
  static const String _downloadedUpdatePathKey = 'downloaded_update_path';
  static const String _downloadedUpdateVersionKey = 'downloaded_update_version';

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

  /// تحميل التحديث (ZIP أو EXE)
  static Future<Map<String, dynamic>> downloadUpdate(
    String downloadUrl,
    String version,
    Function(double progress) onProgress,
  ) async {
    try {
      print('📥 بدء تحميل التحديث من: $downloadUrl');
      
      // إنشاء مجلد للتحديثات
      final appDir = await getApplicationDocumentsDirectory();
      final updatesDir = Directory('${appDir.path}\\Updates');
      if (!await updatesDir.exists()) {
        await updatesDir.create(recursive: true);
      }
      
      // تحديد نوع الملف (ZIP للنسخة الكاملة، EXE للمثبت)
      final urlFileName = downloadUrl.split('/').last;
      final isZip = urlFileName.toLowerCase().endsWith('.zip');
      final fileName = urlFileName.isNotEmpty ? urlFileName : 
                      (isZip ? 'my_system_v$version.zip' : 'my_system_setup_v$version.exe');
      final filePath = '${updatesDir.path}\\$fileName';
      final file = File(filePath);
      
      // حذف الملف القديم إذا كان موجوداً
      if (await file.exists()) {
        await file.delete();
      }
      
      // تحميل الملف
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final total = response.contentLength ?? 0;
        int received = 0;
        final sink = file.openWrite();
        
        await for (var chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            final progress = received / total;
            onProgress(progress);
            print('📊 التقدم: ${(progress * 100).toStringAsFixed(1)}%');
          }
        }
        
        await sink.close();
        
        // حفظ معلومات التحديث المحمل
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_downloadedUpdatePathKey, filePath);
        await prefs.setString(_downloadedUpdateVersionKey, version);
        await prefs.setBool('_isZipUpdate', isZip);
        
        print('✅ تم تحميل التحديث إلى: $filePath');
        
        return {
          'success': true,
          'filePath': filePath,
          'version': version,
          'isZip': isZip,
        };
      } else {
        return {
          'success': false,
          'error': 'فشل التحميل: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ خطأ في تحميل التحديث: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// التحقق من وجود تحديث محمل مسبقاً
  static Future<Map<String, dynamic>> checkDownloadedUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filePath = prefs.getString(_downloadedUpdatePathKey);
      final version = prefs.getString(_downloadedUpdateVersionKey);
      
      if (filePath == null || version == null) {
        return {'hasDownloadedUpdate': false};
      }
      
      final file = File(filePath);
      if (!await file.exists()) {
        // الملف غير موجود، حذف المعلومات المحفوظة
        await prefs.remove(_downloadedUpdatePathKey);
        await prefs.remove(_downloadedUpdateVersionKey);
        return {'hasDownloadedUpdate': false};
      }
      
      // التحقق من أن الإصدار المحمل أحدث من الحالي
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final comparison = compareVersions(version, currentVersion);
      
      if (comparison > 0) {
        // التحديث المحمل أحدث من النسخة الحالية
        return {
          'hasDownloadedUpdate': true,
          'filePath': filePath,
          'version': version,
        };
      } else if (comparison <= 0) {
        // التحديث المحمل نفس النسخة أو أقدم - حذفه تلقائياً
        print('🗑️ التحديث المحمل ($version) نفس النسخة الحالية أو أقدم ($currentVersion). جاري الحذف...');
        await file.delete();
        await prefs.remove(_downloadedUpdatePathKey);
        await prefs.remove(_downloadedUpdateVersionKey);
        return {'hasDownloadedUpdate': false};
      }
      
      return {'hasDownloadedUpdate': false};
    } catch (e) {
      print('❌ خطأ في التحقق من التحديث المحمل: $e');
      return {'hasDownloadedUpdate': false};
    }
  }

  /// تثبيت التحديث - تشغيل المثبت تلقائياً
  static Future<Map<String, dynamic>> installUpdate(String filePath) async {
    try {
      print('🔄 بدء تثبيت التحديث: $filePath');
      
      final updateFile = File(filePath);
      if (!await updateFile.exists()) {
        return {
          'success': false,
          'error': 'ملف التحديث غير موجود',
        };
      }
      
      if (Platform.isWindows) {
        // تشغيل المثبت بوضع صامت (/SILENT) أو بواجهة (/VERYSILENT لإخفاء كل شيء)
        // نستخدم /SILENT لإظهار progress فقط دون أي تفاعل
        print('🚀 تشغيل المثبت: $filePath');
        
        await Process.start(
          filePath,
          ['/SILENT', '/CLOSEAPPLICATIONS', '/RESTARTAPPLICATIONS'],
          mode: ProcessStartMode.detached,
        );
        
        print('✅ تم تشغيل المثبت. سيتم إغلاق البرنامج الحالي...');
        
        // الانتظار قليلاً لضمان بدء المثبت
        await Future.delayed(const Duration(seconds: 1));
        
        return {
          'success': true,
          'message': 'جاري التثبيت... سيتم إعادة تشغيل البرنامج تلقائياً.',
          'shouldExit': true, // إشارة لإغلاق البرنامج
        };
      }
      
      return {'success': true};
    } catch (e) {
      print('❌ خطأ في تثبيت التحديث: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// حذف التحديث المحمل
  static Future<void> clearDownloadedUpdate({bool deleteFile = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filePath = prefs.getString(_downloadedUpdatePathKey);
      
      if (filePath != null && deleteFile) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ تم حذف ملف التحديث');
        }
      }
      
      await prefs.remove(_downloadedUpdatePathKey);
      await prefs.remove(_downloadedUpdateVersionKey);
      
      print('🗑️ تم مسح بيانات التحديث من الذاكرة');
    } catch (e) {
      print('❌ خطأ في حذف التحديث: $e');
    }
  }

  /// الحصول على رابط تحميل نسخة Windows من assets
  static String? _getWindowsDownloadUrl(List<dynamic> assets) {
    // البحث عن ملف المثبت أولاً (Inno Setup)
    for (var asset in assets) {
      final name = (asset['name'] as String).toLowerCase();
      // البحث عن ملف installer أو setup
      if ((name.contains('setup') || name.contains('installer')) && name.endsWith('.exe')) {
        return asset['browser_download_url'] as String;
      }
    }
    
    // إذا لم يجد، ابحث عن أي exe
    for (var asset in assets) {
      final name = (asset['name'] as String).toLowerCase();
      if (name.endsWith('.exe')) {
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
