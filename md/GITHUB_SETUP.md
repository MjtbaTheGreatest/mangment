# 📝 خطوات إنشاء GitHub Repository

## ✅ ما تم حتى الآن:
- ✅ Git repository مهيأ
- ✅ جميع الملفات في commit
- ✅ Tag v1.0.0 تم إنشاؤه
- ✅ صفحة GitHub مفتوحة

---

## 🌐 الآن على موقع GitHub:

### 1️⃣ املأ المعلومات التالية:

**Repository name:** 
```
taif-management
```

**Description:** 
```
إدارة الطيف - نظام إدارة الطلبات والتحاسبات | Taif Management System
```

**Visibility:**
- ✅ **Private** (موصى به إذا تبي تحمي الكود)
- أو **Public** (إذا ما عندك مشكلة)

**لا تختار:**
- ❌ Add a README file
- ❌ Add .gitignore
- ❌ Choose a license

(عندنا هذي الملفات جاهزة)

### 2️⃣ اضغط "Create repository"

---

## 💻 بعد إنشاء الـ Repository - نفذ هذه الأوامر:

```powershell
# استبدل YOUR_USERNAME باسم حسابك على GitHub
git remote add origin https://github.com/YOUR_USERNAME/taif-management.git

# رفع الكود
git branch -M main
git push -u origin main

# رفع الـ tags
git push --tags
```

---

## 📦 بعدها: إنشاء Release

بعد رفع الكود، سويت Release:

```powershell
# على موقع GitHub:
# 1. اذهب لـ: https://github.com/YOUR_USERNAME/taif-management/releases
# 2. اضغط "Create a new release"
# 3. اختر tag: v1.0.0
# 4. Release title: "إدارة الطيف v1.0.0 🎉"
# 5. ارفع ملف: Output\TaifManagement-Setup.exe
# 6. اضغط "Publish release"
```

---

## 🔄 تحديث روابط البرنامج

بعد نشر الـ Release، حدّث الروابط في:

**1. version.json:**
```json
{
  "download_url": "https://github.com/YOUR_USERNAME/taif-management/releases/download/v1.0.0/TaifManagement-Setup.exe"
}
```

**2. lib/services/update_service.dart:**
```dart
static const String versionUrl = 
  'https://raw.githubusercontent.com/YOUR_USERNAME/taif-management/main/version.json';
```

**3. ارفع التحديثات:**
```powershell
git add version.json lib/services/update_service.dart
git commit -m "تحديث روابط التحميل والتحديثات"
git push
```

---

## ⏭️ الخطوة التالية

بعد انتهاء GitHub:
- إعداد Cloudflare Tunnel
- تحديث رابط API
- تشغيل Backend كـ Windows Service

**جاهز؟ بعد ما تنشئ الـ repo، أعطيني اسم المستخدم عشان نكمل!** 🚀
