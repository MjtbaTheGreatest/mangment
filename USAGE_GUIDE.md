# 📖 دليل الاستخدام

## كيفية استخدام المكونات المخصصة

### 1️⃣ GlassTextField - حقل النص الزجاجي

```dart
import 'package:my_system/widgets/glass_text_field.dart';

// استخدام بسيط
GlassTextField(
  controller: _usernameController,
  label: 'اسم المستخدم',
  hint: 'أدخل اسم المستخدم',
  icon: Icons.person_rounded,
)

// حقل كلمة مرور
GlassTextField(
  controller: _passwordController,
  label: 'كلمة المرور',
  hint: 'أدخل كلمة المرور',
  icon: Icons.lock_rounded,
  isPassword: true,
  validator: Validators.validatePassword,
)

// حقل بريد إلكتروني
GlassTextField(
  controller: _emailController,
  label: 'البريد الإلكتروني',
  hint: 'example@domain.com',
  icon: Icons.email_rounded,
  keyboardType: TextInputType.emailAddress,
  validator: Validators.validateEmail,
)
```

### 2️⃣ GlassButton - الزر الفخم

```dart
import 'package:my_system/widgets/glass_button.dart';

// زر بسيط
GlassButton(
  text: 'تسجيل الدخول',
  onPressed: _handleLogin,
)

// زر مع أيقونة
GlassButton(
  text: 'تسجيل الدخول',
  onPressed: _handleLogin,
  icon: Icons.login_rounded,
)

// زر مع تحميل
GlassButton(
  text: 'تسجيل الدخول',
  onPressed: _handleLogin,
  isLoading: _isLoading,
)
```

### 3️⃣ استخدام الألوان

```dart
import 'package:my_system/styles/app_colors.dart';

Container(
  decoration: BoxDecoration(
    gradient: AppColors.goldGradient, // تدرج ذهبي
    borderRadius: BorderRadius.circular(16),
  ),
)

Text(
  'نص ذهبي',
  style: TextStyle(color: AppColors.textGold),
)
```

### 4️⃣ استخدام أنماط النصوص

```dart
import 'package:my_system/styles/app_text_styles.dart';

Text('عنوان كبير', style: AppTextStyles.headlineLarge)
Text('عنوان متوسط', style: AppTextStyles.headlineMedium)
Text('نص عادي', style: AppTextStyles.bodyMedium)
Text('نص صغير', style: AppTextStyles.caption)
```

### 5️⃣ استخدام الأنيميشنات

```dart
import 'package:animate_do/animate_do.dart';

// ظهور من الأعلى
FadeInDown(
  duration: Duration(milliseconds: 800),
  child: YourWidget(),
)

// ظهور من الأسفل
FadeInUp(
  duration: Duration(milliseconds: 800),
  delay: Duration(milliseconds: 200),
  child: YourWidget(),
)

// ظهور من اليمين
FadeInRight(
  duration: Duration(milliseconds: 600),
  child: YourWidget(),
)

// ظهور من اليسار
FadeInLeft(
  duration: Duration(milliseconds: 600),
  child: YourWidget(),
)

// ظهور بسيط
FadeIn(
  duration: Duration(milliseconds: 800),
  child: YourWidget(),
)
```

### 6️⃣ استخدام التحقق من المدخلات

```dart
import 'package:my_system/utils/validators.dart';

TextFormField(
  validator: Validators.validateUsername,
)

TextFormField(
  validator: Validators.validatePassword,
)

TextFormField(
  validator: Validators.validateEmail,
)

TextFormField(
  validator: (value) => Validators.validatePasswordMatch(
    value,
    _passwordController.text,
  ),
)
```

### 7️⃣ إنشاء تأثير زجاجي مخصص

```dart
import 'dart:ui';

Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: AppColors.glassWhite,
      width: 1.5,
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.glassWhite,
              AppColors.glassWhite.withOpacity(0.5),
            ],
          ),
        ),
        child: YourContent(),
      ),
    ),
  ),
)
```

## 💡 نصائح

1. **الاتجاه (RTL):** تأكد من استخدام `Directionality(textDirection: TextDirection.rtl)` للواجهة العربية

2. **الأنيميشنات:** استخدم `delay` لترتيب ظهور العناصر

3. **الألوان:** استخدم التدرجات بدلاً من الألوان الثابتة للحصول على مظهر فخم

4. **التباعد:** استخدم الثوابت من `AppConstants` للحفاظ على تناسق التصميم

5. **التحقق:** دائماً استخدم `GlobalKey<FormState>` مع `Form` للتحقق من المدخلات

## 🎨 مثال شامل لصفحة جديدة

```dart
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../widgets/glass_button.dart';

class NewScreen extends StatelessWidget {
  const NewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  FadeInDown(
                    child: Text(
                      'صفحة جديدة',
                      style: AppTextStyles.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: GlassButton(
                      text: 'زر فخم',
                      onPressed: () {},
                      icon: Icons.star_rounded,
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
}
```
