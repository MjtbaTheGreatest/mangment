# ════════════════════════════════════════════════════════════
# إعادة تشغيل السيرفر - Restart API Server
# ════════════════════════════════════════════════════════════

Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "       إعادة تشغيل سيرفر API" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 1️⃣ إيقاف جميع عمليات Dart
Write-Host "1️⃣  إيقاف السيرفر الحالي..." -ForegroundColor Yellow
Get-Process -Name "dart" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Write-Host "   ✅ تم إيقاف السيرفر" -ForegroundColor Green
Write-Host ""

# 2️⃣ الانتقال إلى مجلد API
Write-Host "2️⃣  الانتقال إلى مجلد API..." -ForegroundColor Yellow
Set-Location "C:\code\my_system\my_system_api"
Write-Host "   ✅ المسار: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# 3️⃣ تشغيل السيرفر
Write-Host "3️⃣  تشغيل السيرفر الجديد..." -ForegroundColor Yellow
Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "        السيرفر يعمل الآن! 🚀" -ForegroundColor Green
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 ملاحظة: اترك هذه النافذة مفتوحة" -ForegroundColor White
Write-Host "   السيرفر سيعمل في هذه النافذة" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 الرابط: https://admin.taif.digital" -ForegroundColor Cyan
Write-Host "⚡ المنفذ المحلي: 53365" -ForegroundColor Cyan
Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# تشغيل السيرفر (سيبقى يعمل هنا)
dart run bin/server.dart
