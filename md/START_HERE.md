# 🎯 دليل سريع - البدء الفوري

## ✅ قائمة المراجعة السريعة (15 دقيقة)

### 📋 قبل البدء
- [ ] حاسوبك يعمل 24/7
- [ ] لديك حساب GitHub
- [ ] لديك حساب Cloudflare مع نفق مفعّل
- [ ] Flutter مثبت ويعمل

---

## 🚀 خطوات التنفيذ

### الخطوة 1️⃣: تحديث الروابط (3 دقائق)

**أ) تحديث رابط API:**
```dart
// في ملف: lib/services/api_service.dart
// غيّر السطر:
static const String baseUrl = 'http://localhost:3000';

// إلى:
static const String baseUrl = 'https://YOUR-SUBDOMAIN.example.com';
```

**ب) تحديث روابط GitHub:**
```dart
// في ملف: lib/services/update_service.dart
// غيّر:
https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/version.json

// إلى (مثال):
https://raw.githubusercontent.com/ahmed123/taif-management/main/version.json
```

### الخطوة 2️⃣: إنشاء أيقونة (5 دقائق)

**استخدم icon.kitchen:**
1. افتح https://icon.kitchen
2. اختر "Emoji" → ابحث عن 💰
3. لون الخلفية: `#D4AF37` (ذهبي)
4. تحميل كل الأحجام
5. ضعها في `assets/icon/`

**أو استخدم أيقونة جاهزة:**
```powershell
# سأنشئ لك أيقونة بسيطة:
mkdir assets\icon
# ثم ضع أي أيقونة ICO/PNG هنا
```

### الخطوة 3️⃣: البناء والتثبيت (5 دقائق)

**تشغيل السكريبت:**
```powershell
cd c:\code\my_system
.\build_and_deploy.ps1 -version "1.0.0" -buildNumber "1"
```

**أو يدوياً:**
```powershell
flutter clean
flutter pub get
flutter build windows --release
```

### الخطوة 4️⃣: إنشاء مثبت Inno Setup (2 دقيقة)

1. حمّل Inno Setup: https://jrsoftware.org/isdl.php
2. افتح ملف `installer.iss`
3. اضغط F9 أو Build → Compile
4. المثبت سيكون في: `Output\TaifManagement-Setup.exe`

### الخطوة 5️⃣: GitHub (3 دقائق)

```powershell
# إنشاء مستودع وإضافة الكود
git init
git add .
git commit -m "🚀 الإصدار الأول v1.0.0"

# ربط مع GitHub (بعد إنشاء repo على الموقع)
git remote add origin https://github.com/YOUR_USERNAME/taif-management.git
git branch -M main
git push -u origin main

# إنشاء release
git tag -a v1.0.0 -m "الإصدار 1.0.0"
git push --tags
```

**على موقع GitHub:**
1. اذهب لـ Releases → Create a new release
2. اختر tag: v1.0.0
3. عنوان: "إدارة الطيف v1.0.0 🎉"
4. ارفع ملف `TaifManagement-Setup.exe`
5. انشر الإصدار

### الخطوة 6️⃣: تحديث version.json (30 ثانية)

```json
{
  "version": "1.0.0",
  "build_number": 1,
  "download_url": "https://github.com/YOUR_USERNAME/taif-management/releases/download/v1.0.0/TaifManagement-Setup.exe",
  "changelog": "🎉 الإصدار الأول",
  "mandatory": false
}
```

```powershell
git add version.json
git commit -m "تحديث رابط التحميل"
git push
```

---

## 🏃‍♂️ اختبار سريع

```powershell
# 1. تشغيل البرنامج المبني
.\build\windows\runner\Release\my_system.exe

# 2. تجربة المثبت
.\Output\TaifManagement-Setup.exe

# 3. التحقق من التحديثات
# افتح البرنامج - سيفحص version.json تلقائياً
```

---

## 🎯 الأوامر المفيدة

### بناء سريع
```powershell
flutter build windows --release
```

### تشغيل مع Debug
```powershell
flutter run -d windows
```

### تحديث الحزم
```powershell
flutter pub upgrade
```

### تنظيف كامل
```powershell
flutter clean; flutter pub get; flutter build windows --release
```

---

## 📱 توزيع للموظفين

### الطريقة 1: رابط مباشر
```
أرسل رابط GitHub Release:
https://github.com/YOUR_USERNAME/taif-management/releases/latest
```

### الطريقة 2: Google Drive
1. ارفع `TaifManagement-Setup.exe` على Drive
2. اجعل الرابط "Anyone with the link"
3. أرسل الرابط المختصر

### الطريقة 3: WhatsApp
```
📥 حمّل برنامج إدارة الطيف
الإصدار: 1.0.0

🔗 رابط التحميل:
[الرابط هنا]

📋 خطوات التثبيت:
1. حمّل الملف
2. شغّل Setup.exe
3. اتبع التعليمات
4. افتح البرنامج
```

---

## 🐛 حل مشاكل سريع

### المشكلة: flutter command not found
```powershell
# أضف Flutter لـ PATH:
$env:Path += ";C:\flutter\bin"
```

### المشكلة: البناء يفشل
```powershell
flutter doctor -v
flutter clean
flutter pub get
```

### المشكلة: Inno Setup لا يعمل
- تأكد من تثبيت Inno Setup 6
- شغّل كـ Administrator
- تحقق من مسار الملفات في installer.iss

### المشكلة: التحديث لا يعمل
- تحقق من رابط version.json
- تأكد من أن الملف موجود على GitHub
- افتح الرابط في المتصفح للتأكد

---

## 🎉 خلصت!

بعد تنفيذ هذه الخطوات:
✅ البرنامج مبني ومثبت
✅ المثبت جاهز للتوزيع
✅ نظام التحديث التلقائي يعمل
✅ الكود محفوظ على GitHub

**الخطوة التالية:** وزّع المثبت على الموظفين! 🚀

---

## 📞 تذكير

إذا واجهت مشاكل:
1. راجع DEPLOYMENT_GUIDE.md للتفاصيل الكاملة
2. تحقق من ICON_GUIDE.md لمشاكل الأيقونة
3. اقرأ USER_GUIDE.md لأسئلة المستخدمين

**وقت التنفيذ الإجمالي:** 15-20 دقيقة ⏱️
