# 🚀 دليل التشغيل السريع

## الخطوة 1: التحقق من متطلبات التشغيل

```bash
flutter doctor
```

## الخطوة 2: تثبيت الحزم

```bash
flutter pub get
```

## الخطوة 3: إضافة صورة الخلفية ⚠️ مهم!

1. ابحث عن صورة خلفية فخمة (يفضل بألوان داكنة)
2. سمّها `background.jpg`
3. ضعها في المجلد: `assets/images/background.jpg`

### بدائل إذا لم يكن لديك صورة:

يمكنك تعديل ملف `lib/screens/login_screen.dart` وحذف أو تعليق سطر الصورة:

```dart
// احذف أو علّق هذا الجزء مؤقتاً:
image: const DecorationImage(
  image: AssetImage('assets/images/background.jpg'),
  fit: BoxFit.cover,
  opacity: 0.15,
),
```

## الخطوة 4: التشغيل

### Android:
```bash
flutter run
```

### Windows:
```bash
flutter run -d windows
```

### Web:
```bash
flutter run -d chrome
```

### iOS (Mac فقط):
```bash
flutter run -d ios
```

## 🎯 اختبار التطبيق

1. قم بكتابة أي اسم مستخدم (3 أحرف على الأقل)
2. قم بكتابة أي كلمة مرور (6 أحرف على الأقل)
3. جرّب إظهار/إخفاء كلمة المرور عن طريق الضغط على أيقونة العين
4. اضغط على زر "تسجيل الدخول"

## 🐛 حل المشاكل الشائعة

### مشكلة: خطأ في تحميل الخط Tajawal

**الحل:**
```bash
flutter clean
flutter pub get
flutter run
```

### مشكلة: الخلفية لا تظهر

**الحل:**
- تأكد من وجود الصورة في المسار الصحيح
- أو احذف كود الصورة من `login_screen.dart`

### مشكلة: الأنيميشنات لا تعمل

**الحل:**
```bash
flutter pub upgrade
flutter pub get
```

### مشكلة: النص العربي يظهر معكوساً

**الحل:** تأكد من وجود:
```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: ...
)
```

## 📱 التشغيل على أجهزة مختلفة

### Android Physical Device:
1. فعّل USB Debugging
2. صِل الجهاز بالكمبيوتر
3. قم بتشغيل: `flutter run`

### iOS Physical Device (Mac فقط):
1. افتح Xcode
2. سجّل حساب Apple Developer
3. قم بتشغيل: `flutter run`

### Windows Desktop:
```bash
flutter config --enable-windows-desktop
flutter run -d windows
```

## 🎨 التخصيص السريع

### تغيير اللون الذهبي:
افتح `lib/styles/app_colors.dart` وعدّل:
```dart
static const Color primaryGold = Color(0xFFFFD700);
```

### تغيير الخط:
افتح `lib/styles/app_text_styles.dart` وغيّر:
```dart
GoogleFonts.tajawal(...)
```
إلى أي خط آخر متاح في google_fonts

### إضافة صفحة جديدة:
1. أنشئ ملف في `lib/screens/`
2. انسخ هيكل `login_screen.dart`
3. عدّل المحتوى حسب حاجتك

## 💾 البناء للإصدار

### Android APK:
```bash
flutter build apk --release
```
الملف سيكون في: `build/app/outputs/flutter-apk/app-release.apk`

### Windows:
```bash
flutter build windows --release
```
الملف سيكون في: `build/windows/runner/Release/`

### Web:
```bash
flutter build web --release
```
الملفات ستكون في: `build/web/`

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تأكد من أن Flutter محدث: `flutter upgrade`
2. نظّف المشروع: `flutter clean`
3. أعد تثبيت الحزم: `flutter pub get`

---

🎉 استمتع بالتطبيق الفخم!
