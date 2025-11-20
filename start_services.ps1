# سكربت تشغيل السيرفر والتونل تلقائياً

Write-Host "🚀 بدء تشغيل الخدمات..." -ForegroundColor Green

# إيقاف العمليات القديمة
Write-Host "⏹️  إيقاف العمليات القديمة..." -ForegroundColor Yellow
Stop-Process -Name dart -Force -ErrorAction SilentlyContinue
Stop-Process -Name cloudflared -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# تشغيل API Server
Write-Host "🔧 تشغيل API Server..." -ForegroundColor Cyan
$apiPath = "c:\code\my_system\my_system_api"
Start-Process -FilePath "dart" -ArgumentList "run", "bin/server.dart" -WorkingDirectory $apiPath -WindowStyle Hidden
Start-Sleep -Seconds 3

# تشغيل Cloudflare Tunnel
Write-Host "🌐 تشغيل Cloudflare Tunnel..." -ForegroundColor Cyan
Start-Process -FilePath "cloudflared" -ArgumentList "tunnel", "run" -WindowStyle Hidden
Start-Sleep -Seconds 3

# التحقق من الحالة
Write-Host "`n✅ حالة الخدمات:" -ForegroundColor Green
$dartProcess = Get-Process -Name dart -ErrorAction SilentlyContinue
$tunnelProcess = Get-Process -Name cloudflared -ErrorAction SilentlyContinue

if ($dartProcess) {
    Write-Host "  ✅ API Server: شغال (PID: $($dartProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "  ❌ API Server: متوقف" -ForegroundColor Red
}

if ($tunnelProcess) {
    Write-Host "  ✅ Cloudflare Tunnel: شغال (PID: $($tunnelProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "  ❌ Cloudflare Tunnel: متوقف" -ForegroundColor Red
}

Write-Host "`n🌐 الروابط:" -ForegroundColor Yellow
Write-Host "  - Local: http://127.0.0.1:53366" -ForegroundColor Cyan
Write-Host "  - Public: https://admin.taif.digital" -ForegroundColor Cyan

Write-Host "`n✨ تم بنجاح!" -ForegroundColor Green
