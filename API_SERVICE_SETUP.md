# 🚀 دليل إعداد Backend API كخدمة دائمة

## ✅ الحالة الحالية:
- ✅ API يشتغل على المنفذ: **53365**
- ✅ قاعدة البيانات: database.db
- ✅ الدومين: admin.taif.digital
- ⏳ يحتاج تشغيل دائم كـ Windows Service

---

## 📋 الطريقة 1: استخدام NSSM (موصى به)

### 1️⃣ تحميل NSSM
```powershell
# تحميل NSSM (Non-Sucking Service Manager)
winget install nssm
```

### 2️⃣ إنشاء الخدمة
```powershell
cd C:\code\my_system\my_system_api

# إنشاء الخدمة
nssm install TaifManagementAPI dart "run bin/server.dart"

# تحديد مجلد العمل
nssm set TaifManagementAPI AppDirectory "C:\code\my_system\my_system_api"

# تشغيل تلقائي عند بدء Windows
nssm set TaifManagementAPI Start SERVICE_AUTO_START

# وصف الخدمة
nssm set TaifManagementAPI Description "إدارة الطيف - Backend API Server"

# إعادة التشغيل التلقائي عند الفشل
nssm set TaifManagementAPI AppRestartDelay 5000
```

### 3️⃣ تشغيل الخدمة
```powershell
# بدء الخدمة
nssm start TaifManagementAPI

# التحقق من الحالة
nssm status TaifManagementAPI
```

### 4️⃣ إيقاف/حذف الخدمة (إذا احتجت)
```powershell
# إيقاف
nssm stop TaifManagementAPI

# حذف
nssm remove TaifManagementAPI confirm
```

---

## 📋 الطريقة 2: PowerShell كـ Startup Task

### إنشاء سكريبت بدء التشغيل:

**ملف: start_api.ps1**
```powershell
# تشغيل API تلقائياً
cd C:\code\my_system\my_system_api
dart run bin\server.dart
```

### إضافة لبدء التشغيل:
```powershell
# نسخ السكريبت لمجلد Startup
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
Copy-Item "start_api.ps1" $startupFolder

# أو إنشاء Scheduled Task
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\code\my_system\my_system_api\start_api.ps1"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "TaifManagementAPI" -Action $action -Trigger $trigger -RunLevel Highest
```

---

## 🌐 الطريقة 3: Docker (احترافي)

### 1️⃣ إنشاء Dockerfile:
```dockerfile
FROM dart:stable

WORKDIR /app
COPY . .

RUN dart pub get

EXPOSE 53365

CMD ["dart", "run", "bin/server.dart"]
```

### 2️⃣ بناء وتشغيل:
```powershell
docker build -t taif-api .
docker run -d --name taif-api -p 53365:53365 --restart always taif-api
```

---

## 🔥 إعداد Cloudflare Tunnel

### 1️⃣ تسجيل الدخول:
```powershell
cloudflared tunnel login
```

### 2️⃣ إنشاء Tunnel جديد:
```powershell
cloudflared tunnel create taif-api

# سيعطيك Tunnel ID - احفظه!
```

### 3️⃣ ربط بالدومين:
```powershell
cloudflared tunnel route dns taif-api admin.taif.digital
```

### 4️⃣ إنشاء ملف config:
**ملف: C:\Users\shams\.cloudflared\config.yml**
```yaml
tunnel: YOUR_TUNNEL_ID
credentials-file: C:\Users\shams\.cloudflared\YOUR_TUNNEL_ID.json

ingress:
  - hostname: admin.taif.digital
    service: http://localhost:53365
  - service: http_status:404
```

### 5️⃣ تشغيل Tunnel كخدمة:
```powershell
# تثبيت كخدمة Windows
cloudflared service install

# تشغيل
cloudflared service start
```

---

## ✅ التحقق من التشغيل

### اختبار محلي:
```powershell
# اختبار API محلياً
Invoke-WebRequest -Uri "http://localhost:53365/health" -Method GET

# أو في المتصفح:
Start-Process "http://localhost:53365"
```

### اختبار عبر الدومين:
```powershell
# بعد إعداد Cloudflare Tunnel
Invoke-WebRequest -Uri "https://admin.taif.digital/health" -Method GET

# في المتصفح:
Start-Process "https://admin.taif.digital"
```

---

## 🔧 تحديث API URL في التطبيق

بعد تشغيل Cloudflare Tunnel:

**ملف: lib/services/api_service.dart**
```dart
static const String baseUrl = 'https://admin.taif.digital';
```

ثم أعد البناء:
```powershell
cd C:\code\my_system
flutter build windows --release
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" installer.iss
```

---

## 📊 مراقبة الخدمة

### NSSM:
```powershell
# عرض logs
nssm status TaifManagementAPI

# إعادة التشغيل
nssm restart TaifManagementAPI
```

### Windows Services:
```powershell
# فتح Services Manager
services.msc

# أو PowerShell:
Get-Service TaifManagementAPI
Restart-Service TaifManagementAPI
```

---

## 🎯 الخطوات السريعة (5 دقائق):

```powershell
# 1. تحميل NSSM
winget install nssm

# 2. إنشاء الخدمة
cd C:\code\my_system\my_system_api
nssm install TaifManagementAPI dart "run bin/server.dart"
nssm set TaifManagementAPI AppDirectory "C:\code\my_system\my_system_api"
nssm start TaifManagementAPI

# 3. إعداد Cloudflare Tunnel
cloudflared tunnel login
cloudflared tunnel create taif-api
cloudflared tunnel route dns taif-api admin.taif.digital
# (أنشئ config.yml كما في الأعلى)
cloudflared service install

# 4. اختبار
Start-Process "https://admin.taif.digital"
```

---

## ⚠️ ملاحظات مهمة:

1. **Cloudflare Tunnel** يحتاج حساب Cloudflare مع دومين مضاف
2. **NSSM** يحتاج صلاحيات Administrator
3. **Port 53365** تأكد إنه مفتوح في الـ Firewall (محلياً فقط)
4. **Database Backup** سوي نسخ احتياطي منتظم لـ database.db

---

## 🚀 جاهز؟

ابدأ بالطريقة 1 (NSSM) - الأسهل والأسرع! 🎉
