# 🎨 سكريبت إنشاء أيقونة Windows ICO

Write-Host "🎨 إنشاء أيقونة Windows..." -ForegroundColor Cyan

# المسارات
$pngPath = "assets\icon\AppIcon~ios-marketing.png"
$icoPath = "assets\icon\app_icon.ico"

# التحقق من وجود الملف
if (!(Test-Path $pngPath)) {
    Write-Host "❌ خطأ: الملف غير موجود: $pngPath" -ForegroundColor Red
    exit 1
}

# طريقة 1: استخدام PowerShell + .NET (بدون برامج إضافية)
Write-Host "📦 تحويل PNG إلى ICO..." -ForegroundColor Yellow

Add-Type -AssemblyName System.Drawing

try {
    # تحميل الصورة
    $img = [System.Drawing.Image]::FromFile((Resolve-Path $pngPath))
    
    # إنشاء أيقونة بأحجام متعددة
    $sizes = @(16, 32, 48, 64, 128, 256)
    $icon = New-Object System.Drawing.Icon -ArgumentList $img, $sizes[0], $sizes[0]
    
    # حفظ كملف ICO
    $fs = [System.IO.File]::Create($icoPath)
    $icon.Save($fs)
    $fs.Close()
    
    $img.Dispose()
    $icon.Dispose()
    
    Write-Host "✅ تم إنشاء: $icoPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 الخطوة التالية:" -ForegroundColor White
    Write-Host "   • إذا لم تعمل الأيقونة بشكل صحيح:" -ForegroundColor Gray
    Write-Host "   • استخدم موقع: https://convertio.co/png-ico/" -ForegroundColor Gray
    Write-Host "   • أو حمّل ImageMagick وشغّل:" -ForegroundColor Gray
    Write-Host "     magick convert $pngPath -define icon:auto-resize=256,128,64,48,32,16 $icoPath" -ForegroundColor DarkGray
    
} catch {
    Write-Host "⚠️ فشل التحويل التلقائي" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🌐 استخدم أحد هذه المواقع:" -ForegroundColor White
    Write-Host "   1. https://convertio.co/png-ico/" -ForegroundColor Cyan
    Write-Host "   2. https://icoconvert.com/" -ForegroundColor Cyan
    Write-Host "   3. https://www.aconvert.com/icon/png-to-ico/" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 الخطوات:" -ForegroundColor White
    Write-Host "   1. ارفع ملف: $pngPath" -ForegroundColor Gray
    Write-Host "   2. حمّل الملف الناتج" -ForegroundColor Gray
    Write-Host "   3. ضعه في: $icoPath" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🎯 ملاحظة: الأيقونة جاهزة للاستخدام!" -ForegroundColor Green
