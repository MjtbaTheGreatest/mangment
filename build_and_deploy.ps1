# 🚀 سكريبت البناء والنشر التلقائي

param(
    [string]$version = "1.0.0",
    [string]$buildNumber = "1"
)

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "      إدارة الطيف - بناء ونشر v$version" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# الخطوة 1: التحقق من البيئة
Write-Host "🔍 الخطوة 1: التحقق من البيئة..." -ForegroundColor Green

if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ خطأ: Flutter غير مثبت!" -ForegroundColor Red
    exit 1
}

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ خطأ: Git غير مثبت!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ البيئة جاهزة" -ForegroundColor Green
Write-Host ""

# الخطوة 2: تنظيف البناء السابق
Write-Host "🧹 الخطوة 2: تنظيف البناء السابق..." -ForegroundColor Green
flutter clean
Write-Host "✅ تم التنظيف" -ForegroundColor Green
Write-Host ""

# الخطوة 3: تحميل الحزم
Write-Host "📦 الخطوة 3: تحميل الحزم..." -ForegroundColor Green
flutter pub get
Write-Host "✅ تم تحميل الحزم" -ForegroundColor Green
Write-Host ""

# الخطوة 4: بناء البرنامج
Write-Host "🔨 الخطوة 4: بناء البرنامج..." -ForegroundColor Green
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ فشل البناء!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ تم البناء بنجاح" -ForegroundColor Green
Write-Host ""

# الخطوة 5: نسخ الملفات للنشر
Write-Host "📁 الخطوة 5: تجهيز ملفات النشر..." -ForegroundColor Green

$releaseFolder = "build\windows\runner\Release"
$outputFolder = "dist\v$version"

if (Test-Path $outputFolder) {
    Remove-Item -Path $outputFolder -Recurse -Force
}

New-Item -ItemType Directory -Path $outputFolder -Force | Out-Null
Copy-Item -Path "$releaseFolder\*" -Destination $outputFolder -Recurse -Force

Write-Host "✅ تم نسخ الملفات إلى: $outputFolder" -ForegroundColor Green
Write-Host ""

# الخطوة 6: إنشاء ملف ZIP
Write-Host "🗜️  الخطوة 6: ضغط الملفات..." -ForegroundColor Green

$zipFile = "dist\TaifManagement-v$version.zip"

if (Test-Path $zipFile) {
    Remove-Item -Path $zipFile -Force
}

Compress-Archive -Path $outputFolder -DestinationPath $zipFile -Force

Write-Host "✅ تم إنشاء: $zipFile" -ForegroundColor Green
Write-Host ""

# الخطوة 7: تحديث version.json
Write-Host "📝 الخطوة 7: تحديث version.json..." -ForegroundColor Green

$versionJson = @{
    version = $version
    build_number = [int]$buildNumber
    download_url = "https://github.com/YOUR_USERNAME/YOUR_REPO/releases/download/v$version/TaifManagement-Setup.exe"
    changelog = "تحديث إلى الإصدار $version"
    mandatory = $false
    min_version = "1.0.0"
    release_date = (Get-Date -Format "yyyy-MM-dd")
}

$versionJson | ConvertTo-Json -Depth 10 | Set-Content -Path "version.json" -Encoding UTF8

Write-Host "✅ تم تحديث version.json" -ForegroundColor Green
Write-Host ""

# الخطوة 8: Git Commit
Write-Host "💾 الخطوة 8: حفظ التغييرات في Git..." -ForegroundColor Green

git add .
git commit -m "🚀 إصدار v$version"

Write-Host "✅ تم حفظ التغييرات" -ForegroundColor Green
Write-Host ""

# الخطوة 9: إنشاء Git Tag
Write-Host "🏷️  الخطوة 9: إنشاء Git Tag..." -ForegroundColor Green

git tag -a "v$version" -m "الإصدار $version"

Write-Host "✅ تم إنشاء Tag: v$version" -ForegroundColor Green
Write-Host ""

# ملخص
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✨ تم البناء بنجاح!" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 الملفات الجاهزة:" -ForegroundColor White
Write-Host "   • $outputFolder" -ForegroundColor Gray
Write-Host "   • $zipFile" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 الخطوات التالية:" -ForegroundColor White
Write-Host "   1. أنشئ مثبت باستخدام Inno Setup" -ForegroundColor Gray
Write-Host "   2. ارفع على GitHub:" -ForegroundColor Gray
Write-Host "      git push" -ForegroundColor DarkGray
Write-Host "      git push --tags" -ForegroundColor DarkGray
Write-Host "   3. أنشئ Release على GitHub" -ForegroundColor Gray
Write-Host "   4. ارفع ملف Setup.exe" -ForegroundColor Gray
Write-Host "   5. حدث رابط التحميل في version.json" -ForegroundColor Gray
Write-Host ""
Write-Host "🎉 مبروك! البرنامج جاهز للنشر" -ForegroundColor Yellow
Write-Host ""
