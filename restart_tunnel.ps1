# ════════════════════════════════════════════════════════════
# إعادة تشغيل النفق - Restart Cloudflare Tunnel
# ════════════════════════════════════════════════════════════

Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "     إعادة تشغيل نفق Cloudflare" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 1️⃣ إيقاف النفق الحالي
Write-Host "1️⃣  إيقاف النفق الحالي..." -ForegroundColor Yellow
Stop-Service Cloudflared -Force -ErrorAction SilentlyContinue
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3
Write-Host "   ✅ تم إيقاف النفق" -ForegroundColor Green
Write-Host ""

# 2️⃣ تشغيل النفق
Write-Host "2️⃣  تشغيل النفق الجديد..." -ForegroundColor Yellow
Start-Service Cloudflared -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# 3️⃣ التحقق من الحالة
Write-Host ""
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "        النفق يعمل الآن! 🌐" -ForegroundColor Green
Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$status = Get-Service Cloudflared -ErrorAction SilentlyContinue
if ($status.Status -eq 'Running') {
    Write-Host "✅ حالة النفق: يعمل بنجاح" -ForegroundColor Green
} else {
    Write-Host "⚠️  حالة النفق: غير متصل" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 جرب تشغيله يدوياً:" -ForegroundColor White
    Write-Host "   Start-Service Cloudflared" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🌐 الرابط: https://admin.taif.digital" -ForegroundColor Cyan
Write-Host ""
