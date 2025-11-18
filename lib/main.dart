import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subscriptions_screen.dart';
import 'screens/orders_management_screen.dart';
import 'screens/archive_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/employees_management_screen.dart';
import 'screens/capital_screen.dart' show CapitalScreen, capitalRouteObserver;
import 'screens/settlement_screen.dart';
import 'screens/settlements_management_screen.dart';
import 'services/api_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';
import 'styles/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // تعيين اتجاه الشريط العلوي
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.pureBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظامي الفخم',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryGold,
        scaffoldBackgroundColor: AppColors.pureBlack,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      navigatorObservers: [capitalRouteObserver],
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/subscriptions': (context) => const SubscriptionsScreen(),
        '/orders': (context) => const OrdersManagementScreen(),
        '/archive': (context) => const ArchiveScreen(),
        '/statistics': (context) => const StatisticsScreen(),
        '/employees': (context) => const EmployeesManagementScreen(),
        '/capital': (context) => const CapitalScreen(),
        '/settlement': (context) => const SettlementScreen(),
        '/settlements-management': (context) => const SettlementsManagementScreen(),
      },
    );
  }
}

/// شاشة البداية - تفحص حالة تسجيل الدخول
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // فحص التحديثات أولاً
    await _checkForUpdates();
    
    final isLoggedIn = await ApiService.isLoggedIn();
    
    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // فحص إذا كان فيه بيانات محفوظة (Remember Me)
        final savedCreds = await ApiService.getSavedCredentials();
        if (savedCreds['username'] != null && savedCreds['password'] != null) {
          // محاولة تسجيل الدخول التلقائي
          final result = await ApiService.login(
            savedCreds['username']!,
            savedCreds['password']!,
          );
          
          if (result['success'] && mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
            return;
          }
        }
        
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
  
  Future<void> _checkForUpdates() async {
    try {
      // فحص وجود تحديث
      final updateInfo = await UpdateService.checkForUpdate();
      
      if (updateInfo['hasUpdate'] == true && mounted) {
        // عرض نافذة التحديث
        await showDialog(
          context: context,
          barrierDismissible: !updateInfo['mandatory'],
          builder: (context) => UpdateDialog(
            currentVersion: updateInfo['currentVersion'],
            latestVersion: updateInfo['latestVersion'],
            changelog: updateInfo['changelog'],
            downloadUrl: updateInfo['downloadUrl'],
            isMandatory: updateInfo['mandatory'],
          ),
        );
        
        // إذا كان التحديث إجباري، لا نكمل تسجيل الدخول
        if (updateInfo['mandatory']) {
          return; // البرنامج يبقى واقف على شاشة التحديث
        }
      }
    } catch (e) {
      print('خطأ في فحص التحديث: $e');
      // نكمل عادي حتى لو فيه مشكلة بالتحديث
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.diamond,
                  size: 50,
                  color: AppColors.pureBlack,
                ),
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(
                color: AppColors.primaryGold,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
