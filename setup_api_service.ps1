# Setup API as Windows Service

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Setting up API as Windows Service" -ForegroundColor Yellow
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Requires Administrator privileges" -ForegroundColor Red
    Write-Host "Run PowerShell as Administrator and retry" -ForegroundColor Yellow
    exit 1
}

# المسارات
$apiPath = "C:\code\my_system\my_system_api"
$serviceName = "TaifManagementAPI"

# البحث عن NSSM
Write-Host "🔍 البحث عن NSSM..." -ForegroundColor Green
$nssmPath = $null

# مسارات محتملة
$possiblePaths = @(
    "C:\Program Files\NSSM\win64\nssm.exe",
    "C:\Program Files (x86)\NSSM\win64\nssm.exe",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\ShayimSoftware.NSSM_*\nssm*.exe"
)

foreach ($path in $possiblePaths) {
    $found = Get-ChildItem -Path (Split-Path $path -Parent) -Filter (Split-Path $path -Leaf) -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $nssmPath = $found.FullName
        break
    }
}

# إذا لم يُعثر عليه في المسارات، ابحث في PATH
if (-not $nssmPath) {
    $nssmPath = (Get-Command nssm -ErrorAction SilentlyContinue).Source
}

if (-not $nssmPath) {
    Write-Host "❌ لم يُعثر على NSSM" -ForegroundColor Red
    Write-Host "حمّله أولاً: winget install nssm" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ NSSM موجود في: $nssmPath" -ForegroundColor Green
Write-Host ""

# البحث عن Dart
Write-Host "🔍 البحث عن Dart..." -ForegroundColor Green
$dartPath = (Get-Command dart -ErrorAction SilentlyContinue).Source
if (-not $dartPath) {
    Write-Host "❌ لم يُعثر على Dart" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dart موجود في: $dartPath" -ForegroundColor Green
Write-Host ""

# التحقق من وجود الخدمة
Write-Host "🔍 التحقق من الخدمة..." -ForegroundColor Green
$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "⚠️  الخدمة موجودة مسبقاً. حذفها..." -ForegroundColor Yellow
    & $nssmPath stop $serviceName
    Start-Sleep -Seconds 2
    & $nssmPath remove $serviceName confirm
    Start-Sleep -Seconds 2
}

# إنشاء الخدمة
Write-Host "📦 إنشاء الخدمة..." -ForegroundColor Green
& $nssmPath install $serviceName $dartPath run bin/server.dart

# تكوين الخدمة
Write-Host "⚙️  تكوين الخدمة..." -ForegroundColor Green
& $nssmPath set $serviceName AppDirectory $apiPath
& $nssmPath set $serviceName DisplayName "إدارة الطيف - Backend API"
& $nssmPath set $serviceName Description "نظام إدارة الطلبات والتحاسبات - Backend Server"
& $nssmPath set $serviceName Start SERVICE_AUTO_START
& $nssmPath set $serviceName AppRestartDelay 5000
& $nssmPath set $serviceName AppStdout "$apiPath\logs\output.log"
& $nssmPath set $serviceName AppStderr "$apiPath\logs\error.log"

# إنشاء مجلد اللوجات
if (!(Test-Path "$apiPath\logs")) {
    New-Item -ItemType Directory -Path "$apiPath\logs" -Force | Out-Null
}

# بدء الخدمة
Write-Host "🚀 بدء الخدمة..." -ForegroundColor Green
& $nssmPath start $serviceName

Start-Sleep -Seconds 3

# التحقق
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq 'Running') {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "✅ نجح! API يعمل كخدمة Windows" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 معلومات الخدمة:" -ForegroundColor White
    Write-Host "   الاسم: $serviceName" -ForegroundColor Gray
    Write-Host "   الحالة: Running" -ForegroundColor Green
    Write-Host "   المنفذ: 53365" -ForegroundColor Gray
    Write-Host "   البدء: تلقائي مع Windows" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🌐 اختبار API:" -ForegroundColor White
    Write-Host "   http://localhost:53365" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📝 اللوجات في:" -ForegroundColor White
    Write-Host "   $apiPath\logs\" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔧 أوامر مفيدة:" -ForegroundColor White
    Write-Host "   إيقاف: nssm stop $serviceName" -ForegroundColor Gray
    Write-Host "   بدء: nssm start $serviceName" -ForegroundColor Gray
    Write-Host "   إعادة تشغيل: nssm restart $serviceName" -ForegroundColor Gray
    Write-Host "   حالة: nssm status $serviceName" -ForegroundColor Gray
    Write-Host "   حذف: nssm remove $serviceName" -ForegroundColor Gray
    Write-Host ""
    
    # اختبار الاتصال
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:53365" -Method GET -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ API يستجيب بنجاح!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  API لا يستجيب بعد. انتظر قليلاً..." -ForegroundColor Yellow
    }
    
} else {
    Write-Host ""
    Write-Host "❌ فشل بدء الخدمة" -ForegroundColor Red
    Write-Host "تحقق من اللوجات في: $apiPath\logs\" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
