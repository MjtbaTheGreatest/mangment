# 🚀 البدء السريع - إدارة الطيف

## ⚡ الخطوات الأساسية (5 دقائق)

### 1️⃣ تحديث رابط API

**افتح:** `lib/services/api_service.dart`

**غير السطر 8 من:**
```dart
static const String baseUrl = 'http://127.0.0.1:53365/api';
```

**إلى (استبدل yoursite.com بالدومين الحقيقي):**
```dart
static const String baseUrl = 'https://api.yoursite.com/api';
```

---

### 2️⃣ تحديث روابط GitHub

**افتح:** `lib/services/update_service.dart`

**غير السطر 9-10 (استبدل YOUR_USERNAME و YOUR_REPO):**
```dart
static const String versionUrl = 
    'https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/version.json';

static const String releasesUrl = 
    'https://github.com/YOUR_USERNAME/YOUR_REPO/releases/latest';
```

---

### 3️⃣ تحميل الحزم
```bash
flutter pub get
```

---

### 4️⃣ اختبار البرنامج
```bash
# شغل API أولاً
cd my_system_api/bin
dart run server.dart

# في terminal آخر - شغل البرنامج
cd ../..
flutter run -d windows
```

---

### 5️⃣ بناء النسخة النهائية
```bash
flutter clean
flutter build windows --release
```

**الملفات في:** `build\windows\runner\Release\`

---

## 📦 إنشاء المثبت

### باستخدام Inno Setup:

1. **نزل Inno Setup:** https://jrsoftware.org/isdl.php
2. **افتح Inno Setup Compiler**
3. **File → New**
4. **اتبع المعالج:**
   - App name: `إدارة الطيف`
   - Version: `1.0.0`
   - Company: `اسمك`
   - App folder: `build\windows\runner\Release`
   - Main executable: `my_system.exe`
   - Output folder: `Output`
   - Output filename: `TaifManagement-Setup`

5. **Build → Compile**

**النتيجة:** `Output\TaifManagement-Setup.exe`

---

## 🌐 رفع على GitHub

```bash
# إنشاء repo جديد على GitHub أولاً
# ثم:

git init
git add .
git commit -m "🎉 الإصدار الأول v1.0.0"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

---

## 📤 إنشاء Release

1. **اذهب لـ GitHub → Releases**
2. **Create new release**
3. **Tag:** `v1.0.0`
4. **Title:** `🎉 إدارة الطيف v1.0.0`
5. **Description:** انسخ من DEPLOYMENT_GUIDE.md
6. **Upload:** `TaifManagement-Setup.exe`
7. **Publish**

---

## 🔗 تحديث روابط التحميل

بعد رفع Release:

1. **انسخ رابط الملف**
2. **افتح:** `version.json`
3. **حدث:** `download_url`
4. **احفظ وارفع:**
```bash
git add version.json
git commit -m "📝 تحديث رابط التحميل"
git push
```

---

## ✅ التحقق النهائي

- [ ] API يشتغل على `localhost:53365`
- [ ] Cloudflare Tunnel مربوط
- [ ] Subdomain يستجيب
- [ ] البرنامج يتصل بالسيرفر
- [ ] التحديث التلقائي يشتغل
- [ ] المثبت جاهز
- [ ] Release على GitHub
- [ ] version.json محدث

---

## 🎯 الخطوة التالية

**اقرأ:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) للتفاصيل الكاملة

**أو شغل مباشرة:**
```bash
# 1. شغل API
cd my_system_api/bin
dart run server.dart

# 2. في terminal جديد - شغل البرنامج
cd ../../
flutter run -d windows
```

---

## 🆘 مشاكل؟

**خطأ في البناء:**
```bash
flutter clean
flutter pub get
flutter build windows --release
```

**خطأ في الاتصال:**
- تأكد API شغال
- تأكد الرابط صحيح في api_service.dart

**التحديث ما يشتغل:**
- تأكد version.json على GitHub
- تأكد الروابط صحيحة في update_service.dart

---

**🎉 يالله انطلق!**
