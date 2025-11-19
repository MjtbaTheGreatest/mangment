# 📦 دليل نشر "إدارة الطيف" خطوة بخطوة

## المرحلة 1: التحضير (10 دقائق)

### ✅ الخطوة 1: تحديث رابط API
في ملف `lib/services/api_service.dart`:

```dart
// غير من:
static const String baseUrl = 'http://127.0.0.1:53365/api';

// إلى (استبدل بـ subdomain الحقيقي):
static const String baseUrl = 'https://api.yoursite.com/api';
```

### ✅ الخطوة 2: اختبار الاتصال
```bash
# شغل API
cd my_system_api/bin
dart run server.dart

# شغل البرنامج واختبر
flutter run -d windows
```

تأكد:
- ✓ تسجيل الدخول يشتغل
- ✓ إضافة طلبات يشتغل
- ✓ التحاسبات تشتغل
- ✓ كل الميزات طبيعية

---

## المرحلة 2: إعداد GitHub (15 دقيقة)

### الخطوة 1: إنشاء Repository

1. **اذهب إلى:** https://github.com/new
2. **اسم Repository:** `taif-management`
3. **الوصف:** `نظام إدارة الطيف للطلبات والتحاسبات`
4. **النوع:** Private (خاص)
5. **اضغط:** Create repository

### الخطوة 2: رفع المشروع

```bash
# في مجلد المشروع
cd c:\code\my_system

# إضافة remote
git init
git remote add origin https://github.com/YOUR_USERNAME/taif-management.git

# إضافة الملفات
git add .
git commit -m "🎉 الإصدار الأول v1.0.0"

# رفع على GitHub
git branch -M main
git push -u origin main
```

### الخطوة 3: رفع ملف version.json

```bash
# تأكد أن الملف في المشروع
git add version.json
git commit -m "📝 إضافة ملف التحديثات"
git push
```

**عدل `version.json` وحدث:**
- اسم المستخدم
- اسم الـ repo
- رابط التحميل

**في ملف:** `lib/services/update_service.dart`
```dart
// غير:
static const String versionUrl = 
    'https://raw.githubusercontent.com/YOUR_USERNAME/taif-management/main/version.json';

static const String releasesUrl = 
    'https://github.com/YOUR_USERNAME/taif-management/releases/latest';
```

---

## المرحلة 3: بناء البرنامج (30 دقيقة)

### للويندوز:

```bash
# نظف البناء السابق
flutter clean

# حمل الحزم
flutter pub get

# ابني البرنامج
flutter build windows --release
```

**الملفات في:** `build\windows\runner\Release\`

#### إنشاء المثبت (Installer):

**الطريقة 1: باستخدام Inno Setup (موصى بها)**

1. **نزل Inno Setup:** https://jrsoftware.org/isdl.php
2. **ثبته وافتحه**
3. **اختر:** "Create a new script file using the Script Wizard"
4. **املأ المعلومات:**
   - اسم التطبيق: `إدارة الطيف`
   - الإصدار: `1.0.0`
   - الناشر: `اسمك`
   - الموقع: `https://yoursite.com`

5. **حدد المجلد:** `build\windows\runner\Release`
6. **اختر الملف الرئيسي:** `my_system.exe`
7. **اسم المجلد في البرامج:** `Taif Management`
8. **إنشاء اختصار:** سطح المكتب + قائمة ابدأ

9. **اضغط Compile**

**النتيجة:** `Output\TaifManagement-Setup.exe`

**الطريقة 2: يدوياً (للاختبار)**
- انسخ مجلد `Release` كامل
- اسمه `إدارة_الطيف_v1.0.0`
- اضغطه كـ ZIP

---

## المرحلة 4: رفع الإصدار على GitHub (10 دقائق)

### الخطوة 1: إنشاء Release

1. **اذهب إلى repository**
2. **اضغط "Releases"** (في الجانب الأيمن)
3. **اضغط "Create a new release"**

### الخطوة 2: ملء المعلومات

```
Tag version: v1.0.0
Release title: 🎉 إدارة الطيف v1.0.0 - الإصدار الأول

Description:
الإصدار الأول من نظام إدارة الطيف

✨ الميزات:
• إدارة شاملة للطلبات والعملاء
• نظام تحاسبات متطور للموظفين
• إحصائيات وتقارير تفصيلية
• إدارة رأس المال
• أرشفة تلقائية ذكية
• واجهة عصرية وسهلة الاستخدام

📥 التحميل:
حمل ملف Setup.exe وشغله، البرنامج يثبت تلقائياً

📖 طريقة التثبيت:
1. حمل TaifManagement-Setup.exe
2. شغل الملف
3. اضغط Next → Next → Install
4. خلاص! البرنامج جاهز

🔐 أول استخدام:
سجل دخول بحساب الأدمن:
• اسم المستخدم: admin
• كلمة المرور: admin123
```

### الخطوة 3: رفع الملف
- **اسحب** ملف `TaifManagement-Setup.exe`
- **أو اضغط** "Attach binaries"
- **انتظر** التحميل يخلص

### الخطوة 4: نشر
- **اضغط** "Publish release"

### الخطوة 5: نسخ الرابط
- **بعد النشر، انسخ رابط الملف**
- **مثال:** `https://github.com/username/repo/releases/download/v1.0.0/TaifManagement-Setup.exe`
- **ضعه في** `version.json` → `download_url`
- **احفظ وارفع** على GitHub

---

## المرحلة 5: إعداد السيرفر (20 دقيقة)

### الخطوة 1: تثبيت Cloudflare Tunnel

```bash
# نزل cloudflared
# من: https://github.com/cloudflare/cloudflared/releases

# لـ Windows:
# حمل cloudflared-windows-amd64.exe
# اسمه cloudflared.exe
# ضعه في: C:\cloudflared\

# تسجيل الدخول
cloudflared tunnel login

# إنشاء tunnel
cloudflared tunnel create taif-api

# ظهر Tunnel ID - احفظه!
```

### الخطوة 2: ربط Subdomain

```bash
# في Cloudflare Dashboard:
# 1. اذهب لموقعك
# 2. DNS → Add Record
# 3. Type: CNAME
# 4. Name: api
# 5. Target: [TUNNEL_ID].cfargotunnel.com
# 6. Proxy: Enabled (☁️)
# 7. Save
```

### الخطوة 3: إعداد Config

**أنشئ ملف:** `C:\cloudflared\config.yml`

```yaml
tunnel: [TUNNEL_ID]
credentials-file: C:\cloudflared\[TUNNEL_ID].json

ingress:
  - hostname: api.yoursite.com
    service: http://localhost:53365
  - service: http_status:404
```

### الخطوة 4: تشغيل Tunnel كخدمة

```bash
# تثبيت الخدمة
cloudflared service install

# تشغيل
cloudflared service start

# فحص الحالة
cloudflared service status
```

**اختبار:**
```bash
# افتح المتصفح
https://api.yoursite.com/api/health

# لازم يرجع: OK
```

---

## المرحلة 6: تشغيل API كخدمة (15 دقيقة)

### باستخدام NSSM (Windows):

**الخطوة 1: تحميل NSSM**
- https://nssm.cc/download
- حمل `nssm-2.24.zip`
- فك الضغط

**الخطوة 2: تثبيت الخدمة**

```bash
# افتح CMD كـ Administrator
cd C:\path\to\nssm-2.24\win64

# تثبيت الخدمة
nssm install TaifAPI

# في النافذة اللي تطلع:
# Path: C:\path\to\dart-sdk\bin\dart.exe
# Startup directory: C:\code\my_system\my_system_api\bin
# Arguments: run server.dart

# اضغط Install service
```

**الخطوة 3: تشغيل الخدمة**

```bash
# تشغيل
nssm start TaifAPI

# فحص
nssm status TaifAPI

# إيقاف
nssm stop TaifAPI

# إعادة تشغيل
nssm restart TaifAPI
```

**الخطوة 4: جعلها تشتغل تلقائياً**
```bash
# في services.msc
# ابحث عن TaifAPI
# Properties → Startup type → Automatic
# Apply → OK
```

---

## المرحلة 7: توزيع البرنامج (5 دقائق)

### الطريقة 1: Google Drive

```
1. ارفع TaifManagement-Setup.exe على Drive
2. اعمل رابط مشاركة (Anyone with the link)
3. انسخ الرابط
4. أرسله للموظفين على WhatsApp
```

**رسالة مقترحة:**

```
السلام عليكم 👋

تم تجهيز برنامج إدارة الطيف! 🎉

📥 للتحميل:
[رابط Google Drive]

📖 خطوات التثبيت:
1️⃣ افتح الرابط وحمل الملف
2️⃣ شغل الملف اللي نزل
3️⃣ اضغط Next ثلاث مرات
4️⃣ خلاص! البرنامج يشتغل

🔑 تسجيل الدخول:
استخدم اسم المستخدم وكلمة المرور اللي أعطيتك إياها

❓ أي مشكلة راسلني
```

### الطريقة 2: مباشرة من GitHub

```
1. شارك رابط Release مباشرة
2. الموظف يضغط على TaifManagement-Setup.exe
3. يحمل ويثبت
```

---

## المرحلة 8: المراقبة والصيانة

### إعداد مراقب الأداء

**1. Uptime Robot (مجاني)**
- https://uptimerobot.com
- أنشئ حساب
- أضف Monitor:
  - Type: HTTP(s)
  - URL: https://api.yoursite.com/api/health
  - Interval: كل 5 دقائق
  - Alert: أرسل email إذا توقف

**2. فحص Logs**
```bash
# في مجلد API
type database.db.log

# أو إذا مافيه log، أضف:
# في server.dart
print('[${DateTime.now()}] API Request: $method $path');
```

### النسخ الاحتياطي

**يدوياً:**
```bash
# كل يوم، انسخ database.db
copy C:\code\my_system\my_system_api\bin\database.db D:\Backups\db_backup_[DATE].db
```

**تلقائياً (Windows Task Scheduler):**
```bash
# أنشئ ملف backup.bat:
@echo off
set timestamp=%date:~-4,4%%date:~-10,2%%date:~-7,2%
copy "C:\code\my_system\my_system_api\bin\database.db" "D:\Backups\db_%timestamp%.db"

# في Task Scheduler:
# Create Basic Task
# Trigger: Daily, 2:00 AM
# Action: Start a program
# Program: C:\path\to\backup.bat
```

---

## المرحلة 9: التحديثات المستقبلية

### عند إصدار نسخة جديدة:

**1. عدل الإصدار**
```yaml
# في pubspec.yaml
version: 1.0.1+2  # رقم الإصدار + رقم البناء
```

**2. ابني البرنامج**
```bash
flutter build windows --release
```

**3. أنشئ المثبت**
```
# باستخدام Inno Setup
# غير رقم الإصدار إلى 1.0.1
```

**4. أنشئ Release جديد على GitHub**
```
Tag: v1.0.1
Title: إدارة الطيف v1.0.1 - تحديث صغير
Description: [ما الجديد]
Attach: TaifManagement-Setup-v1.0.1.exe
```

**5. حدث version.json**
```json
{
  "version": "1.0.1",
  "build_number": 2,
  "download_url": "[رابط الملف الجديد]",
  "changelog": "[التغييرات]",
  "mandatory": false
}
```

**6. ارفع على GitHub**
```bash
git add version.json
git commit -m "📝 تحديث إلى v1.0.1"
git push
```

**🎉 خلاص!**
- الموظفين عند فتح البرنامج → يشوفون رسالة تحديث
- يضغطون تحميل → ينزل النسخة الجديدة
- يثبتون → ويكملون شغل!

---

## ✅ Checklist النهائي

قبل ما تعطي الموظفين، تأكد:

- [ ] API يشتغل 24/7 (Cloudflare Tunnel + NSSM)
- [ ] Subdomain يرد على الطلبات
- [ ] البرنامج يتصل بالسيرفر الحقيقي
- [ ] التحديث التلقائي يشتغل
- [ ] الأيقونة موجودة
- [ ] المثبت يشتغل صح
- [ ] الملف على GitHub Releases
- [ ] version.json صحيح
- [ ] رابط التحميل يشتغل
- [ ] النسخة الاحتياطية مضبوطة
- [ ] Uptime monitoring شغال
- [ ] حسابات الموظفين جاهزة

---

## 🆘 المشاكل الشائعة وحلولها

### 1. "Cannot connect to server"
**الحل:**
```bash
# تأكد API شغال
cd my_system_api/bin
dart run server.dart

# تأكد Cloudflare Tunnel شغال
cloudflared service status
```

### 2. "Update check failed"
**الحل:**
- تأكد version.json على GitHub
- تأكد الرابط صحيح في update_service.dart
- تأكد Repository عام أو الملف Public

### 3. "Setup.exe not working"
**الحل:**
- أعد إنشاء المثبت بـ Inno Setup
- تأكد كل ملفات DLL موجودة
- شغل Build نظيف: `flutter clean && flutter build windows`

### 4. "Icon not showing"
**الحل:**
- تأكد ملف .ico في المكان الصحيح
- أعد بناء البرنامج
- نظف الكاش: `flutter clean`

---

## 📞 الدعم

إذا عندك أي مشكلة:
1. تأكد من الخطوات أعلاه
2. فحص ال Logs
3. جرب إعادة التشغيل
4. واتساب/تيليجرام: [رقمك]

---

**🎉 مبروك! برنامجك الآن جاهز للاستخدام الحقيقي!**
