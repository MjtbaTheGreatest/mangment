# ❓ الأسئلة الشائعة (FAQ)

## 🚀 التشغيل والإعداد

### س: كيف أبدأ المشروع؟
```bash
flutter pub get
flutter run
```

### س: ما هي متطلبات التشغيل؟
- Flutter SDK 3.9.2 أو أحدث
- Dart 3.9.2 أو أحدث
- محرر نصوص (VS Code / Android Studio)

### س: الخط العربي لا يظهر بشكل صحيح
**الحل:**
```bash
flutter clean
flutter pub get
flutter run
```
الخط يُحمّل تلقائياً من google_fonts، تأكد من وجود اتصال بالإنترنت في أول تشغيل.

---

## 🎨 التصميم والألوان

### س: كيف أغير اللون الذهبي إلى لون آخر؟
**الجواب:** افتح `lib/styles/app_colors.dart` وعدّل:
```dart
static const Color primaryGold = Color(0xFFYOURCOLOR);
```

### س: كيف أغير الخط إلى خط آخر؟
**الجواب:** في `lib/styles/app_text_styles.dart`:
```dart
// بدلاً من:
GoogleFonts.tajawal(...)
// استخدم:
GoogleFonts.cairo(...) // أو أي خط آخر
```

### س: التطبيق يظهر بالإنجليزية بدلاً من العربية
**الحل:** تأكد من وجود:
```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: ...
)
```

---

## 🖼️ الصور والموارد

### س: رسالة خطأ: "asset_does_not_exist"
**الحل:** هذا طبيعي، فقط:
1. أضف صورة باسم `background.jpg` في `assets/images/`
2. أو علّق سطر الصورة في `pubspec.yaml`
3. أو احذف كود الصورة من `login_screen.dart`

### س: كيف أضيف صوراً أخرى؟
**الجواب:**
1. ضع الصورة في `assets/images/`
2. أضفها في `pubspec.yaml`:
```yaml
assets:
  - assets/images/your_image.png
```
3. استخدمها:
```dart
Image.asset('assets/images/your_image.png')
```

---

## 🔧 التعديل والتخصيص

### س: كيف أضيف حقل نص جديد؟
**الجواب:**
```dart
GlassTextField(
  controller: _myController,
  label: 'العنوان',
  hint: 'أدخل البيانات',
  icon: Icons.your_icon,
)
```

### س: كيف أغير نص الزر؟
**الجواب:**
```dart
GlassButton(
  text: 'النص الجديد',
  onPressed: () {},
)
```

### س: كيف أضيف صفحة جديدة؟
**الجواب:**
1. أنشئ ملف في `lib/screens/new_screen.dart`
2. انسخ هيكل `login_screen.dart`
3. عدّل المحتوى
4. انتقل إليها:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
)
```

---

## ⚠️ الأخطاء الشائعة

### س: خطأ: "package:google_fonts not found"
**الحل:**
```bash
flutter clean
flutter pub get
```

### س: خطأ: "package:animate_do not found"
**الحل:**
```bash
flutter pub add animate_do
flutter pub get
```

### س: الأنيميشنات لا تعمل
**الحل:**
- تأكد من استيراد: `import 'package:animate_do/animate_do.dart';`
- تأكد من وجود الحزمة في `pubspec.yaml`

### س: النص مقطوع أو غير واضح
**الحل:**
- أضف `Directionality` للنص العربي
- تأكد من حجم الخط مناسب
- استخدم `Expanded` أو `Flexible` للنصوص الطويلة

---

## 📱 البناء والنشر

### س: كيف أبني APK للأندرويد؟
```bash
flutter build apk --release
```
الملف في: `build/app/outputs/flutter-apk/app-release.apk`

### س: كيف أبني للآيفون؟
```bash
flutter build ios --release
```
(يتطلب Mac + Xcode)

### س: كيف أبني للويب؟
```bash
flutter build web --release
```
الملفات في: `build/web/`

### س: كيف أبني لويندوز؟
```bash
flutter build windows --release
```
الملف في: `build/windows/runner/Release/`

---

## 🎯 الأداء

### س: التطبيق بطيء
**الحلول:**
1. استخدم `const` حيثما أمكن
2. قلل الأنيميشنات المعقدة
3. استخدم `flutter run --release` للاختبار

### س: الأنيميشنات متقطعة
**الحل:**
- اختبر في وضع release لا debug
- قلل مدة الأنيميشن
- قلل عدد blur effects المتداخلة

---

## 🔐 الأمان

### س: هل كلمة المرور آمنة؟
**ملاحظة:** هذا مشروع تعليمي. في التطبيقات الحقيقية:
- استخدم HTTPS
- شفّر كلمة المرور
- استخدم Authentication services
- لا تحفظ كلمة المرور في الكود

### س: كيف أضيف تسجيل دخول حقيقي؟
**خيارات:**
- Firebase Authentication
- REST API مع backend
- OAuth (Google, Facebook, etc.)

---

## 🌍 التوطين (Localization)

### س: كيف أضيف دعم الإنجليزية؟
**الجواب:**
1. أضف حزمة: `flutter_localizations`
2. أنشئ ملفات الترجمة
3. استخدم `AppLocalizations`

أو ببساطة:
- أنشئ ملف `strings.dart`:
```dart
class Strings {
  static Map<String, String> ar = {
    'welcome': 'أهلاً بعودتك',
  };
  
  static Map<String, String> en = {
    'welcome': 'Welcome back',
  };
}
```

---

## 🔄 التحديثات

### س: كيف أحدث الحزم؟
```bash
flutter pub upgrade
```

### س: كيف أحدث Flutter نفسه؟
```bash
flutter upgrade
```

---

## 💾 حفظ البيانات

### س: كيف أحفظ بيانات المستخدم؟
**خيارات:**
- `shared_preferences` (للبيانات البسيطة)
- `sqflite` (قاعدة بيانات محلية)
- `hive` (سريع ومحلي)
- Firebase Firestore (سحابي)

**مثال مع shared_preferences:**
```dart
// أضف الحزمة أولاً
flutter pub add shared_preferences

// استخدم:
final prefs = await SharedPreferences.getInstance();
await prefs.setString('username', 'محمد');
String? username = prefs.getString('username');
```

---

## 🧪 الاختبار

### س: كيف أختبر التطبيق؟
```bash
flutter test
```

### س: كيف أنشئ unit tests؟
**الجواب:** أنشئ ملف في `test/`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_system/utils/validators.dart';

void main() {
  test('Username validator', () {
    expect(Validators.validateUsername('ab'), isNotNull);
    expect(Validators.validateUsername('abc'), isNull);
  });
}
```

---

## 🎨 التعديلات الشائعة

### س: كيف أجعل الزر مربعاً؟
```dart
// في glass_button.dart، غيّر:
borderRadius: BorderRadius.circular(16),
// إلى:
borderRadius: BorderRadius.circular(8),
```

### س: كيف أغير حجم الشعار؟
```dart
// في login_screen.dart، غيّر:
width: 100,
height: 100,
// إلى الحجم المطلوب
```

### س: كيف أخفي زر "إنشاء حساب"؟
```dart
// في login_screen.dart، احذف أو علّق:
FadeIn(
  // ... كود الزر
),
```

---

## 🆘 المساعدة

### س: أين أجد المساعدة؟
- **Flutter Docs:** [flutter.dev/docs](https://flutter.dev/docs)
- **Stack Overflow:** [stackoverflow.com/questions/tagged/flutter](https://stackoverflow.com/questions/tagged/flutter)
- **GitHub Issues:** ضع مشكلتك في المشروع

### س: كيف أبلغ عن مشكلة؟
1. تأكد من تشغيل `flutter doctor`
2. احفظ رسالة الخطأ كاملة
3. اشرح الخطوات لإعادة إنتاج المشكلة

---

## 💡 نصائح إضافية

### ⚡ الأداء:
- استخدم `const` للwidgets الثابتة
- تجنب `setState()` الزائد
- استخدم `ListView.builder` للقوائم الطويلة

### 🎨 التصميم:
- حافظ على التناسق في الألوان
- استخدم المسافات بشكل متسق
- لا تبالغ في الأنيميشنات

### 📱 التوافق:
- اختبر على أجهزة مختلفة
- استخدم `MediaQuery` للأحجام
- اختبر في orientations مختلفة

---

## 🎓 التعلم المتقدم

### للخطوة التالية:
1. **State Management:** Provider, Riverpod, Bloc
2. **Backend Integration:** REST API, GraphQL
3. **Database:** Firebase, Supabase
4. **Testing:** Unit, Widget, Integration tests
5. **CI/CD:** GitHub Actions, Codemagic

---

## 📚 موارد مفيدة

- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Pub.dev](https://pub.dev) - حزم Flutter
- [Flutter Community](https://flutter.dev/community)

---

💡 **هل لديك سؤال غير موجود؟**  
أضفه هنا وسنجيب عليه! 🎉
