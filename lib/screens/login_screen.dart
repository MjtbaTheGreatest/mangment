import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/glass_text_field.dart';
import '../widgets/glass_button.dart';
import '../services/api_service.dart';

/// شاشة تسجيل الدخول الفخمة بتصميم iOS 18
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final result = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'],
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            backgroundColor: result['success']
                ? AppColors.success
                : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (result['success']) {
          // حفظ بيانات الدخول إذا كان Remember Me مفعل
          if (_rememberMe) {
            await ApiService.saveCredentials(
              _usernameController.text.trim(),
              _passwordController.text,
            );
          }
          
          // الانتقال للصفحة الرئيسية
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            image: const DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
              opacity: 0.25,
              filterQuality: FilterQuality.high,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.goldGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGold.withOpacity(
                                      0.5,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 5,
                                    sigmaY: 5,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.lock_rounded,
                                      size: 50,
                                      color: AppColors.pureBlack,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            Text(
                              'أهلاً بعودتك',
                              style: AppTextStyles.headlineLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'سجل دخولك للمتابعة',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 200),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 500),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 52,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.glassWhite,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.pureBlack.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.glassWhite.withOpacity(0.15),
                                      AppColors.glassWhite.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      FadeInLeft(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      delay: const Duration(milliseconds: 400),
                                      child: GlassTextField(
                                        controller: _usernameController,
                                        label: 'اسم المستخدم',
                                        hint: 'أدخل اسم المستخدم',
                                        icon: Icons.person_rounded,
                                        keyboardType: TextInputType.text,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء إدخال اسم المستخدم';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 28),

                                    FadeInRight(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      delay: const Duration(milliseconds: 600),
                                      child: GlassTextField(
                                        controller: _passwordController,
                                        label: 'كلمة المرور',
                                        hint: 'أدخل كلمة المرور',
                                        icon: Icons.lock_rounded,
                                        isPassword: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'الرجاء إدخال كلمة المرور';
                                          }
                                          if (value.length < 6) {
                                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    FadeIn(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      delay: const Duration(milliseconds: 800),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: () {},
                                          child: Text(
                                            'نسيت كلمة المرور؟',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: AppColors.textGold,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    // Remember Me Toggle
                                    FadeInUp(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      delay: const Duration(milliseconds: 900),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.glassWhite,
                                              AppColors.glassWhite.withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'تذكر بياناتي',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            Transform.scale(
                                              scale: 0.85,
                                              child: Switch(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() => _rememberMe = value);
                                                },
                                                activeThumbColor: AppColors.primaryGold,
                                                activeTrackColor: AppColors.darkGold,
                                                inactiveThumbColor: AppColors.lightGray,
                                                inactiveTrackColor: AppColors.mediumGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 36),

                                    FadeInUp(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      delay: const Duration(milliseconds: 1000),
                                      child: GlassButton(
                                        text: 'تسجيل الدخول',
                                        onPressed: _handleLogin,
                                        isLoading: _isLoading,
                                        icon: Icons.login_rounded,
                                      ),
                                    ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
